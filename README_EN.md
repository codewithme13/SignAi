<div align="center">

# 🤟 SignAI

### AI-Powered Bidirectional Sign Language Video Calling Platform

*Breaking communication barriers between deaf and hearing individuals through real-time AI-powered bidirectional translation*

[![Flutter](https://img.shields.io/badge/Flutter-3.2.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-18.0+-339933?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org)
[![WebRTC](https://img.shields.io/badge/WebRTC-P2P-333333?style=for-the-badge&logo=webrtc&logoColor=white)](https://webrtc.org)
[![Render](https://img.shields.io/badge/Deploy-Render.com-46E3B7?style=for-the-badge&logo=render&logoColor=white)](https://render.com)
[![Lottie](https://img.shields.io/badge/Animations-Lottie-00DDB3?style=for-the-badge&logo=airbnb&logoColor=white)](https://lottiefiles.com)

[Features](#-features) • [Demo](#-demo) • [Architecture](#-architecture) • [Deployment](#-deployment) • [Installation](#-installation) • [API](#-api-reference)

---

**🌐 Live Server:** `https://signai-5g3q.onrender.com`

**📱 APK Sizes:** arm64-v8a (54MB) | armeabi-v7a (43MB) | x86_64 (58MB)

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

**SignAI** is an innovative AI-powered video calling application that enables **true bidirectional communication** between deaf and hearing individuals. Unlike existing solutions, SignAI provides:

- **Sign Language → Text:** Real-time AI-powered gesture detection converts sign language to readable subtitles
- **Speech → Sign Language Animation:** Spoken words are converted to beautiful Lottie sign language animations

This creates a complete communication loop where both parties can express themselves naturally in their preferred language.

### The Problem

Over 466 million people worldwide are deaf or hard of hearing. Traditional video calling platforms lack real-time translation capabilities, forcing deaf individuals to rely on interpreters or resort to text-only communication. This creates significant communication barriers in daily life, professional settings, and emergency situations.

### The Solution

SignAI implements a **dual AI pipeline**:

1. **Visual AI (Sign → Text):** Uses Google ML Kit's advanced pose detection to recognize Turkish Sign Language (TİD) gestures in real-time, converting them to text subtitles visible to the hearing user.

2. **Audio AI with Animation (Speech → Sign):** Utilizes speech recognition to convert spoken words into animated Lottie sign language gestures, displayed to the deaf user as smooth, professional animations.

<!-- BURAYA: Sistem akış diyagramı veya kullanım senaryosu görseli -->

---

## ✨ Features

### 🎥 **P2P Encrypted Video Calling**
- End-to-end encrypted video/audio using WebRTC DTLS-SRTP
- True peer-to-peer connection - video/audio NEVER passes through server
- Adaptive video quality with HD support (640×480 @ 24fps)
- STUN/TURN server support for NAT traversal behind firewalls
- Automatic ICE candidate gathering for optimal connection path

### 🤖 **AI-Powered Sign Language Detection (Sign → Text)**
- Real-time recognition of Turkish Sign Language gestures
- Google ML Kit Pose Detection with 33-point skeletal tracking
- Advanced gesture validation with consistency buffer (5/10 frames minimum)
- Smart cooldown mechanism (2 seconds) to prevent duplicate detection
- Sentence building mode for natural communication flow
- Confidence scoring for accurate gesture matching

**Detection Pipeline:**
```
Camera Frame → ML Kit Pose → Landmark Analysis → Gesture Classification → Subtitle Generation
     ↓              ↓               ↓                    ↓                      ↓
  200ms/frame   33 keypoints   Angle/Position     Pattern Match          WebSocket Send
```

**Recognized Gestures Include:**
| Turkish | English | Detection Method |
|---------|---------|------------------|
| Merhaba | Hello | Right hand raised above head |
| Teşekkürler | Thank you | Hand moves from chin downward |
| Evet / Hayır | Yes / No | Head nod / Index finger swaying |
| Yardım | Help | Both arms raised above head |
| ...and more | | Full gesture library included |

### 🎬 **Speech-to-Sign Animation System (Speech → Sign)**
- **Lottie-powered** professional sign language animations
- Real-time keyword detection in speech stream
- Smooth, accessible animations for deaf users
- Overlay display on remote video feed
- Automatic animation sequencing for multiple detected words

**How It Works:**
```
Speech Input → STT Engine → Keyword Extraction → Animation Lookup → Lottie Display
     ↓              ↓              ↓                   ↓                ↓
 Microphone    Turkish NLP    Word Match         Asset Load      Overlay Render
```

**Example Animation Triggers:**
- User says "Merhaba, nasılsın?" → [merhaba.json] then [nasilsin.json] animations play
- User says "Su istiyorum, teşekkürler" → [su.json] then [tesekkurler.json] play
- Animations include greetings, common phrases, questions, and essential vocabulary

### 🎤 **Speech-to-Text Conversion**
- Real-time Turkish speech recognition via platform APIs
- Automatic session restart mechanism (30-second continuous windows)
- Partial and final transcription results for responsive feedback
- Low-latency subtitle display (<500ms end-to-end)
- Noise-tolerant recognition for real-world environments

### 💬 **Dual Subtitle System**
- 🤟 **Purple subtitles** for sign language (AI detected gestures)
- 🎤 **Cyan subtitles** for speech (STT converted)
- Bidirectional subtitle streaming via WebSocket
- 3-second display duration with smooth fade effects
- Non-overlapping subtitle positioning

### 👤 **User Management**
- JWT-based authentication with 7-day token expiry
- Profile photo upload/delete with image optimization
- Real-time online status indicator
- Call history tracking with duration and status
- Secure password hashing with bcrypt (12 rounds)

### 🎨 **Modern UI/UX**
- Dark/Light theme support with system preference detection
- Smooth Lottie animations throughout the app
- Responsive design for various screen sizes
- Picture-in-picture video layout with draggable local preview
- Gradient backgrounds and glassmorphism effects
- Intuitive call controls with visual feedback

### ☁️ **Cloud Deployment Ready**
- **Render.com** deployment with automatic SSL
- Hybrid database mode (PostgreSQL or In-Memory)
- Zero-configuration deployment with Procfile
- Environment-based configuration
- Always-on server (no cold starts for paid plans)

---

## 🎬 Demo

<!-- BURAYA: Demo videosu veya GIF animasyonu ekle -->
<!-- Örnek kullanım senaryosu: -->
<!-- 1. Kullanıcı A "Merhaba" işareti yapıyor → Kullanıcı B ekranında "Merhaba" altyazısı görünüyor -->
<!-- 2. Kullanıcı B "Selam" diyor → Kullanıcı A ekranında "Selam" altyazısı görünüyor -->

---

## 🔄 How It Works

```
┌────────────────────┐                                    ┌────────────────────┐
│   DEAF USER (A)    │                                    │  HEARING USER (B)  │
│                    │                                    │                    │
│  🤟 Signs gesture  │                                    │  🎤 Says "Merhaba" │
│         ↓          │                                    │         ↓          │
│  ML Kit detects    │                                    │  STT converts      │
│         ↓          │                                    │         ↓          │
│  "Merhaba" text    │═══════ P2P ENCRYPTED ══════════════│  Keyword detected  │
│                    │        VIDEO STREAM                │         ↓          │
│  ┌──────────────┐  │                                    │  🎬 Lottie plays   │
│  │ Sees Lottie  │◄═╪════════════════════════════════════╪══ merhaba.json    │
│  │ animation    │  │        SUBTITLE STREAM             │                    │
│  └──────────────┘  │                                    │  ┌──────────────┐  │
│                    │                                    │  │ Sees purple  │  │
│                    ╪════════════════════════════════════╪═►│ "Merhaba"    │  │
│                    │                                    │  │ subtitle     │  │
└────────────────────┘                                    └──└──────────────┘──┘
                              ▲
                              │
                    ┌─────────┴─────────┐
                    │ SIGNALING SERVER  │
                    │ (Render.com)      │
                    │                   │
                    │ • SDP/ICE relay   │
                    │ • User registry   │
                    │ • Subtitle relay  │
                    │ • Auth/JWT        │
                    │                   │
                    │ Video/Audio does  │
                    │ NOT pass through  │
                    └───────────────────┘
```

### Complete Call Flow Sequence

```
1. AUTHENTICATION
   └─► User A & B login → Receive JWT tokens → Connect to signaling server

2. CALL INITIATION
   ├─► User A taps "Call User B"
   ├─► WebRTC creates SDP Offer (video/audio capabilities)
   ├─► Signaling server forwards offer to User B
   └─► User B sees incoming call dialog with caller info

3. CALL ACCEPTANCE
   ├─► User B accepts → WebRTC creates SDP Answer
   ├─► Signaling server forwards answer to User A
   └─► Both peers exchange ICE candidates for NAT traversal

4. P2P CONNECTION ESTABLISHED
   ├─► DTLS-SRTP handshake encrypts all media
   ├─► Direct peer-to-peer video/audio streaming begins
   └─► AI pipelines activate on both devices

5. BIDIRECTIONAL AI PROCESSING
   │
   ├─► DEAF USER SIDE:
   │   ├─► Every 200ms: Capture camera frame
   │   ├─► ML Kit Pose Detection extracts 33 landmarks
   │   ├─► Gesture classifier analyzes hand/body positions
   │   ├─► On match: Send "sign_subtitle" via WebSocket
   │   └─► Receive "speech_animation" → Play Lottie animation
   │
   └─► HEARING USER SIDE:
       ├─► Continuous speech recognition active
       ├─► STT engine processes microphone input
       ├─► Keyword matcher scans for animation-supported words
       ├─► Send animation trigger + text subtitle
       └─► Receive "sign_subtitle" → Display purple text

6. CALL TERMINATION
   ├─► Either user taps end call
   ├─► WebRTC connection closed
   ├─► AI pipelines stopped
   └─► Call record saved to database
```

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
| **flutter_webrtc** | 0.12.4 | P2P video/audio calling with SRTP encryption |
| **google_mlkit_pose_detection** | 0.12.0 | 33-point skeletal tracking for gesture detection |
| **speech_to_text** | 7.0.0 | Native speech-to-text with Turkish support |
| **lottie** | 3.1.0 | High-performance vector animations for sign language |
| **socket_io_client** | 2.0.3+1 | Real-time WebSocket signaling |
| **provider** | 6.1.1 | Efficient state management |
| **shared_preferences** | 2.2.2 | Local persistent storage for settings |

### Backend (Node.js)

| Technology | Version | Purpose |
|------------|---------|---------|
| **Express** | 4.18.2 | HTTP server & REST API |
| **Socket.IO** | 4.7.4 | Bidirectional WebSocket communication |
| **PostgreSQL** | 14+ | Relational database (optional, has in-memory fallback) |
| **jsonwebtoken** | 9.0.2 | Stateless JWT authentication |
| **bcrypt** | 6.0.0 | Secure password hashing (12 rounds) |
| **helmet** | 7.1.0 | Security headers (XSS, clickjacking protection) |
| **express-rate-limit** | 7.1.5 | DDoS and brute-force protection |
| **uuid** | 10.0.0 | Unique identifier generation |

### Infrastructure & Deployment

| Component | Technology | Details |
|-----------|------------|---------|
| **Hosting** | Render.com | Auto-scaling, SSL, always-on |
| **Database** | PostgreSQL / In-Memory | Hybrid mode for flexibility |
| **WebRTC** | DTLS-SRTP, ICE, SDP | Industry-standard P2P protocols |
| **STUN** | Google (`stun.l.google.com:19302`) | NAT discovery |
| **TURN** | OpenRelay (`openrelay.metered.ca`) | Relay fallback |
| **Target** | Android (min SDK 21) | 98% device coverage |

---

## 📁 Project Structure

```
signai/
├── signai_app/                      # Flutter Mobile Application
│   ├── lib/
│   │   ├── main.dart                # App entry point with providers
│   │   ├── screens/                 # 6 UI screens
│   │   │   ├── splash_screen.dart   # Animated splash with logo
│   │   │   ├── login_screen.dart    # Auth with validation
│   │   │   ├── home_screen.dart     # User list + call initiation
│   │   │   ├── call_screen.dart     # Video call with AI overlays
│   │   │   ├── profile_screen.dart  # User settings
│   │   │   └── privacy_security_screen.dart
│   │   ├── providers/               # State management
│   │   │   ├── auth_provider.dart   # JWT token + user state
│   │   │   ├── call_provider.dart   # WebRTC + call state
│   │   │   └── theme_provider.dart  # Dark/light mode
│   │   ├── services/                # Business logic layer
│   │   │   ├── webrtc_service.dart  # P2P connection management
│   │   │   ├── signaling_service.dart # Socket.IO communication
│   │   │   ├── sign_language_service.dart # ML Kit gesture detection
│   │   │   ├── speech_to_text_service.dart # Native STT wrapper
│   │   │   └── permission_service.dart # Runtime permissions
│   │   ├── widgets/                 # Reusable UI components
│   │   │   ├── call_controls.dart   # Mic/camera/end buttons
│   │   │   ├── call_timer.dart      # HH:MM:SS display
│   │   │   ├── incoming_call_dialog.dart # Accept/reject UI
│   │   │   ├── subtitle_overlay.dart # Dual subtitle display
│   │   │   └── sign_animation_overlay.dart # Lottie animation player
│   │   └── utils/
│   │       ├── constants.dart       # Server URL, timeouts
│   │       └── theme.dart           # Colors, typography
│   ├── assets/
│   │   ├── animations/              # Lottie JSON files
│   │   │   ├── merhaba.json         # "Hello" animation
│   │   │   ├── tesekkurler.json     # "Thank you" animation
│   │   │   ├── nasilsin.json        # "How are you?" animation
│   │   │   └── ... (more gestures)  # Extensive gesture library
│   │   ├── images/                  # App icons, backgrounds
│   │   ├── labels/
│   │   │   └── sign_labels.txt      # Gesture label definitions
│   │   └── models/                  # ML model files (if custom)
│   ├── android/                     # Android native configuration
│   ├── ios/                         # iOS native configuration
│   └── pubspec.yaml                 # Dependencies & assets
│
├── signaling_server/                # Node.js Signaling Server
│   ├── server.js                    # Express + Socket.IO main
│   ├── auth.js                      # JWT + bcrypt authentication
│   ├── db.js                        # Hybrid PostgreSQL/In-Memory
│   ├── validation.js                # Input sanitization
│   ├── package.json                 # Dependencies
│   ├── Procfile                     # Render.com deployment
│   ├── render.yaml                  # Render configuration
│   └── .env.example                 # Environment template
│
├── README.md                        # This documentation
└── LICENSE                          # MIT License
```

**Code Statistics:**
- Flutter App: ~4,500+ lines of Dart
- Backend: ~1,400+ lines of JavaScript
- Lottie Animations: Professional-grade JSON assets
- **Total:** ~6,000+ lines of production code

---

## 🚀 Deployment

### Production Server (Render.com)

SignAI's signaling server is deployed on **Render.com** for 24/7 availability:

- **Live URL:** `https://signai-5g3q.onrender.com`
- **Region:** Frankfurt (EU)
- **SSL:** Automatic (Let's Encrypt)
- **Database:** In-Memory mode (no PostgreSQL required)

#### Deploying Your Own Instance

1. **Fork the repository** on GitHub

2. **Create a Render account** at [render.com](https://render.com)

3. **New Web Service** → Connect your GitHub repo

4. **Configure settings:**
   ```
   Name: signai-server
   Root Directory: signaling_server
   Runtime: Node
   Build Command: npm install
   Start Command: node server.js
   ```

5. **Environment Variables:**
   ```
   JWT_SECRET=your-super-secret-key-minimum-32-chars
   NODE_ENV=production
   ```

6. **Deploy** → Your server will be live at `https://your-app.onrender.com`

### APK Build Optimization

SignAI uses `--split-per-abi` flag for optimized APK sizes:

| Architecture | Device Type | APK Size |
|--------------|-------------|----------|
| **arm64-v8a** | Modern phones (2018+) | 54 MB |
| **armeabi-v7a** | Older phones | 43 MB |
| **x86_64** | Emulators, rare devices | 58 MB |

```bash
# Build optimized APKs
flutter build apk --release --split-per-abi

# Output location
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## 📥 Installation

### Prerequisites

- Flutter SDK ≥ 3.2.0
- Node.js ≥ 18.0.0
- Android Studio + Android device/emulator
- (Optional) PostgreSQL ≥ 14 for persistent storage

### 1. Clone Repository

```bash
git clone https://github.com/codewithme13/SignAi.git
cd SignAi
```

### 2. Backend Setup

```bash
cd signaling_server

# Install dependencies
npm install

# Option A: In-Memory Mode (No database needed)
export JWT_SECRET="your-secret-key"
npm start

# Option B: PostgreSQL Mode (Persistent storage)
createdb signai_db
export DATABASE_URL="postgresql://user:pass@localhost:5432/signai_db"
export JWT_SECRET="your-secret-key"
npm start
```

Server will start at `http://localhost:3001`

### 3. Mobile App Setup

```bash
cd ../signai_app

# Install Flutter dependencies
flutter pub get

# Update server URL (for local development)
# Edit lib/utils/constants.dart:
# static const String signalingServerUrl = 'http://YOUR_IP:3001';

# For Android emulator, use ADB port forwarding:
adb reverse tcp:3001 tcp:3001

# Run on connected device
flutter run

# Or build release APK
flutter build apk --release --split-per-abi
```

---

## ⚙️ Configuration

### Server Configuration

Environment variables for `signaling_server`:

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `JWT_SECRET` | Secret key for JWT signing (min 32 chars) | ✅ Yes | - |
| `DATABASE_URL` | PostgreSQL connection string | ❌ No | In-Memory |
| `PORT` | Server port | ❌ No | `3001` |
| `NODE_ENV` | Environment mode | ❌ No | `development` |

**Hybrid Database Mode:**
- If `DATABASE_URL` is set → Uses PostgreSQL (persistent)
- If `DATABASE_URL` is NOT set → Uses In-Memory storage (resets on restart)

### App Configuration

Edit `signai_app/lib/utils/constants.dart`:

```dart
class AppConstants {
  // Production server (Render.com deployment)
  static const String signalingServerUrl = 'https://signai-5g3q.onrender.com';
  
  // Local development alternatives:
  // static const String signalingServerUrl = 'http://localhost:3001';
  // static const String signalingServerUrl = 'http://10.0.2.2:3001'; // Android emulator
  
  static const int connectionTimeout = 30;
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

- [ ] Expand gesture recognition vocabulary (add more sign language words)
- [ ] Add more Lottie animations for speech-to-sign conversion
- [ ] Support for additional sign languages (ASL, BSL, etc.)
- [ ] iOS platform support with native optimizations
- [ ] Group video calling (multi-party WebRTC)
- [ ] Custom ML model training for improved accuracy
- [ ] Offline gesture recognition mode
- [ ] Real-time translation between different sign languages
- [ ] Accessibility improvements (VoiceOver, TalkBack)
- [ ] UI/UX enhancements and new themes

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

- **Google ML Kit** for advanced pose detection and skeletal tracking
- **Lottie by Airbnb** for beautiful, performant vector animations
- **WebRTC** community for peer-to-peer communication standards
- **Flutter** team for the excellent cross-platform framework
- **Render.com** for seamless cloud deployment
- **Turkish Sign Language (TİD)** resources and experts
- **OpenRelay** for free TURN server services

---

<div align="center">

### ⭐ Star this repo if you find it helpful!

**SignAI** - True bidirectional communication between deaf and hearing individuals

Made with ❤️ for accessibility and inclusion

[Back to Top](#-signai)

</div>
