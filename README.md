# 📘 SignAI — Proje Konu Anlatımı

> **Son Güncelleme:** 14 Şubat 2026
> **Durum:** Geliştirme aşamasında (~%85 tamamlandı)

---

## 📌 Projenin Amacı

**SignAI**, işitme engelli bireylerle işaret dili bilmeyen insanlar arasındaki iletişim engelini kaldırmak için geliştirilmiş bir **gerçek zamanlı görüntülü arama uygulamasıdır.**

Uygulama video arama sırasında iki temel yapay zeka özelliği sunar:

1. **İşaret Dili → Yazı:** Kameradan gelen görüntüde kullanıcının vücut hareketlerini analiz eder ve 10 temel Türk İşaret Dili hareketini algılayarak ekranda altyazı olarak gösterir.
2. **Konuşma → Yazı:** Mikrofondan gelen sesi gerçek zamanlı yazıya çevirir ve karşı tarafa altyazı olarak iletir.

Böylece bir taraf işaret diliyle, diğer taraf konuşarak iletişim kurabilir ve ikisi de karşı tarafı **altyazılardan** anlayabilir.

---

## 🏗️ Genel Mimari

```
┌─────────────────────────────────────────────────────────────────────┐
│                        📱 FLUTTER MOBİL APP                        │
│                                                                     │
│  ┌──────────────┐  ┌──────────────────────────────────────────┐    │
│  │ AuthProvider  │  │           CallProvider                   │    │
│  │ (JWT Oturum)  │  │  (Ana Orkestratör — herşeyi bağlar)     │    │
│  └──────┬───────┘  └───────┬──────────┬──────────┬────────────┘    │
│         │                  │          │          │                  │
│         │          ┌───────▼───┐ ┌────▼────┐ ┌──▼──────────┐      │
│         │          │ WebRTC    │ │İşaret   │ │Konuşma→Yazı │      │
│         │          │ Service   │ │Dili AI  │ │(STT)        │      │
│         │          │(P2P Video)│ │(ML Kit) │ │Service      │      │
│         │          └───────┬───┘ └─────────┘ └─────────────┘      │
│         │                  │                                       │
│         │          ┌───────▼──────────┐  ┌──────────────────┐     │
│         │          │ Signaling Service │  │ Permission       │     │
│         │          │ (Socket.IO)       │  │ Service          │     │
│         │          └───────┬──────────┘  └──────────────────┘     │
│         │                  │                                       │
│  ┌──────┴──────────────────┴───────────────────────────────────┐   │
│  │ EKRANLAR: Splash → Login → Home → Call                      │   │
│  │ WİDGET'LAR: CallControls, CallTimer, IncomingCallDialog,    │   │
│  │             SubtitleOverlay                                  │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────┬───────────────────────────────────┘
                                  │ Socket.IO (WebSocket) + HTTP REST
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                 🖥️ SİNYALİZASYON SUNUCUSU (Node.js)               │
│                                                                     │
│  Express + Socket.IO + Helmet + Rate Limit                         │
│  ┌──────────┐  ┌────────────┐  ┌────────────────────────┐         │
│  │ auth.js  │  │validation  │  │     server.js          │         │
│  │ (JWT)    │  │   .js      │  │ (tüm mantık burada)    │         │
│  └──────────┘  └────────────┘  └──────────┬─────────────┘         │
│                                            │                       │
│  ┌─────────────────────────────────────────▼───────────────────┐   │
│  │ db.js → PostgreSQL Veritabanı                               │   │
│  │ Tablolar: users, call_history                               │   │
│  │ Port: 5432 | Veritabanı: signai_db                          │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📁 Dosya Yapısı ve Her Dosyanın Görevi

### 📱 Flutter Uygulaması (`signai_app/`)

| Dosya | Satır | Ne Yapar |
|-------|-------|----------|
| `lib/main.dart` | 58 | Uygulamanın giriş noktası. Ekranı dikeye kilitler, Provider'ları sarar, karanlık temayı uygular, SplashScreen'den başlar |
| `lib/providers/auth_provider.dart` | 119 | JWT tabanlı kullanıcı oturum yönetimi. Sunucuya kayıt olur, token'ı saklar, token süresini kontrol eder |
| `lib/providers/call_provider.dart` | 430 | **Ana beyindir.** WebRTC + İşaret Dili AI + Konuşma servisi + Signaling servisini bir arada yönetir. Arama yaşam döngüsünü kontrol eder |
| `lib/screens/splash_screen.dart` | 155 | Açılış animasyonu (logo fade+scale). 3 saniye sonra oturum durumuna göre Login veya Home'a yönlendirir |
| `lib/screens/login_screen.dart` | 218 | Kullanıcı adı giriş ekranı. Min 2 karakter. Başarılıysa Home'a gider |
| `lib/screens/home_screen.dart` | 644 | Ana ekran. Kullanıcı bilgi kartı, çevrimiçi kullanıcı listesi, arama başlatma, gelen arama dialog'u, uygulama yaşam döngüsü yönetimi |
| `lib/screens/call_screen.dart` | 489 | Görüntülü arama ekranı. Yerel/uzak video, altyazı overlay, kontrol butonları, zamanlayıcı, bağlantı durumu |
| `lib/services/webrtc_service.dart` | 372 | WebRTC peer bağlantısı. Kamera/mikrofon erişimi, SDP offer/answer, ICE candidate değişimi, medya kontrolü |
| `lib/services/signaling_service.dart` | 265 | Socket.IO istemcisi. SDP/ICE relay, kullanıcı varlık durumu, altyazı iletimi. Reconnect'te otomatik yeniden kayıt |
| `lib/services/sign_language_service.dart` | 505 | **AI çekirdeği.** ML Kit Pose Detection ile 10 Türk İşaret Dili hareketini algılar. Hareket geçmişi, buffer tutarlılık kontrolü |
| `lib/services/speech_to_text_service.dart` | 260 | Yerel mikrofonu dinler, sesi yazıya çevirir (Türkçe). 30sn dinleme penceresi + otomatik yeniden başlatma |
| `lib/services/permission_service.dart` | 96 | Kamera, mikrofon, konuşma tanıma izinlerini yönetir |
| `lib/utils/constants.dart` | 59 | Sunucu URL'si, ICE sunucu ayarları, medya kısıtlamaları, UI sabitleri |
| `lib/utils/theme.dart` | 108 | Karanlık tema tanımı. Mor/cyan renk paleti, gradyanlar, Material ThemeData |
| `lib/widgets/call_controls.dart` | 174 | Arama kontrol çubuğu: mikrofon, kamera, kamera değiştir, kapat |
| `lib/widgets/call_timer.dart` | 72 | Canlı arama süresi sayacı (SS:DD veya SS:DD:SS) |
| `lib/widgets/incoming_call_dialog.dart` | 230 | Gelen arama dialog'u. Titreşim + nabız animasyonu + kabul/red butonları |
| `lib/widgets/subtitle_overlay.dart` | 118 | İki şeritli altyazı: işaret dili (mor) ve konuşma (cyan) |

**Toplam Dart kodu: ~3,952 satır**

### 🖥️ Signaling Sunucusu (`signaling_server/`)

| Dosya | Satır | Ne Yapar |
|-------|-------|----------|
| `server.js` | 448 | Express + Socket.IO ana sunucu. REST API + WebSocket olayları. Kullanıcı varlık yönetimi, arama geçmişi |
| `db.js` | 233 | PostgreSQL veritabanı katmanı. Tablo oluşturma, CRUD işlemleri |
| `auth.js` | 87 | JWT token üretimi ve doğrulaması (REST + Socket.IO için) |
| `validation.js` | 167 | Tüm gelen verilerin doğrulanması (UUID, SDP, ICE, kullanıcı adı) |
| `package.json` | 27 | Node.js bağımlılıkları ve scriptler |

**Toplam JS kodu: ~962 satır**

---

## 🗄️ Veritabanı (PostgreSQL)

**Bağlantı:** `localhost:5432` | **Veritabanı adı:** `signai_db`

### Tablo 1: `users` — Kullanıcılar

```sql
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY,                              -- Benzersiz kullanıcı ID
    username VARCHAR(50) NOT NULL,                     -- Kullanıcı adı
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- Hesap oluşturma tarihi
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),  -- Son görülme zamanı
    is_online BOOLEAN DEFAULT false                    -- Şu an çevrimiçi mi?
);
```

### Tablo 2: `call_history` — Arama Geçmişi

```sql
CREATE TABLE IF NOT EXISTS call_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),     -- Arama kaydı ID
    caller_id UUID REFERENCES users(id),               -- Arayan kullanıcı
    callee_id UUID REFERENCES users(id),               -- Aranan kullanıcı
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- Başlangıç zamanı
    ended_at TIMESTAMP WITH TIME ZONE,                 -- Bitiş zamanı
    duration_seconds INTEGER,                          -- Süre (saniye)
    status VARCHAR(20) DEFAULT 'initiated',            -- Durum: initiated → connected → ended
    end_reason VARCHAR(50)                             -- Bitiş nedeni: normal, disconnect, rejected
);
```

### İndeksler (5 adet)

```sql
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_online ON users(is_online);
CREATE INDEX idx_call_history_caller ON call_history(caller_id);
CREATE INDEX idx_call_history_callee ON call_history(callee_id);
CREATE INDEX idx_call_history_started ON call_history(started_at DESC);
```

### Arama Durumu Akışı

```
'initiated' ─── arama başlatıldı
     │
     ├── cevaplandı → 'connected' ─── taraflar konuşuyor
     │                      │
     │                      └── kapattılar → 'ended' (reason: 'normal')
     │
     ├── reddedildi → 'ended' (reason: 'rejected')
     │
     └── bağlantı koptu → 'ended' (reason: 'disconnect')
```

**Sunucu başlangıcında:** Tüm kullanıcılar `is_online = false` yapılır (ghost kayıtları temizlenir).

---

## 🔐 Kimlik Doğrulama (Auth) Akışı

```
Kullanıcı                    Flutter App                     Sunucu + DB
   │                             │                               │
   │── kullanıcı adı girer ────>│                               │
   │                             │── POST /api/auth/register ──>│
   │                             │   {username: "umut"}          │
   │                             │                               │── UUID üretir
   │                             │                               │── DB'ye yazar (upsert)
   │                             │                               │── JWT token imzalar
   │                             │<── {userId, username, token} ─│
   │                             │                               │
   │                             │── SharedPreferences'a kaydeder│
   │                             │── Socket.IO bağlanır (JWT)──>│── JWT doğru mu? ✅
   │                             │── register event gönderir ──>│── onlineUsers'a ekler
   │                             │                               │── herkese user-online yayınlar
   │<── Home ekranına gider ────│                               │
```

**JWT Token:**
- İçerik: `{userId, username, iat, exp}`
- Süre: 7 gün (`JWT_EXPIRY` env ile değiştirilebilir)
- Secret: `JWT_SECRET` env variable (zorunlu, yoksa sunucu başlamaz)
- Saklanma: SharedPreferences (yerel cihaz)
- Her uygulama açılışında `exp` kontrol edilir → süresi geçmişse otomatik logout

---

## 📞 WebRTC Arama Akışı (Detaylı)

```
CİHAZ A (Arayan)               SİNYALİZASYON SUNUCUSU            CİHAZ B (Aranan)
     │                                   │                              │
     │ 1. Kullanıcıya tıklar             │                              │
     │ 2. getUserMedia(640×480, 24fps)    │                              │
     │ 3. PeerConnection oluştur          │                              │
     │    (3 STUN + 2 TURN sunucu)        │                              │
     │ 4. createOffer() → SDP             │                              │
     │ 5. setLocalDescription(offer)      │                              │
     │                                    │                              │
     │── emit('call-user', {offer}) ────>│                              │
     │                                    │── DB: createCallRecord() ──>│
     │                                    │── emit('incoming-call') ───>│
     │                                    │                    6. 📳 Titreşim başlar
     │                                    │                    7. Dialog gösterilir
     │                                    │                    8. Kullanıcı "Kabul Et" der
     │                                    │                    9. getUserMedia()
     │                                    │                    10. PeerConnection oluştur
     │                                    │                    11. setRemoteDescription(offer)
     │                                    │                    12. createAnswer() → SDP
     │                                    │                    13. setLocalDescription(answer)
     │                                    │                              │
     │                                    │<── emit('answer-call') ─────│
     │                                    │── DB: updateCallAnswered()  │
     │<── emit('call-answered', answer) ──│                              │
     │ 14. setRemoteDescription(answer)   │                              │
     │                                    │                              │
     │<═══════ ICE Candidate Değişimi (STUN/TURN aracılığıyla) ════════>│
     │                                    │                              │
     │<═══════════ P2P DTLS/SRTP ŞİFRELİ BAĞLANTI KURULDU ═══════════>│
     │                                    │                              │
     │ 15. AI Pipeline başlar             │              15. AI Pipeline başlar
     │     (200ms timer, frame yakala)    │                  (STT dinlemeye başlar)
     │                                    │                              │
     │ 16. İşaret algılandı → "Merhaba"  │                              │
     │── emit('subtitle', "Merhaba") ───>│── emit('subtitle') ────────>│
     │                                    │              17. Ekranda "Merhaba" görünür
     │                                    │                              │
     │                                    │         18. Kullanıcı konuşur → "Nasılsın"
     │                                    │<── emit('subtitle', "Nasılsın") ──│
     │<── emit('subtitle') ──────────────│                              │
     │ 19. Ekranda "Nasılsın" görünür    │                              │
     │                                    │                              │
     │── emit('end-call') ──────────────>│── emit('call-ended') ──────>│
     │                                    │── DB: endCallRecordById()   │
     │ 20. CallScreen otomatik kapanır   │              20. CallScreen pop
```

### ICE Sunucu Yapılandırması

| Tür | Adres | Kullanım |
|-----|-------|----------|
| STUN | `stun:stun.l.google.com:19302` | NAT traversal keşfi (ücretsiz, Google) |
| STUN | `stun:stun1.l.google.com:19302` | Yedek STUN |
| STUN | `stun:stun2.l.google.com:19302` | Yedek STUN |
| TURN | `turn:turn.signai.app:3478` (UDP) | NAT arkasında relay (henüz deploy edilmedi) |
| TURN | `turn:turn.signai.app:3478` (TCP) | Firewall arkası relay (henüz deploy edilmedi) |

**NOT:** STUN sunucuları çalışıyor (Google). TURN sunucusu (`turn.signai.app`) henüz kurulmadı — aynı ağdaki cihazlar STUN ile çalışır, farklı ağlardaki cihazlar TURN gerektirir.

---

## 🤖 Yapay Zeka Sistemi (İşaret Dili Algılama)

### Pipeline Akışı

```
WebRTC getUserMedia() → Yerel video akışı
         │
         ▼
Timer.periodic(200ms) — her 200 milisaniyede bir:
         │
         ▼
captureFrame() — video track'ten PNG yakalama
         │
         ▼
dart:ui instantiateImageCodec — PNG'yi bellekte decode et
         │
         ▼
image.toByteData(rawRgba) — ham piksel verisine çevir
         │
         ▼
InputImage.fromBytes(BGRA8888) — ML Kit formatına çevir
         │
         ▼
ML Kit PoseDetector.processImage() — 33 vücut noktası algıla
         │
         ▼
_detect(Pose) — 10 hareket kuralını kontrol et
         │
         ▼
_addToBuffer() — son 10 algılamayı tampona ekle
         │
         ▼
_checkConsistency() — 10 üzerinden 5+ aynı mı?
         │
    EVET ▼
onWordConfirmed("Merhaba") → altyazı olarak gönder
```

### Algılanan 10 Türk İşaret Dili Hareketi

| # | Hareket | Nasıl Yapılır | Algılama Mantığı | Güven |
|---|---------|---------------|------------------|-------|
| 1 | **Yardım** 🆘 | İki el yukarı kalkık | Her iki bilek burunun üstünde, dirsekler omuzların üstünde, bilekler birbirinden uzak | %92 |
| 2 | **Merhaba** 👋 | Sağ el baş üstünde | Sağ bilek başın üstünde (>0.3×omuz genişliği), sol el AŞAĞIDA (Yardım'dan ayırt etmek için). Yatay sallanma varsa bonus | %85-93 |
| 3 | **Hoşçakal** 👋 | Sağ el yüz hizasında sallama | El yüz hizasında (burundan 0.35×OG mesafe), yüzün yanında, belirgin yatay sallanma (>0.2×OG) | %84 |
| 4 | **Hayır** ☝️ | İşaret parmağı sağa sola | İşaret parmağı bileğin üstünde, baş hizasında, yatay sallanma (>0.15×OG), parmak uzanmış | %82 |
| 5 | **Teşekkürler** 🙏 | Sağ el çeneden aşağı doğru | Bilek çene yakınında (burunun altında), ortalanmış, AŞAĞI hareket (>0.1×OG dikey hareket) | %83 |
| 6 | **Evet** ✊ | Baş önünde yumruk aşağı | Yumruk kapalı (işaret+başparmak bileğe yakın), baş hizasında, aşağı doğru hareket | %80 |
| 7 | **Yemek** 🍽️ | Sağ el ağza doğru | Ağız bölgesinde (burundan 0.05-0.35×OG altında), yüze yakın, dirsek bileğin altında | %81 |
| 8 | **Su** 💧 | C şekli el çeneye | Çene altında, ortalanmış, C şekli (başparmak-işaret arası 0.05-0.25×OG), dirsek altta | %78 |
| 9 | **Dur/Tamam** ✋ | Avuç ileri, göğüs hizası | Göğüs hizasında, avuç açık (işaret-bilek >0.15×OG), sabit (düşük hareket) | %77 |
| 10 | **Ben** 👆 | İşaret parmağı göğse | Göğüs hizasında, ortalanmış, işaret parmağı AŞAGI (bileğin altında), vücuda yakın | %76 |

### Normalizasyon

Tüm mesafeler **omuz genişliğine (OG)** göre normalize edilir. ML Kit'ten gelen sol ve sağ omuz noktaları arasındaki mesafe ölçülür. Bu sayede kameraya yakın/uzak duran kullanıcılar için aynı kurallar çalışır.

### Tutarlılık Kontrolü

- Son 10 frame'in algılamaları bir buffer'da tutulur
- 10 frame'den en az 5'i aynı hareketi gösteriyorsa → **kelime onaylanır**
- Aynı kelime 2 saniye içinde tekrar onaylanmaz (spam önleme)
- Onaylanan kelimeler cümleye eklenir ve altyazı olarak gönderilir

---

## 🎤 Konuşma → Yazı (Speech-to-Text) Sistemi

```
Mikrofon → speech_to_text paketi → Türkçe tanıma
                    │
                    ▼
          30 saniyelik dinleme penceresi
                    │
            final sonuç gelirse
                    │
                    ▼
          onTextRecognized("Nasılsın") → CallProvider
                    │
                    ▼
          signaling.sendSubtitle(targetUserId, text)
                    │
                    ▼
          Socket.IO → karşı cihaz → ekranda gösterilir
                    │
          500ms bekle → otomatik yeniden dinlemeye başla
          (max 100 otomatik restart — sonsuz döngü önleme)
```

**Desteklenen dil:** Türkçe (`tr_TR`) — varsayılan olarak seçilir. Cihazda bulunan diğer diller de kullanılabilir.

---

## 🌐 Sunucu API'leri

### REST API Endpoints

| Method | Path | Auth | Açıklama |
|--------|------|------|----------|
| `GET` | `/` | ❌ | Sağlık kontrolü — sunucu versiyonu, çevrimiçi sayısı, aktif arama sayısı |
| `POST` | `/api/auth/register` | ❌ | Kullanıcı kaydı. `{username}` gönder → `{userId, username, token}` al |
| `GET` | `/api/users` | ✅ JWT | Çevrimiçi kullanıcı listesi |
| `GET` | `/api/users/:userId` | ✅ JWT | Tek kullanıcı bilgisi |
| `GET` | `/api/calls/history` | ✅ JWT | Arama geçmişi (son 20) |

**Rate Limit:** `/api/*` için dakikada max 100 istek.

### Socket.IO Olayları

#### İstemci → Sunucu (7 olay)

| Olay | Veri | Ne Yapar |
|------|------|----------|
| `register` | `{userId, username}` | Kullanıcıyı çevrimiçi olarak kaydet |
| `call-user` | `{targetUserId, offer, callerInfo}` | Arama başlat (SDP offer ile) |
| `answer-call` | `{targetUserId, answer}` | Aramayı kabul et (SDP answer ile) |
| `reject-call` | `{targetUserId}` | Aramayı reddet |
| `ice-candidate` | `{targetUserId, candidate}` | ICE adayını ilet |
| `end-call` | `{targetUserId}` | Aramayı sonlandır |
| `subtitle` | `{targetUserId, text, language}` | Altyazı gönder (max 500 karakter) |

#### Sunucu → İstemci (11 olay)

| Olay | Veri | Ne Yapar |
|------|------|----------|
| `incoming-call` | `{callerId, callerName, offer, callId}` | Gelen arama bildirimi |
| `call-answered` | `{answer, answeredBy}` | Arama kabul edildi |
| `call-rejected` | `{rejectedBy}` | Arama reddedildi |
| `call-ended` | `{endedBy, reason?}` | Arama sonlandı |
| `ice-candidate` | `{candidate, from}` | ICE adayı geldi |
| `subtitle` | `{text, language, from, timestamp}` | Altyazı geldi |
| `user-online` | `{userId, username}` | Bir kullanıcı çevrimiçi oldu |
| `user-offline` | `{userId, username}` | Bir kullanıcı çevrimdışı oldu |
| `online-users` | `{users: [...]}` | Tam çevrimiçi kullanıcı listesi |
| `call-error` | `{message}` | Arama hatası |
| `error` | `{message}` | Genel hata |

**Socket Rate Limit:** Soket başına 60 saniyede max 50 olay.

---

## 📦 Kullanılan Teknolojiler ve Paketler

### Flutter (Mobil Uygulama)

| Paket | Versiyon | Ne İçin |
|-------|----------|---------|
| `flutter_webrtc` | ^0.12.4 | Peer-to-peer gerçek zamanlı video/ses |
| `google_mlkit_pose_detection` | ^0.12.0 | Cihaz üzerinde vücut noktası algılama (33 nokta) |
| `speech_to_text` | ^7.0.0 | Cihaz üzerinde konuşma tanıma |
| `socket_io_client` | ^2.0.3+1 | Socket.IO ile sunucuya bağlanma |
| `provider` | ^6.1.1 | State management (ChangeNotifier) |
| `http` | ^1.2.1 | REST API HTTP istekleri |
| `permission_handler` | ^11.3.0 | Çalışma anında izin isteme |
| `shared_preferences` | ^2.2.2 | JWT token'ı yerel depolamada saklama |
| `path_provider` | ^2.1.5 | Geçici dosya yolları |
| `google_fonts` | ^6.1.0 | Inter fontu |
| `wakelock_plus` | ^1.2.1 | Arama sırasında ekranı açık tutma |
| `vibration` | ^2.0.0 | Gelen arama titreşimi |
| `cupertino_icons` | ^1.0.8 | iOS tarzı ikonlar |

### Node.js (Sunucu)

| Paket | Versiyon | Ne İçin |
|-------|----------|---------|
| `express` | ^4.18.2 | HTTP sunucu framework |
| `socket.io` | ^4.7.4 | WebSocket tabanlı gerçek zamanlı iletişim |
| `pg` | ^8.12.0 | PostgreSQL veritabanı istemcisi |
| `jsonwebtoken` | ^9.0.2 | JWT token üretim ve doğrulama |
| `helmet` | ^7.1.0 | HTTP güvenlik başlıkları |
| `express-rate-limit` | ^7.1.5 | API rate limiting |
| `cors` | ^2.8.5 | Cross-origin kaynak paylaşımı |
| `uuid` | ^9.0.0 | Benzersiz ID üretimi |
| `dotenv` | ^16.4.5 | Ortam değişkenleri (.env dosyası) |

---

## 🛡️ Güvenlik Önlemleri

| Önlem | Nerede | Detay |
|-------|--------|-------|
| JWT Kimlik Doğrulama | auth.js | Her REST ve Socket bağlantısı token ile doğrulanır |
| JWT Secret Kontrolü | auth.js | `JWT_SECRET` env yoksa sunucu başlamaz (`process.exit(1)`) |
| Token Süresi Kontrolü | auth_provider.dart | Her açılışta `exp` claim kontrol edilir → süresi geçmişse logout |
| Input Validation | validation.js | Tüm gelen veriler (UUID, SDP, ICE, username) doğrulanır |
| Rate Limiting (REST) | server.js | `/api/*` dakikada max 100 istek |
| Rate Limiting (Socket) | server.js | Soket başına 60 saniyede max 50 olay |
| Helmet | server.js | HTTP güvenlik başlıkları (XSS, clickjacking koruması) |
| CORS | server.js | Cross-origin kontrol |
| P2P Şifreleme | WebRTC | DTLS/SRTP ile uçtan uca şifreli video/ses (sunucu göremez) |
| Altyazı Limiti | server.js | Max 500 karakter (XSS/spam koruması) |

---

## 📊 Proje Tamamlanma Durumu

### ✅ Tamamlanan Kısımlar (~%85)

| Alan | Durum | Detay |
|------|-------|-------|
| Flutter uygulama yapısı | ✅ %100 | 4 ekran, 4 widget, 5 servis, 2 provider |
| UI/UX Tasarımı | ✅ %100 | Karanlık tema, animasyonlar, gradient'ler |
| Sunucu altyapısı | ✅ %100 | Express + Socket.IO + PostgreSQL |
| JWT Kimlik Doğrulama | ✅ %100 | Üretim, doğrulama, saklama, süre kontrolü |
| Veritabanı | ✅ %100 | Şema, CRUD, indeksler, stale kayıt temizleme |
| Socket.IO Sinyalizasyon | ✅ %100 | 7 istemci + 11 sunucu olayı, reconnect, re-register |
| WebRTC Entegrasyonu | ✅ %95 | Offer/answer, ICE kuyruklama, medya kontrol |
| İşaret Dili AI Pipeline | ✅ %90 | 10 hareket tanımlandı, bellekte frame işleme, tutarlılık kontrolü |
| Konuşma→Yazı | ✅ %90 | Türkçe tanıma, otomatik yeniden başlatma, döngü sınırı |
| İzin Yönetimi | ✅ %100 | Kamera, mikrofon, konuşma izinleri |
| Hata Yönetimi | ✅ %90 | Try/catch, hata mesajları, graceful degradation |
| Güvenlik | ✅ %90 | JWT, rate limit, validation, helmet |
| Input Validation | ✅ %100 | UUID, SDP, ICE, username doğrulama |

### ⚠️ Gerçek Cihazda Test Gerektiren Kısımlar (~%15)

| Alan | Durum | Neden |
|------|-------|-------|
| WebRTC P2P Bağlantı | ⚠️ Test Gerekli | STUN/TURN sunucuları, NAT traversal, ICE negotiation — iki farklı ağdaki cihaz gerektirir |
| TURN Sunucusu | ❌ Kurulmadı | `turn.signai.app:3478` yapılandırıldı ama deploy edilmedi. Aynı WiFi'de STUN yeterli, farklı ağlarda TURN şart |
| İşaret Dili Doğruluğu | ⚠️ Kalibrasyon | Kamera açısı, ışık, mesafe, giysi rengi doğruluğu etkiler. Gerçek kullanıcılarla test+ayar gerekli |
| ML Kit Performansı | ⚠️ Test Gerekli | 200ms'de bir frame işleme — düşük donanımlı cihazlarda gecikme olabilir |
| STT Platform Davranışı | ⚠️ Test Gerekli | 30sn dinleme penceresi + otomatik restart — iOS/Android farklılıkları |
| Sunucu Deploy | ❌ Yapılmadı | `localhost:3001` — gerçek kullanım için Railway/Heroku/VPS'e deploy gerekli |
| Ses Yönlendirme | ⚠️ Test Gerekli | Hoparlör/kulaklık geçişi platform bağımlı |
| Arka Plan Davranışı | ⚠️ Test Gerekli | Uygulama arka plana alındığında arama durumu |

---

## 🔧 Çalıştırmak İçin Gerekenler

### 1. PostgreSQL

```bash
# PostgreSQL kurulu olmalı
# Veritabanı oluştur:
createdb signai_db
```

### 2. Sunucu

```bash
cd signaling_server

# .env dosyası oluştur:
echo "DATABASE_URL=postgresql://localhost:5432/signai_db" > .env
echo "JWT_SECRET=your-super-secret-key-here" >> .env
echo "PORT=3001" >> .env

# Bağımlılıkları kur ve başlat:
npm install
npm run dev   # nodemon ile (geliştirme)
npm start     # production
```

### 3. Flutter Uygulaması

```bash
cd signai_app
flutter pub get
flutter run
```

**Android gereksinimleri:** `minSdkVersion 24`, İnternet + Kamera + Mikrofon + Titreşim izinleri (AndroidManifest.xml'de tanımlı)

**iOS gereksinimleri:** Info.plist'te kamera, mikrofon, konuşma tanıma, yerel ağ izin açıklamaları tanımlı. Sadece portrait modu.

### 4. Gerçek Cihazda Test

Emülatörde kamera ve WebRTC çalışmaz. Gerçek test için:
1. Sunucu IP'sini `constants.dart`'ta güncelle (`localhost` yerine bilgisayar IP'si)
2. İki fiziksel cihaz veya bir fiziksel + bir emülatör kullan
3. Aynı WiFi ağında olduklarından emin ol

---

## 📈 İstatistikler

| Metrik | Değer |
|--------|-------|
| Toplam Dart dosyası | 16 |
| Toplam JS dosyası | 4 |
| Toplam Dart kodu | ~3,952 satır |
| Toplam JS kodu | ~962 satır |
| **Toplam kod** | **~4,914 satır** |
| Flutter ekranları | 4 |
| Flutter widget'ları | 4 |
| Flutter servisleri | 5 |
| Flutter provider'ları | 2 |
| REST API endpoint'leri | 5 |
| Socket.IO olayları | 18 (7 istemci + 11 sunucu) |
| Veritabanı tabloları | 2 |
| Veritabanı indeksleri | 5 |
| Algılanan işaret sayısı | 10 |
| Flutter bağımlılıkları | 13 |
| Node.js bağımlılıkları | 9 |

---

## 🎯 Özet

**SignAI**, Flutter + Node.js + PostgreSQL + WebRTC + ML Kit + Speech-to-Text teknolojileriyle geliştirilmiş, işaret dili ile konuşma arasında köprü kuran bir gerçek zamanlı iletişim uygulamasıdır.

Uygulama:
- İki kullanıcı arasında **P2P şifreli görüntülü arama** kurar
- Bir tarafın **işaret dili hareketlerini** kamerayla algılayıp **yazıya çevirir**
- Diğer tarafın **konuşmasını** mikrofon ile dinleyip **yazıya çevirir**
- Her iki taraf da karşı tarafı **altyazılardan** anlar

Kodun yaklaşık **%85'i tamamlanmış** ve sıfır hata ile derlenmektedir. Kalan **%15** gerçek cihaz testi, TURN sunucusu kurulumu, işaret dili kalibrasyonu ve production deployment gerektirmektedir.
