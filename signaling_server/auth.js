/**
 * ============================================
 * SignAI - Kimlik Doğrulama Middleware
 * ============================================
 * JWT + bcrypt tabanlı güvenli auth sistemi.
 * Kullanıcılar username+password ile kayıt olur,
 * Şifreler bcrypt ile hash'lenir.
 * ============================================
 */

const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRY = process.env.JWT_EXPIRY || '7d';
const SALT_ROUNDS = 12; // bcrypt salt rounds

if (!JWT_SECRET) {
  console.error('❌ JWT_SECRET ortam değişkeni ayarlanmamış! .env dosyasını kontrol edin.');
  process.exit(1);
}

/**
 * Şifreyi hash'le
 */
async function hashPassword(password) {
  return await bcrypt.hash(password, SALT_ROUNDS);
}

/**
 * Şifreyi doğrula
 */
async function verifyPassword(password, hash) {
  return await bcrypt.compare(password, hash);
}

/**
 * JWT token oluştur
 */
function generateToken(userId, username) {
  return jwt.sign(
    { userId, username },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRY }
  );
}

/**
 * JWT token doğrula
 */
function verifyToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (err) {
    return null;
  }
}

/**
 * REST API auth middleware
 */
function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token gerekli' });
  }

  const token = authHeader.split(' ')[1];
  const decoded = verifyToken(token);

  if (!decoded) {
    return res.status(401).json({ error: 'Geçersiz veya süresi dolmuş token' });
  }

  req.user = decoded;
  next();
}

/**
 * Socket.IO auth middleware
 * Bağlantı kurulurken token doğrulanır.
 */
function socketAuthMiddleware(socket, next) {
  const token = socket.handshake.auth?.token;

  if (!token) {
    return next(new Error('Token gerekli'));
  }

  const decoded = verifyToken(token);
  if (!decoded) {
    return next(new Error('Geçersiz veya süresi dolmuş token'));
  }

  socket.userId = decoded.userId;
  socket.username = decoded.username;
  next();
}

module.exports = {
  generateToken,
  verifyToken,
  hashPassword,
  verifyPassword,
  authMiddleware,
  socketAuthMiddleware,
};
