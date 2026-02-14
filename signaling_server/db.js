/**
 * ============================================
 * SignAI - PostgreSQL Veritabanı Bağlantısı
 * ============================================
 * Kullanıcı kaydı, arama geçmişi ve oturum
 * yönetimi için PostgreSQL kullanılır.
 * ============================================
 */

const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

// Bağlantı test
pool.on('connect', () => {
  console.log('🐘 PostgreSQL bağlantısı kuruldu');
});

pool.on('error', (err) => {
  console.error('❌ PostgreSQL bağlantı hatası:', err.message);
});

/**
 * Veritabanı tablolarını oluştur
 */
async function initializeDatabase() {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Kullanıcılar tablosu
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY,
        username VARCHAR(50) NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        is_online BOOLEAN DEFAULT false
      );
    `);

    // Arama geçmişi tablosu
    await client.query(`
      CREATE TABLE IF NOT EXISTS call_history (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        caller_id UUID REFERENCES users(id),
        callee_id UUID REFERENCES users(id),
        started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        ended_at TIMESTAMP WITH TIME ZONE,
        duration_seconds INTEGER,
        status VARCHAR(20) DEFAULT 'initiated',
        end_reason VARCHAR(50)
      );
    `);

    // İndeksler
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
      CREATE INDEX IF NOT EXISTS idx_users_online ON users(is_online);
      CREATE INDEX IF NOT EXISTS idx_call_history_caller ON call_history(caller_id);
      CREATE INDEX IF NOT EXISTS idx_call_history_callee ON call_history(callee_id);
      CREATE INDEX IF NOT EXISTS idx_call_history_started ON call_history(started_at DESC);
    `);

    await client.query('COMMIT');

    // Sunucu yeniden başladığında tüm kullanıcıları çevrimdışı yap
    // (kalan is_online=true kayıtları stale/ghost olabilir)
    await pool.query('UPDATE users SET is_online = false');

    console.log('✅ Veritabanı tabloları hazır');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Tablo oluşturma hatası:', err.message);
    throw err;
  } finally {
    client.release();
  }
}

/**
 * Kullanıcı oluştur (şifreli)
 */
async function createUser(username, passwordHash) {
  const userId = require('uuid').v4();
  const result = await pool.query(
    `INSERT INTO users (id, username, password_hash, created_at, last_seen, is_online)
     VALUES ($1, $2, $3, NOW(), NOW(), false)
     RETURNING *`,
    [userId, username, passwordHash]
  );
  return result.rows[0];
}

/**
 * Kullanıcıyı username'e göre bul
 */
async function getUserByUsername(username) {
  const result = await pool.query(
    'SELECT * FROM users WHERE username = $1',
    [username]
  );
  return result.rows[0] || null;
}

/**
 * Kullanıcı oluştur veya güncelle (upsert)
 */
async function upsertUser(userId, username) {
  const result = await pool.query(
    `INSERT INTO users (id, username, last_seen, is_online)
     VALUES ($1, $2, NOW(), true)
     ON CONFLICT (id) DO UPDATE
     SET username = $2, last_seen = NOW(), is_online = true
     RETURNING *`,
    [userId, username]
  );
  return result.rows[0];
}

/**
 * Kullanıcıyı offline yap
 */
async function setUserOffline(userId) {
  await pool.query(
    `UPDATE users SET is_online = false, last_seen = NOW() WHERE id = $1`,
    [userId]
  );
}

/**
 * Online kullanıcıları getir
 */
async function getOnlineUsers() {
  const result = await pool.query(
    `SELECT id as "userId", username FROM users WHERE is_online = true ORDER BY last_seen DESC`
  );
  return result.rows;
}

/**
 * Kullanıcıyı ID ile bul
 */
async function getUserById(userId) {
  const result = await pool.query(
    `SELECT id as "userId", username, is_online, last_seen FROM users WHERE id = $1`,
    [userId]
  );
  return result.rows[0] || null;
}

// ============ ARAMA GEÇMİŞİ ============

/**
 * Yeni arama kaydı oluştur
 */
async function createCallRecord(callerId, calleeId) {
  const result = await pool.query(
    `INSERT INTO call_history (caller_id, callee_id, status)
     VALUES ($1, $2, 'initiated')
     RETURNING *`,
    [callerId, calleeId]
  );
  return result.rows[0];
}

/**
 * Arama kaydını güncelle (kabul edildi)
 */
async function updateCallAnswered(callId) {
  await pool.query(
    `UPDATE call_history SET status = 'connected', started_at = NOW() WHERE id = $1`,
    [callId]
  );
}

/**
 * Arama kaydını sonlandır (caller/callee pair ile)
 */
async function endCallRecord(callerId, calleeId, reason = 'normal') {
  const result = await pool.query(
    `UPDATE call_history
     SET ended_at = NOW(),
         duration_seconds = EXTRACT(EPOCH FROM (NOW() - started_at))::INTEGER,
         status = 'ended',
         end_reason = $3
     WHERE ((caller_id = $1 AND callee_id = $2) OR (caller_id = $2 AND callee_id = $1))
       AND status IN ('initiated', 'connected')
     RETURNING *`,
    [callerId, calleeId, reason]
  );
  return result.rows[0];
}

/**
 * Arama kaydını callId ile sonlandır (daha güvenilir)
 */
async function endCallRecordById(callId, reason = 'normal') {
  const result = await pool.query(
    `UPDATE call_history
     SET ended_at = NOW(),
         duration_seconds = EXTRACT(EPOCH FROM (NOW() - started_at))::INTEGER,
         status = 'ended',
         end_reason = $3
     WHERE id = $1
       AND status IN ('initiated', 'connected')
     RETURNING *`,
    [callId, reason]
  );
  return result.rows[0];
}

/**
 * Kullanıcının arama geçmişini getir
 */
async function getCallHistory(userId, limit = 20) {
  const result = await pool.query(
    `SELECT ch.*,
            u1.username as caller_name,
            u2.username as callee_name
     FROM call_history ch
     LEFT JOIN users u1 ON ch.caller_id = u1.id
     LEFT JOIN users u2 ON ch.callee_id = u2.id
     WHERE ch.caller_id = $1 OR ch.callee_id = $1
     ORDER BY ch.started_at DESC
     LIMIT $2`,
    [userId, limit]
  );
  return result.rows;
}

module.exports = {
  pool,
  initializeDatabase,
  createUser,
  getUserByUsername,
  upsertUser,
  setUserOffline,
  getOnlineUsers,
  getUserById,
  createCallRecord,
  updateCallAnswered,
  endCallRecord,
  endCallRecordById,
  getCallHistory,
};
