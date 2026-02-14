<div align="center">

# 🤟 SignAI

### AI-Powered Sign Language Video Calling Platform

*Breaking communication barriers between deaf and hearing individuals through real-time AI translation*

[![Flutter](https://img.shields.io/badge/Flutter-3.2.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-18.0+-339933?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![WebRTC](https://img.shields.io/badge/WebRTC-P2P-333333?style=for-the-badge&logo=webrtc&logoColor=white)](https://webrtc.org)

[Features](#-features) • [Demo](#-demo) • [Architecture](#-architecture) • [Installation](#-installation) • [Usage](#-usage) • [API](#-api-reference) • [Contributing](#-contributing)

---

<!-- BURAYA: Uygulama ekran görüntüsü veya demo GIF'i ekle -->
<!-- Örnek: Ana ekran + Arama ekranı yan yana -->

</div>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Demo](#-demo)
- [How It Works](#-how-it-works)
- [System Architecture](#-architecture)
- [Technology Stack](#-technology-stack)
- [Project Structure](#-project-structure)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [API Reference](#-api-reference)
- [Security](#-security)
- [Contributing](#-contributing)
- [License](#-license)
- [Contact](#-contact)

---

## 🌟 Overview

**SignAI** is an innovative AI-powered video calling application designed to eliminate communication barriers between deaf and hearing individuals. Using advanced machine learning and WebRTC technology, SignAI provides real-time sign language detection and speech-to-text conversion, enabling seamless bidirectional communication.

### The Problem

Over 466 million people worldwide are deaf or hard of hearing. Traditional video calling platforms don't provide real-time translation between sign language and spoken language, creating significant communication barriers.

### The Solution

SignAI uses Google ML Kit's pose detection to recognize Turkish Sign Language (TİD) gestures in real-time while simultaneously converting speech to text, displaying both as live subtitles during video calls.

<!-- BURAYA: Sistem akış diyagramı veya kullanım senaryosu görseli -->

---

## ✨ Features

### 🎥 **P2P Encrypted Video Calling**
- End-to-end encrypted video/audio using WebRTC DTLS-SRTP
- Low-latency peer-to-peer connection
- HD video quality (640×480 @ 24fps)
- STUN/TURN server support for NAT traversal

### 🤖 **AI-Powered Sign Language Detection**
- Real-time recognition of 10 Turkish Sign Language gestures
- Google ML Kit Pose Detection integration
- Gesture validation with consistency buffer (5/10 frames)
- Smart cooldown mechanism to prevent spam

**Recognized Gestures:**
| Turkish | English | Detection Method |
|---------|---------|------------------|
| Merhaba | Hello | Right hand raised above head |
| Teşekkürler | Thank you | Hand moves from chin downward |
| Evet | Yes | Fist at head level, downward motion |
| Hayır | No | Index finger swaying left-right |
| Yardım | Help | Both arms raised above head |
| Yemek | Food | Right hand at mouth level |
| Su | Water | C-shaped hand at chin level |
| Dur | Stop | Open palm at chest level |
| Hoşçakal | Goodbye | Hand waving at face level |
| Ben | Me | Index finger pointing to chest |

### 🎤 **Speech-to-Text Conversion**
- Real-time Turkish speech recognition
- Automatic restart mechanism (30-second windows)
- Partial and final transcription results
- Low-latency subtitle display

### 💬 **Dual Subtitle System**
- 🤟 **Purple subtitles** for sign language (AI detected)
- 🎤 **Cyan subtitles** for speech (STT converted)
- Bidirectional subtitle streaming
- 3-second display duration with fade effects

### 👤 **User Management**
- JWT-based authentication (7-day expiry)
- Profile photo upload/delete
- Online status indicator
- Call history tracking

### 🎨 **Modern UI/UX**
- Dark/Light theme support
- Smooth animations and transitions
- Responsive design
- Picture-in-picture video layout
- Draggable local video preview

<!-- BURAYA: UI ekran görüntüleri (Login, Home, Call screens) -->

---

## 🎬 Demo

<!-- BURAYA: Demo videosu veya GIF animasyonu ekle -->
<!-- Örnek kullanım senaryosu: -->
<!-- 1. Kullanıcı A "Merhaba" işareti yapıyor → Kullanıcı B ekranında "Merhaba" altyazısı görünüyor -->
<!-- 2. Kullanıcı B "Selam" diyor → Kullanıcı A ekranında "Selam" altyazısı görünüyor -->

---

## 🔄 How It Works

```
┌──────────────┐         ┌──────────────────┐         ┌──────────────┐
│  User A      │◄───────►│  Signaling       │◄───────►│  User B      │
│  (Flutter)   │   WS    │  Server          │   WS    │  (Flutter)   │
│              │         │  (Node.js)       │         │              │
│  🤟 Signs    │         └──────────────────┘         │  🎤 Speaks   │
│  "Hello"     │              ▲                        │  "Hi"        │
│              │              │ SDP/ICE Signaling      │              │
│  AI: "Hello" │              │                        │  STT: "Hi"   │
│  ─────────────┼──────── P2P (DTLS-SRTP) ─────────────┼──────────────│
│  Subtitle:   │      Direct Video/Audio Stream        │  Subtitle:   │
│  "Hi" 🎤     │      (NOT through server)             │  "Hello" 🤟  │
└──────────────┘                                        └──────────────┘
```

### Call Flow Sequence

1. **User A** initiates call → Creates WebRTC offer → Sends via signaling server
2. **Server** forwards incoming call notification to User B
3. **User B** accepts → Creates WebRTC answer → Sends back via signaling server
4. **ICE Candidates** exchanged bidirectionally for NAT traversal
5. **P2P Connection** established with DTLS-SRTP encryption
6. **AI Pipeline** starts:
   - Every 200ms, capture frame from WebRTC camera
   - Process through ML Kit Pose Detection
   - Detect gestures and form sentences
   - Send subtitles to remote peer via WebSocket
7. **Speech Recognition** runs continuously:
   - Listen to microphone
   - Convert speech to text in real-time
   - Send subtitles to remote peer
8. **Call End** → Close WebRTC connection, stop AI processing

<!-- BURAYA: Sequence diagram görseli -->

---

## 🏗 Architecture

### System Overview

```
┌─────────────────────────────────────────────────────┐
│                 PRESENTATION LAYER                   │
│  Screens (6)  │  Widgets (4)  │  Theme/Constants    │
├─────────────────────────────────────────────────────┤
│                 STATE MANAGEMENT                     │
│  AuthProvider  │  CallProvider  │  ThemeProvider    │
├─────────────────────────────────────────────────────┤
│                 SERVICE LAYER                        │
│  WebRTC │ Signaling │ SignLanguage │ STT │ Perms   │
├─────────────────────────────────────────────────────┤
│                 NETWORK LAYER                        │
│  Socket.IO (WS) │ HTTP/REST │ WebRTC (P2P)         │
├─────────────────────────────────────────────────────┤
│                 BACKEND                              │
│  Express │ Socket.IO │ PostgreSQL │ JWT/bcrypt     │
└─────────────────────────────────────────────────────┘
```

### Database Schema

```sql
-- Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_online BOOLEAN DEFAULT false
);

-- Call History Table
CREATE TABLE call_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    caller_id UUID REFERENCES users(id),
    callee_id UUID REFERENCES users(id),
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    status VARCHAR(20) DEFAULT 'initiated',
    end_reason VARCHAR(50)
);
```

<!-- BURAYA: Architecture diagram veya component interaction görseli -->

---

## 🛠 Technology Stack

### Mobile Application (Flutter)

| Technology | Version | Purpose |
|------------|---------|---------|
| **Flutter** | 3.2.0+ | Cross-platform mobile framework |
| **flutter_webrtc** | 0.12.4 | P2P video/audio calling |
| **google_mlkit_pose_detection** | 0.12.0 | Sign language gesture detection |
| **speech_to_text** | 7.0.0 | Speech-to-text conversion |
| **socket_io_client** | 2.0.3+1 | WebSocket signaling |
| **provider** | 6.1.1 | State management |
| **shared_preferences** | 2.2.2 | Local persistent storage |

### Backend (Node.js)

| Technology | Version | Purpose |
|------------|---------|---------|
| **Express** | 4.18.2 | HTTP server & REST API |
| **Socket.IO** | 4.7.4 | Real-time WebSocket communication |
| **PostgreSQL** | 14+ | Relational database |
| **jsonwebtoken** | 9.0.2 | JWT authentication |
| **bcrypt** | 6.0.0 | Password hashing |
| **helmet** | 7.1.0 | Security headers |
| **express-rate-limit** | 7.1.5 | API rate limiting |

### Infrastructure

- **WebRTC Protocols:** DTLS-SRTP, ICE, SDP
- **STUN Servers:** Google STUN (`stun.l.google.com:19302`)
- **TURN Servers:** OpenRelay (`openrelay.metered.ca`)
- **Target Platform:** Android (min SDK 21)

---

## 📁 Project Structure

```
signai/
├── signai_app/                      # Flutter Mobile Application
│   ├── lib/
│   │   ├── main.dart                # App entry point
│   │   ├── screens/                 # 6 UI screens
│   │   │   ├── splash_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── home_screen.dart
│   │   │   ├── call_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   └── privacy_security_screen.dart
│   │   ├── providers/               # State management
│   │   │   ├── auth_provider.dart
│   │   │   ├── call_provider.dart
│   │   │   └── theme_provider.dart
│   │   ├── services/                # Business logic
│   │   │   ├── webrtc_service.dart
│   │   │   ├── signaling_service.dart
│   │   │   ├── sign_language_service.dart
│   │   │   ├── speech_to_text_service.dart
│   │   │   └── permission_service.dart
│   │   ├── widgets/                 # Reusable components
│   │   │   ├── call_controls.dart
│   │   │   ├── call_timer.dart
│   │   │   ├── incoming_call_dialog.dart
│   │   │   └── subtitle_overlay.dart
│   │   └── utils/
│   │       ├── constants.dart
│   │       └── theme.dart
│   ├── android/                     # Android native code
│   ├── ios/                         # iOS native code
│   └── pubspec.yaml
│
└── signaling_server/                # Node.js Signaling Server
    ├── server.js                    # Main server (Express + Socket.IO)
    ├── auth.js                      # JWT + bcrypt authentication
    ├── db.js                        # PostgreSQL database layer
    ├── validation.js                # Input validation
    ├── package.json
    └── .env.example
```

**Code Statistics:**
- Flutter App: ~4,424 lines of Dart
- Backend: ~1,247 lines of JavaScript
- **Total:** ~5,671 lines of code

---

## 🚀 Installation

### Prerequisites

- Flutter SDK ≥ 3.2.0
- Node.js ≥ 18.0.0
- PostgreSQL ≥ 14
- Android Studio + Android Emulator or physical device

### 1. Clone Repository

```bash
git clone https://github.com/codewithme13/SignAi.git
cd SignAi
```

### 2. Database Setup

```bash
# Create PostgreSQL database
createdb signai_db

# Tables will be auto-created on first server run
```

### 3. Backend Setup

```bash
cd signaling_server

# Install dependencies
npm install

# Configure environment variables
cp .env.example .env
nano .env
```

Edit `.env` file:
```env
DATABASE_URL=postgresql://username:password@localhost:5432/signai_db
JWT_SECRET=your-super-secret-key-change-this
JWT_EXPIRY=7d
PORT=3001
CORS_ORIGIN=*
```

```bash
# Start server
npm start
# Server running at http://localhost:3001
```

### 4. Mobile App Setup

```bash
cd ../signai_app

# Install Flutter dependencies
flutter pub get

# Update server URL in lib/utils/constants.dart
# Change: static const String serverUrl = 'http://YOUR_SERVER_IP:3001';

# For emulator, use ADB reverse:
adb reverse tcp:3001 tcp:3001

# Run on connected device
flutter run

# Or build APK
flutter build apk --release
```

---

## ⚙️ Configuration

### Server Configuration

Edit `signaling_server/.env`:

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | Required |
| `JWT_SECRET` | Secret key for JWT signing | Required |
| `JWT_EXPIRY` | Token expiration time | `7d` |
| `PORT` | Server port | `3001` |
| `CORS_ORIGIN` | Allowed CORS origins | `*` |

### App Configuration

Edit `signai_app/lib/utils/constants.dart`:

```dart
class AppConstants {
  static const String serverUrl = 'http://YOUR_SERVER_IP:3001';
  static const int connectionTimeout = 30;
  static const int maxReconnectAttempts = 5;
  static const int subtitleDisplayDuration = 3;
}
```

### Android Permissions

Required permissions in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

---

## 💡 Usage

### For End Users

1. **Register/Login**
   - Launch app → Enter username and password
   - Tap "Kayıt Ol" (Register) or "Giriş Yap" (Login)

2. **Start a Call**
   - On Home screen, enter target User ID or select from online users
   - Tap "Görüntülü Arama Başlat" (Start Video Call)
   - Grant camera/microphone permissions if prompted

3. **During Call**
   - 🤟 Make sign language gestures → AI detects and shows purple subtitles
   - 🎤 Speak → Speech-to-text converts and shows cyan subtitles
   - Toggle camera/mic using bottom controls
   - Tap red phone icon to end call

4. **View Profile**
   - Tap profile card → Upload photo, change theme, view settings

### For Developers

#### Testing with Android Emulator

```bash
# Start emulator
~/Library/Android/sdk/emulator/emulator -avd Medium_Phone_API_36 &

# Set up port forwarding
adb reverse tcp:3001 tcp:3001

# Install and run
flutter run
```

#### Testing Sign Language Detection

The AI recognizes gestures when:
- Face is clearly visible in frame
- Hands are raised above waist level
- Gesture held for at least 5 frames (consistency buffer)
- 2-second cooldown between same gestures

<!-- BURAYA: Gesture detection demo GIF veya örnek ekran görüntüleri -->

---

## 📡 API Reference

### REST Endpoints

#### Authentication

**POST** `/api/auth/register`
```json
Request:
{
  "username": "john_doe",
  "password": "secure123"
}

Response (201):
{
  "success": true,
  "data": {
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "username": "john_doe",
    "token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

**POST** `/api/auth/login`
- Same request/response format as register

#### Users

**GET** `/api/users` (Auth required)
- Returns list of online users with profile photos

**GET** `/api/users/:userId` (Auth required)
- Get specific user details

#### Profile

**POST** `/api/profile/photo` (Auth required)
- Upload profile photo (multipart/form-data, max 2MB)
- Allowed formats: JPEG, PNG, GIF, WEBP

**DELETE** `/api/profile/photo` (Auth required)
- Delete profile photo

#### Call History

**GET** `/api/calls/history` (Auth required)
- Returns last 50 call records for authenticated user

### WebSocket Events

#### Client → Server

| Event | Data | Description |
|-------|------|-------------|
| `register` | `{ userId }` | Register user as online |
| `call-user` | `{ targetUserId, offer, callerName }` | Initiate call |
| `answer-call` | `{ targetUserId, answer }` | Accept call |
| `reject-call` | `{ callerId }` | Reject call |
| `ice-candidate` | `{ targetUserId, candidate }` | Share ICE candidate |
| `end-call` | `{ targetUserId }` | End call |
| `subtitle` | `{ targetUserId, text, type }` | Send subtitle |

#### Server → Client

| Event | Data | Description |
|-------|------|-------------|
| `registered` | `{ userId, onlineUsers }` | Registration confirmed |
| `incoming-call` | `{ callerId, callerName, callerPhoto, offer }` | Incoming call notification |
| `call-answered` | `{ answer }` | Call accepted |
| `call-rejected` | `{ reason }` | Call rejected |
| `call-ended` | `{}` | Call terminated |
| `ice-candidate` | `{ candidate }` | Remote ICE candidate |
| `subtitle` | `{ text, type }` | Remote subtitle |
| `user-online` | `{ userId, username, photoUrl }` | User came online |
| `user-offline` | `{ userId }` | User went offline |

---

## 🔒 Security

### Communication Security

| Layer | Method | Details |
|-------|--------|---------|
| **Video/Audio** | DTLS-SRTP | WebRTC's built-in end-to-end encryption |
| **Signaling** | WSS/HTTPS | WebSocket Secure (TLS in production) |
| **API** | JWT Bearer | Token-based authentication |
| **Socket.IO** | JWT Auth | WebSocket connection authentication |
| **Passwords** | bcrypt (12 rounds) | One-way hashing, brute-force resistant |

### Server Security

- **Rate Limiting:** 100 req/min (REST), 50 events/min (Socket)
- **Helmet:** XSS, clickjacking, MIME sniffing protection
- **CORS:** Configurable origin restriction
- **Input Validation:** All inputs sanitized and validated
- **File Upload:** 2MB limit, MIME type verification

### Privacy

- **P2P Connection:** Video/audio data does NOT pass through server
- **Token Expiry:** 7 days (configurable)
- **Password Requirements:** Minimum 6 characters
- **No Data Logging:** Subtitle content not stored on server

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Test thoroughly (unit tests, integration tests)
5. Commit: `git commit -m 'Add amazing feature'`
6. Push: `git push origin feature/amazing-feature`
7. Open a Pull Request

### Code Style

- **Flutter:** Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- **Node.js:** Use ESLint with provided config
- **Commits:** Use [Conventional Commits](https://www.conventionalcommits.org/)

### Areas for Contribution

- [ ] Add more sign language gestures (currently 10 → expand to 50+)
- [ ] Support for additional languages (currently Turkish only)
- [ ] iOS platform support
- [ ] Group video calling (multi-party)
- [ ] AI model training improvements
- [ ] UI/UX enhancements
- [ ] Documentation translations

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Contact

**Project Maintainer:** codewithme13

- GitHub: [@codewithme13](https://github.com/codewithme13)
- Project Link: [https://github.com/codewithme13/SignAi](https://github.com/codewithme13/SignAi)

---

## 🙏 Acknowledgments

- **Google ML Kit** for pose detection capabilities
- **WebRTC** community for P2P communication standards
- **Flutter** team for excellent cross-platform framework
- **Turkish Sign Language** experts for gesture validation
- OpenRelay for free TURN server services

---

<div align="center">

### ⭐ Star this repo if you find it helpful!

Made with ❤️ for the deaf and hard-of-hearing community

[Back to Top](#-signai)

</div>
