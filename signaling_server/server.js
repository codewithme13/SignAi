/**
 * ============================================
 * SignAI - Signaling Server (v2)
 * ============================================
 * Bu sunucu sadece iki cihazı "buluşturur".
 * Video verisi buradan GEÇMEZ (P2P WebRTC).
 *
 * v2 İyileştirmeleri:
 * - PostgreSQL ile kalıcı veri saklama
 * - JWT tabanlı kimlik doğrulama
 * - Input validasyonu
 * - Rate limiting
 * - Arama geçmişi kaydı
 * - Helmet güvenlik header'ları
 * ============================================
 */

require('dotenv').config();

const express = require('express');
const { createServer } = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const { v4: uuidv4 } = require('uuid');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Yerel modüller
const {
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
} = require('./db');

const {
  generateToken,
  hashPassword,
  verifyPassword,
  authMiddleware,
  socketAuthMiddleware,
} = require('./auth');

const {
  validateSocketRegisterData,
  validateRegisterData,
  validateLoginData,
  validateCallData,
  validateAnswerData,
  validateIceCandidateData,
  isValidUUID,
} = require('./validation');

// ============ EXPRESS SETUP ============

const app = express();

// Güvenlik header'ları
app.use(helmet({ contentSecurityPolicy: false }));

// CORS
const corsOrigin = process.env.CORS_ORIGIN || '*';
app.use(cors({ origin: corsOrigin, methods: ['GET', 'POST'] }));

app.use(express.json({ limit: '1mb' }));

// Profil fotoğrafları klasörü
const uploadsDir = path.join(__dirname, 'uploads', 'profiles');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Multer yapılandırması
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadsDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, `${req.user.userId}${ext}`);
  },
});
const upload = multer({
  storage,
  limits: { fileSize: 2 * 1024 * 1024 }, // 2MB
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/webp'];
    cb(null, allowed.includes(file.mimetype));
  },
});

// Kullanıcının profil fotoğrafı URL'sini bul
function getUserPhotoUrl(userId) {
  const extensions = ['.jpg', '.jpeg', '.png', '.webp'];
  for (const ext of extensions) {
    const filePath = path.join(uploadsDir, `${userId}${ext}`);
    if (fs.existsSync(filePath)) {
      return `/uploads/profiles/${userId}${ext}`;
    }
  }
  return null;
}

// Rate Limiting (REST API)
const apiLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 60000,
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: { error: 'Çok fazla istek. Lütfen bekleyin.' },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', apiLimiter);

// ============ HTTP SERVER ============

const httpServer = createServer(app);

// ============ SOCKET.IO ============

const io = new Server(httpServer, {
  cors: { origin: corsOrigin, methods: ['GET', 'POST'] },
  pingTimeout: 30000,
  pingInterval: 10000,
});

// Socket.IO auth middleware
io.use(socketAuthMiddleware);

// ============ IN-MEMORY STATE ============
const onlineUsers = new Map();
const socketToUser = new Map();
const activeCalls = new Map();    // socketId -> partnerSocketId
const activeCallIds = new Map();  // socketId -> DB callId (for updateCallAnswered)

// ============ SOCKET RATE LIMITER ============
const socketRateLimits = new Map();
const SOCKET_RATE_LIMIT = 50;
const SOCKET_RATE_WINDOW = 60000;

function checkSocketRateLimit(socketId) {
  const now = Date.now();
  let limiter = socketRateLimits.get(socketId);
  if (!limiter || now > limiter.resetTime) {
    limiter = { count: 0, resetTime: now + SOCKET_RATE_WINDOW };
    socketRateLimits.set(socketId, limiter);
  }
  limiter.count++;
  return limiter.count <= SOCKET_RATE_LIMIT;
}

// ============ REST API ============

app.get('/', (req, res) => {
  res.json({
    status: 'SignAI Signaling Server v2',
    version: '2.0.0',
    onlineUsers: onlineUsers.size,
    activeCalls: activeCalls.size,
    timestamp: new Date().toISOString(),
  });
});

// Kullanıcı kaydı
app.post('/api/auth/register', async (req, res) => {
  try {
    const validationResult = validateRegisterData(req.body);
    if (!validationResult.isValid) {
      return res.status(400).json({ error: validationResult.error });
    }

    const { username, password } = req.body;
    
    // Kullanıcı zaten var mı kontrol et
    const existingUser = await getUserByUsername(username);
    if (existingUser) {
      return res.status(409).json({ error: 'Bu kullanıcı adı zaten kullanımda' });
    }

    // Şifreyi hash'le
    const passwordHash = await hashPassword(password);
    
    // Yeni kullanıcı oluştur
    const user = await createUser(username, passwordHash);
    const token = generateToken(user.id, user.username);

    res.status(201).json({ 
      userId: user.id, 
      username: user.username, 
      token 
    });
  } catch (err) {
    console.error('Kayıt hatası:', err.message);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// Kullanıcı giriş
app.post('/api/auth/login', async (req, res) => {
  try {
    const validationResult = validateLoginData(req.body);
    if (!validationResult.isValid) {
      return res.status(400).json({ error: validationResult.error });
    }

    const { username, password } = req.body;
    
    // Kullanıcıyı bul
    const user = await getUserByUsername(username);
    if (!user) {
      return res.status(401).json({ error: 'Kullanıcı adı veya şifre hatalı' });
    }

    // Şifreyi doğrula
    const isPasswordValid = await verifyPassword(password, user.password_hash);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Kullanıcı adı veya şifre hatalı' });
    }

    // Kullanıcıyı online yap
    await upsertUser(user.id, user.username);
    const token = generateToken(user.id, user.username);

    res.status(200).json({ 
      userId: user.id, 
      username: user.username, 
      token 
    });
  } catch (err) {
    console.error('Giriş hatası:', err.message);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// Online kullanıcılar
app.get('/api/users', authMiddleware, async (req, res) => {
  try {
    const users = await getOnlineUsers();
    res.json({ users });
  } catch (err) {
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// Arama geçmişi
app.get('/api/calls/history', authMiddleware, async (req, res) => {
  try {
    const history = await getCallHistory(req.user.userId);
    res.json({ history });
  } catch (err) {
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// Profil fotoğrafı yükle
app.post('/api/profile/photo', authMiddleware, upload.single('photo'), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Fotoğraf yüklenemedi' });
    }
    const photoUrl = `/uploads/profiles/${req.file.filename}`;
    console.log(`📸 Profil fotoğrafı yüklendi: ${req.user.userId}`);
    res.json({ photoUrl });
  } catch (err) {
    console.error('Fotoğraf yükleme hatası:', err.message);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// Profil fotoğrafı sil
app.delete('/api/profile/photo', authMiddleware, (req, res) => {
  try {
    const extensions = ['.jpg', '.jpeg', '.png', '.webp'];
    for (const ext of extensions) {
      const filePath = path.join(uploadsDir, `${req.user.userId}${ext}`);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
    }
    res.json({ message: 'Fotoğraf silindi' });
  } catch (err) {
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// Profil fotoğrafı kontrol
app.get('/api/profile/photo/:userId', (req, res) => {
  const { userId } = req.params;
  const extensions = ['.jpg', '.jpeg', '.png', '.webp'];
  for (const ext of extensions) {
    const filePath = path.join(uploadsDir, `${userId}${ext}`);
    if (fs.existsSync(filePath)) {
      return res.json({ photoUrl: `/uploads/profiles/${userId}${ext}` });
    }
  }
  res.json({ photoUrl: null });
});

// Kullanıcı bilgisi
app.get('/api/users/:userId', authMiddleware, async (req, res) => {
  try {
    if (!isValidUUID(req.params.userId)) {
      return res.status(400).json({ error: 'Geçersiz userId' });
    }
    const user = await getUserById(req.params.userId);
    if (!user) return res.status(404).json({ error: 'Kullanıcı bulunamadı' });
    res.json({ user });
  } catch (err) {
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// ============ SOCKET.IO EVENTS ============

io.on('connection', (socket) => {
  console.log(`🔌 Bağlantı: ${socket.id} (${socket.username})`);

  // ---- 1. KULLANICI GİRİŞİ ----
  socket.on('register', async (data) => {
    if (!checkSocketRateLimit(socket.id)) {
      socket.emit('error', { message: 'Rate limit aşıldı' });
      return;
    }

    const validation = validateSocketRegisterData(data);
    if (!validation.isValid) {
      socket.emit('error', { message: validation.error });
      return;
    }

    const { userId, username } = validation.sanitized;
    console.log(`👤 Kayıt: ${username} (${userId})`);

    try {
      await upsertUser(userId, username);
      onlineUsers.set(userId, socket.id);
      socketToUser.set(socket.id, { userId, username });

      const photoUrl = getUserPhotoUrl(userId);
      socket.broadcast.emit('user-online', { userId, username, photoUrl });

      const currentUsers = [];
      socketToUser.forEach((user, sid) => {
        if (sid !== socket.id) {
          const userPhoto = getUserPhotoUrl(user.userId);
          currentUsers.push({ ...user, photoUrl: userPhoto });
        }
      });
      socket.emit('online-users', { users: currentUsers });

      console.log(`📊 Online: ${onlineUsers.size}`);
    } catch (err) {
      console.error('Kayıt DB hatası:', err.message);
      socket.emit('error', { message: 'Kayıt hatası' });
    }
  });

  // ---- 2. ARAMA BAŞLAT ----
  socket.on('call-user', async (data) => {
    if (!checkSocketRateLimit(socket.id)) return;

    const validation = validateCallData(data);
    if (!validation.isValid) {
      console.warn(`⚠️ Geçersiz call-user payload (${socket.id}): ${validation.error}`);
      socket.emit('error', { message: validation.error });
      return;
    }

    const { targetUserId, offer, callerInfo } = data;
    const targetSocketId = onlineUsers.get(targetUserId);
    const caller = socketToUser.get(socket.id);

    console.log(`📞 Arama: ${caller?.username} -> ${targetUserId}`);

    if (targetSocketId) {
      const callId = uuidv4();
      let dbCallId = null;
      try {
        if (caller) {
          const record = await createCallRecord(caller.userId, targetUserId);
          dbCallId = record?.id;
        }
      } catch (err) {
        console.error('Arama kaydı hatası:', err.message);
      }

      // DB call id'yi sakla (answer-call'da kullanmak için)
      if (dbCallId) {
        activeCallIds.set(socket.id, dbCallId);
        activeCallIds.set(targetSocketId, dbCallId);
      }

      // Arayanın profil fotoğrafını bul
      let callerPhotoUrl = null;
      if (caller) {
        const extensions = ['.jpg', '.jpeg', '.png', '.webp'];
        for (const ext of extensions) {
          const filePath = path.join(uploadsDir, `${caller.userId}${ext}`);
          if (fs.existsSync(filePath)) {
            callerPhotoUrl = `/uploads/profiles/${caller.userId}${ext}`;
            break;
          }
        }
      }

      io.to(targetSocketId).emit('incoming-call', {
        callerId: callerInfo.userId,
        callerName: callerInfo.username,
        callerPhoto: callerPhotoUrl,
        offer, callId,
      });
    } else {
      socket.emit('call-error', { message: 'Kullanıcı çevrimdışı', targetUserId });
    }
  });

  // ---- 3. ARAMAYI KABUL ET ----
  socket.on('answer-call', async (data) => {
    if (!checkSocketRateLimit(socket.id)) return;

    const validation = validateAnswerData(data);
    if (!validation.isValid) {
      console.warn(`⚠️ Geçersiz answer-call payload (${socket.id}): ${validation.error}`);
      socket.emit('error', { message: validation.error });
      return;
    }

    const { targetUserId, answer } = data;
    const targetSocketId = onlineUsers.get(targetUserId);

    if (targetSocketId) {
      io.to(targetSocketId).emit('call-answered', {
        answer, answeredBy: socketToUser.get(socket.id),
      });
      activeCalls.set(socket.id, targetSocketId);
      activeCalls.set(targetSocketId, socket.id);

      // DB'de arama durumunu "connected" yap
      const dbCallId = activeCallIds.get(socket.id) || activeCallIds.get(targetSocketId);
      if (dbCallId) {
        try {
          await updateCallAnswered(dbCallId);
        } catch (err) {
          console.error('Call answered DB hatası:', err.message);
        }
      }
    }
  });

  // ---- 4. ARAMAYI REDDET ----
  socket.on('reject-call', (data) => {
    if (!checkSocketRateLimit(socket.id)) return;
    const { targetUserId } = data || {};
    if (!isValidUUID(targetUserId)) return;

    const targetSocketId = onlineUsers.get(targetUserId);
    if (targetSocketId) {
      io.to(targetSocketId).emit('call-rejected', {
        rejectedBy: socketToUser.get(socket.id),
      });
    }
  });

  // ---- 5. ICE CANDIDATE ----
  socket.on('ice-candidate', (data) => {
    if (!checkSocketRateLimit(socket.id)) return;
    const validation = validateIceCandidateData(data);
    if (!validation.isValid) {
      console.warn(`⚠️ Geçersiz ice-candidate payload (${socket.id}): ${validation.error}`);
      return;
    }

    const { targetUserId, candidate } = data;
    const targetSocketId = onlineUsers.get(targetUserId);
    if (targetSocketId) {
      io.to(targetSocketId).emit('ice-candidate', {
        candidate, from: socketToUser.get(socket.id)?.userId,
      });
    }
  });

  // ---- 6. ARAMAYI SONLANDIR ----
  socket.on('end-call', async (data) => {
    if (!checkSocketRateLimit(socket.id)) return;
    const { targetUserId } = data || {};
    if (!isValidUUID(targetUserId)) return;

    const targetSocketId = onlineUsers.get(targetUserId);
    if (targetSocketId) {
      io.to(targetSocketId).emit('call-ended', {
        endedBy: socketToUser.get(socket.id),
      });
    }

    try {
      const caller = socketToUser.get(socket.id);
      const callId = activeCallIds.get(socket.id);
      if (callId) {
        await endCallRecordById(callId, 'normal');
      } else if (caller) {
        await endCallRecord(caller.userId, targetUserId, 'normal');
      }
    } catch (err) {
      console.error('Arama sonlandırma kaydı hatası:', err.message);
    }

    activeCalls.delete(socket.id);
    if (targetSocketId) activeCalls.delete(targetSocketId);
    activeCallIds.delete(socket.id);
    if (targetSocketId) activeCallIds.delete(targetSocketId);
  });

  // ---- 7. ALT YAZI ----
  socket.on('subtitle', (data) => {
    if (!checkSocketRateLimit(socket.id)) return;
    const { targetUserId, text, language } = data || {};
    if (!isValidUUID(targetUserId)) return;
    if (typeof text !== 'string' || text.length > 500) return;

    const targetSocketId = onlineUsers.get(targetUserId);
    if (targetSocketId) {
      io.to(targetSocketId).emit('subtitle', {
        text: text.substring(0, 500),
        language: language || 'tr',
        from: socketToUser.get(socket.id)?.userId,
        timestamp: Date.now(),
      });
    }
  });

  // ---- 8. BAĞLANTI KESİLDİ ----
  socket.on('disconnect', async () => {
    const user = socketToUser.get(socket.id);
    if (!user) return;

    console.log(`🔴 Çıkış: ${user.username} (${user.userId})`);

    const partnerSocketId = activeCalls.get(socket.id);
    if (partnerSocketId) {
      io.to(partnerSocketId).emit('call-ended', {
        endedBy: user, reason: 'disconnect',
      });
      activeCalls.delete(partnerSocketId);

      try {
        const callId = activeCallIds.get(socket.id) || activeCallIds.get(partnerSocketId);
        if (callId) {
          await endCallRecordById(callId, 'disconnect');
        } else {
          const partner = socketToUser.get(partnerSocketId);
          if (partner) await endCallRecord(user.userId, partner.userId, 'disconnect');
        }
      } catch (err) {
        console.error('Disconnect arama kaydı hatası:', err.message);
      }
    }

    socket.broadcast.emit('user-offline', {
      userId: user.userId, username: user.username,
    });

    try { await setUserOffline(user.userId); } catch (_) {}

    onlineUsers.delete(user.userId);
    socketToUser.delete(socket.id);
    activeCalls.delete(socket.id);
    activeCallIds.delete(socket.id);
    socketRateLimits.delete(socket.id);

    console.log(`📊 Online: ${onlineUsers.size}`);
  });
});

// ============ SUNUCUYU BAŞLAT ============

async function startServer() {
  try {
    await initializeDatabase();

    const PORT = process.env.PORT || 3001;
    const HOST = '0.0.0.0'; // Tüm IP'lerden erişim için
    httpServer.listen(PORT, HOST, () => {
      console.log(`
  ╔══════════════════════════════════════════╗
  ║    🤟 SignAI Signaling Server v2        ║
  ║    Host: ${HOST}:${PORT}                    ║
  ║    DB: PostgreSQL (signai_db)            ║
  ║    Auth: JWT                             ║
  ║    Rate Limit: Aktif                     ║
  ║    Validation: Aktif                     ║
  ║    Status: Çalışıyor                     ║
  ╚══════════════════════════════════════════╝
      `);
    });
  } catch (err) {
    console.error('Sunucu başlatma hatası:', err.message);
    process.exit(1);
  }
}

startServer();
