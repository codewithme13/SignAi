<div align="center">

# 🤟 SignAI

### Yapay Zeka Destekli Çift Yönlü İşaret Dili Görüntülü Arama Platformu

*İşitme engelli ve işiten bireyler arasındaki iletişim engellerini gerçek zamanlı yapay zeka çevirisi ile ortadan kaldırıyoruz*

[![Flutter](https://img.shields.io/badge/Flutter-3.2.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-18.0+-339933?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org)
[![WebRTC](https://img.shields.io/badge/WebRTC-P2P-333333?style=for-the-badge&logo=webrtc&logoColor=white)](https://webrtc.org)
[![Render](https://img.shields.io/badge/Deploy-Render.com-46E3B7?style=for-the-badge&logo=render&logoColor=white)](https://render.com)
[![Lottie](https://img.shields.io/badge/Animasyonlar-Lottie-00DDB3?style=for-the-badge&logo=airbnb&logoColor=white)](https://lottiefiles.com)

[Özellikler](#-özellikler) • [Demo](#-demo) • [Mimari](#-sistem-mimarisi) • [Kurulum](#-kurulum) • [API](#-api-referansı)

---

**🌐 Canlı Sunucu:** `https://signai-5g3q.onrender.com`

**📱 APK Boyutları:** arm64-v8a (54MB) | armeabi-v7a (43MB) | x86_64 (58MB)

</div>

---

## 📖 İçindekiler

- [Genel Bakış](#-genel-bakış)
- [Özellikler](#-özellikler)
- [Demo](#-demo)
- [Nasıl Çalışır?](#-nasıl-çalışır)
- [Sistem Mimarisi](#-sistem-mimarisi)
- [Teknoloji Yığını](#-teknoloji-yığını)
- [Proje Yapısı](#-proje-yapısı)
- [Dağıtım (Deployment)](#-dağıtım-deployment)
- [Kurulum](#-kurulum)
- [Yapılandırma](#-yapılandırma)
- [Kullanım](#-kullanım)
- [API Referansı](#-api-referansı)
- [Güvenlik](#-güvenlik)
- [Katkıda Bulunma](#-katkıda-bulunma)
- [Lisans](#-lisans)
- [İletişim](#-iletişim)

---

## 🌟 Genel Bakış

**SignAI**, işitme engelli ve işiten bireyler arasında **gerçek çift yönlü iletişimi** mümkün kılan yenilikçi bir yapay zeka destekli görüntülü arama uygulamasıdır. Mevcut çözümlerden farklı olarak SignAI şunları sağlar:

- **İşaret Dili → Metin:** Gerçek zamanlı yapay zeka destekli jest algılama, işaret dilini okunabilir altyazılara dönüştürür
- **Konuşma → İşaret Dili Animasyonu:** Söylenen kelimeler profesyonel Lottie işaret dili animasyonlarına dönüştürülür

Bu, her iki tarafın da tercih ettiği dilde doğal bir şekilde kendini ifade edebildiği eksiksiz bir iletişim döngüsü oluşturur.

### Problem

Dünya genelinde 466 milyondan fazla insan işitme engelli veya işitme güçlüğü çekmektedir. Geleneksel görüntülü arama platformları gerçek zamanlı çeviri yeteneklerinden yoksundur ve işitme engelli bireyleri tercümanlara güvenmeye veya yalnızca metin tabanlı iletişime başvurmaya zorlamaktadır. Bu durum günlük hayatta, profesyonel ortamlarda ve acil durumlarda önemli iletişim engelleri oluşturmaktadır.

### Çözüm

SignAI **çift yapay zeka hattı** uygular:

1. **Görsel Yapay Zeka (İşaret → Metin):** Google ML Kit'in gelişmiş poz algılama özelliğini kullanarak Türk İşaret Dili (TİD) jestlerini gerçek zamanlı olarak tanır ve işiten kullanıcının görebileceği metin altyazılarına dönüştürür.

2. **Sesli Yapay Zeka + Animasyon (Konuşma → İşaret):** Konuşma tanıma teknolojisini kullanarak söylenen kelimeleri animasyonlu Lottie işaret dili jestlerine dönüştürür ve işitme engelli kullanıcıya akıcı, profesyonel animasyonlar olarak görüntüler.

---

## ✨ Özellikler

### 🎥 **P2P Şifreli Görüntülü Arama**
- WebRTC DTLS-SRTP ile uçtan uca şifrelenmiş video/ses
- Gerçek peer-to-peer bağlantı - video/ses ASLA sunucudan geçmez
- HD desteği ile uyarlanabilir video kalitesi (640×480 @ 24fps)
- Güvenlik duvarları arkasındaki NAT geçişi için STUN/TURN sunucu desteği
- Optimal bağlantı yolu için otomatik ICE aday toplama

### 🤖 **Yapay Zeka Destekli İşaret Dili Algılama (İşaret → Metin)**
- Türk İşaret Dili jestlerinin gerçek zamanlı tanınması
- 33 noktalı iskelet takibi ile Google ML Kit Poz Algılama
- Tutarlılık tamponu ile gelişmiş jest doğrulama (minimum 5/10 kare)
- Mükerrer algılamayı önlemek için akıllı bekleme mekanizması (2 saniye)
- Doğal iletişim akışı için cümle oluşturma modu
- Doğru jest eşleştirmesi için güven puanlaması

**Algılama Hattı:**
```
Kamera Karesi → ML Kit Poz → Landmark Analizi → Jest Sınıflandırma → Altyazı Oluşturma
      ↓              ↓              ↓                   ↓                    ↓
  200ms/kare    33 anahtar      Açı/Pozisyon      Desen Eşleştirme    WebSocket Gönder
                 nokta
```

**Tanınan Jestler:**
| Jest | Algılama Yöntemi |
|------|------------------|
| Merhaba | Sağ el baş üstünde kaldırılmış |
| Teşekkürler | El çeneden aşağı doğru hareket |
| Evet | Yumruk baş hizasında, aşağı hareket |
| Hayır | İşaret parmağı sağa-sola sallanma |
| Yardım | Her iki kol baş üstünde kaldırılmış |
| Yemek | Sağ el ağız hizasında |
| Su | C şeklinde el çene hizasında |
| Dur | Açık avuç göğüs hizasında |
| Hoşçakal | Yüz hizasında el sallama |
| Ben | İşaret parmağı göğüse işaret ediyor |
| Nasılsın | Eller göğüste, dışa doğru hareket |
| Seni Seviyorum | Klasik ASL "I Love You" işareti |

### 🎬 **Konuşmadan İşaret Diline Animasyon Sistemi (Konuşma → İşaret)**
- **Lottie destekli** profesyonel işaret dili animasyonları
- Konuşma akışında gerçek zamanlı anahtar kelime algılama
- İşitme engelli kullanıcılar için akıcı, erişilebilir animasyonlar
- Uzak video akışı üzerinde overlay görüntüleme
- Birden fazla algılanan kelime için otomatik animasyon sıralama

**Nasıl Çalışır:**
```
Konuşma Girişi → STT Motoru → Anahtar Kelime Çıkarma → Animasyon Arama → Lottie Görüntüleme
      ↓              ↓                ↓                     ↓                  ↓
   Mikrofon     Türkçe NLP      Kelime Eşleştirme      Asset Yükleme     Overlay Render
```

**Örnek Animasyon Tetikleyicileri:**
- Kullanıcı "Merhaba, nasılsın?" dediğinde → [merhaba.json] sonra [nasilsin.json] animasyonları oynar
- Kullanıcı "Su istiyorum, teşekkürler" dediğinde → [su.json] sonra [tesekkurler.json] oynar
- Animasyonlar selamlaşma, yaygın ifadeler, sorular ve temel kelime dağarcığını içerir

### 🎤 **Konuşmadan Metne Dönüştürme**
- Platform API'leri aracılığıyla gerçek zamanlı Türkçe konuşma tanıma
- Otomatik oturum yeniden başlatma mekanizması (30 saniyelik sürekli pencereler)
- Duyarlı geri bildirim için kısmi ve nihai transkripsiyon sonuçları
- Düşük gecikmeli altyazı görüntüleme (<500ms uçtan uca)
- Gerçek dünya ortamları için gürültüye dayanıklı tanıma

### 💬 **Çift Altyazı Sistemi**
- 🤟 **Mor altyazılar** işaret dili için (AI algılanan jestler)
- 🎤 **Cyan altyazılar** konuşma için (STT dönüştürülmüş)
- WebSocket üzerinden çift yönlü altyazı akışı
- Yumuşak solma efektleri ile 3 saniyelik görüntüleme süresi
- Çakışmayan altyazı konumlandırma

### 👤 **Kullanıcı Yönetimi**
- 7 günlük token süresi ile JWT tabanlı kimlik doğrulama
- Görüntü optimizasyonu ile profil fotoğrafı yükleme/silme
- Gerçek zamanlı çevrimiçi durum göstergesi
- Süre ve durum ile arama geçmişi takibi
- bcrypt ile güvenli şifre hashleme (12 tur)

### 🎨 **Modern UI/UX**
- Sistem tercihi algılama ile Koyu/Açık tema desteği
- Uygulama genelinde akıcı Lottie animasyonları
- Çeşitli ekran boyutları için duyarlı tasarım
- Sürüklenebilir yerel önizleme ile resim içinde resim video düzeni
- Gradyan arka planlar ve glassmorphism efektleri
- Görsel geri bildirim ile sezgisel arama kontrolleri

### ☁️ **Bulut Dağıtıma Hazır**
- Otomatik SSL ile **Render.com** dağıtımı
- Hibrit veritabanı modu (PostgreSQL veya Bellek İçi)
- Procfile ile sıfır yapılandırma dağıtımı
- Ortam tabanlı yapılandırma
- Her zaman açık sunucu (ücretli planlar için soğuk başlatma yok)

---

## 🔄 Nasıl Çalışır?

```
┌────────────────────┐                                    ┌────────────────────┐
│  İŞİTME ENGELLİ    │                                    │   İŞİTEN           │
│   KULLANICI (A)    │                                    │   KULLANICI (B)    │
│                    │                                    │                    │
│  🤟 Jest yapar     │                                    │  🎤 "Merhaba" der  │
│         ↓          │                                    │         ↓          │
│  ML Kit algılar    │                                    │  STT dönüştürür    │
│         ↓          │                                    │         ↓          │
│  "Merhaba" metni   │═══════ P2P ŞİFRELİ ════════════════│  Anahtar kelime    │
│                    │        VİDEO AKIŞI                 │  algılandı         │
│  ┌──────────────┐  │                                    │         ↓          │
│  │ Lottie       │◄═╪════════════════════════════════════╪══ 🎬 Lottie oynar │
│  │ animasyonu   │  │        ALTYAZI AKIŞI               │  merhaba.json     │
│  │ görür        │  │                                    │                    │
│  └──────────────┘  │                                    │  ┌──────────────┐  │
│                    │                                    │  │ Mor          │  │
│                    ╪════════════════════════════════════╪═►│ "Merhaba"    │  │
│                    │                                    │  │ altyazı görür│  │
└────────────────────┘                                    └──└──────────────┘──┘
                              ▲
                              │
                    ┌─────────┴─────────┐
                    │  SİNYALLEŞME      │
                    │  SUNUCUSU         │
                    │  (Render.com)     │
                    │                   │
                    │ • SDP/ICE iletimi │
                    │ • Kullanıcı kaydı │
                    │ • Altyazı iletimi │
                    │ • Kimlik doğrulama│
                    │                   │
                    │ Video/Ses sunucu- │
                    │ dan GEÇMEZ        │
                    └───────────────────┘
```

### Tam Arama Akış Sırası

```
1. KİMLİK DOĞRULAMA
   └─► Kullanıcı A & B giriş yapar → JWT token alır → Sinyalleşme sunucusuna bağlanır

2. ARAMA BAŞLATMA
   ├─► Kullanıcı A "Kullanıcı B'yi Ara" butonuna basar
   ├─► WebRTC SDP Teklifi oluşturur (video/ses yetenekleri)
   ├─► Sinyalleşme sunucusu teklifi Kullanıcı B'ye iletir
   └─► Kullanıcı B arayan bilgileriyle gelen arama diyaloğunu görür

3. ARAMA KABUL
   ├─► Kullanıcı B kabul eder → WebRTC SDP Yanıtı oluşturur
   ├─► Sinyalleşme sunucusu yanıtı Kullanıcı A'ya iletir
   └─► Her iki eş NAT geçişi için ICE adaylarını değiştirir

4. P2P BAĞLANTI KURULDU
   ├─► DTLS-SRTP el sıkışması tüm medyayı şifreler
   ├─► Doğrudan peer-to-peer video/ses akışı başlar
   └─► Her iki cihazda AI hatları aktifleşir

5. ÇİFT YÖNLÜ AI İŞLEME
   │
   ├─► İŞİTME ENGELLİ KULLANICI TARAFI:
   │   ├─► Her 200ms'de: Kamera karesi yakala
   │   ├─► ML Kit Poz Algılama 33 landmark çıkarır
   │   ├─► Jest sınıflandırıcı el/vücut pozisyonlarını analiz eder
   │   ├─► Eşleşme durumunda: WebSocket üzerinden "sign_subtitle" gönder
   │   └─► "speech_animation" al → Lottie animasyonu oynat
   │
   └─► İŞİTEN KULLANICI TARAFI:
       ├─► Sürekli konuşma tanıma aktif
       ├─► STT motoru mikrofon girişini işler
       ├─► Anahtar kelime eşleştirici animasyon destekli kelimeleri tarar
       ├─► Animasyon tetikleyici + metin altyazı gönder
       └─► "sign_subtitle" al → Mor metin görüntüle

6. ARAMA SONLANDIRMA
   ├─► Her iki kullanıcıdan biri aramayı sonlandır butonuna basar
   ├─► WebRTC bağlantısı kapatılır
   ├─► AI hatları durdurulur
   └─► Arama kaydı veritabanına kaydedilir
```

---

## 🏗 Sistem Mimarisi

### Sistem Genel Bakışı

```
┌─────────────────────────────────────────────────────┐
│                 SUNUM KATMANI                        │
│  Ekranlar (6)  │  Widget'lar (5) │  Tema/Sabitler   │
├─────────────────────────────────────────────────────┤
│                 DURUM YÖNETİMİ                       │
│  AuthProvider  │  CallProvider  │  ThemeProvider    │
├─────────────────────────────────────────────────────┤
│                 SERVİS KATMANI                       │
│  WebRTC │ Sinyalleşme │ İşaretDili │ STT │ İzinler │
├─────────────────────────────────────────────────────┤
│                 AĞ KATMANI                           │
│  Socket.IO (WS) │ HTTP/REST │ WebRTC (P2P)          │
├─────────────────────────────────────────────────────┤
│                 BACKEND                              │
│  Express │ Socket.IO │ PostgreSQL/Bellek │ JWT     │
└─────────────────────────────────────────────────────┘
```

### Veritabanı Şeması

```sql
-- Kullanıcılar Tablosu
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_online BOOLEAN DEFAULT false
);

-- Arama Geçmişi Tablosu
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

---

## 🛠 Teknoloji Yığını

### Mobil Uygulama (Flutter)

| Teknoloji | Sürüm | Kullanım Amacı |
|-----------|-------|----------------|
| **Flutter** | 3.2.0+ | Çapraz platform mobil framework |
| **flutter_webrtc** | 0.12.4 | SRTP şifrelemeli P2P video/ses arama |
| **google_mlkit_pose_detection** | 0.12.0 | Jest algılama için 33 noktalı iskelet takibi |
| **speech_to_text** | 7.0.0 | Türkçe destekli yerel konuşmadan metne |
| **lottie** | 3.1.0 | İşaret dili için yüksek performanslı vektör animasyonları |
| **socket_io_client** | 2.0.3+1 | Gerçek zamanlı WebSocket sinyalleşme |
| **provider** | 6.1.1 | Verimli durum yönetimi |
| **shared_preferences** | 2.2.2 | Ayarlar için yerel kalıcı depolama |

### Backend (Node.js)

| Teknoloji | Sürüm | Kullanım Amacı |
|-----------|-------|----------------|
| **Express** | 4.18.2 | HTTP sunucu & REST API |
| **Socket.IO** | 4.7.4 | Çift yönlü WebSocket iletişimi |
| **PostgreSQL** | 14+ | İlişkisel veritabanı (isteğe bağlı, bellek içi yedek var) |
| **jsonwebtoken** | 9.0.2 | Durumsuz JWT kimlik doğrulama |
| **bcrypt** | 6.0.0 | Güvenli şifre hashleme (12 tur) |
| **helmet** | 7.1.0 | Güvenlik başlıkları (XSS, clickjacking koruması) |
| **express-rate-limit** | 7.1.5 | DDoS ve kaba kuvvet koruması |
| **uuid** | 10.0.0 | Benzersiz tanımlayıcı oluşturma |

### Altyapı & Dağıtım

| Bileşen | Teknoloji | Detaylar |
|---------|-----------|----------|
| **Barındırma** | Render.com | Otomatik ölçekleme, SSL, her zaman açık |
| **Veritabanı** | PostgreSQL / Bellek İçi | Esneklik için hibrit mod |
| **WebRTC** | DTLS-SRTP, ICE, SDP | Endüstri standardı P2P protokolleri |
| **STUN** | Google (`stun.l.google.com:19302`) | NAT keşfi |
| **TURN** | OpenRelay (`openrelay.metered.ca`) | Relay yedek |
| **Hedef** | Android (min SDK 21) | %98 cihaz kapsama |

---

## 📁 Proje Yapısı

```
signai/
├── signai_app/                      # Flutter Mobil Uygulama
│   ├── lib/
│   │   ├── main.dart                # Provider'larla uygulama giriş noktası
│   │   ├── screens/                 # 6 UI ekranı
│   │   │   ├── splash_screen.dart   # Logo ile animasyonlu açılış
│   │   │   ├── login_screen.dart    # Doğrulamalı kimlik
│   │   │   ├── home_screen.dart     # Kullanıcı listesi + arama başlatma
│   │   │   ├── call_screen.dart     # AI overlay'lerle görüntülü arama
│   │   │   ├── profile_screen.dart  # Kullanıcı ayarları
│   │   │   └── privacy_security_screen.dart
│   │   ├── providers/               # Durum yönetimi
│   │   │   ├── auth_provider.dart   # JWT token + kullanıcı durumu
│   │   │   ├── call_provider.dart   # WebRTC + arama durumu
│   │   │   └── theme_provider.dart  # Koyu/açık mod
│   │   ├── services/                # İş mantığı katmanı
│   │   │   ├── webrtc_service.dart  # P2P bağlantı yönetimi
│   │   │   ├── signaling_service.dart # Socket.IO iletişimi
│   │   │   ├── sign_language_service.dart # ML Kit jest algılama
│   │   │   ├── speech_to_text_service.dart # Yerel STT sarmalayıcı
│   │   │   └── permission_service.dart # Çalışma zamanı izinleri
│   │   ├── widgets/                 # Yeniden kullanılabilir UI bileşenleri
│   │   │   ├── call_controls.dart   # Mikrofon/kamera/sonlandır butonları
│   │   │   ├── call_timer.dart      # SS:DD:SS görüntüleme
│   │   │   ├── incoming_call_dialog.dart # Kabul/reddet UI
│   │   │   ├── subtitle_overlay.dart # Çift altyazı görüntüleme
│   │   │   └── sign_animation_overlay.dart # Lottie animasyon oynatıcı
│   │   └── utils/
│   │       ├── constants.dart       # Sunucu URL, zaman aşımları
│   │       └── theme.dart           # Renkler, tipografi
│   ├── assets/
│   │   ├── animations/              # Lottie JSON dosyaları
│   │   │   ├── merhaba.json         # "Merhaba" animasyonu
│   │   │   ├── tesekkurler.json     # "Teşekkürler" animasyonu
│   │   │   ├── nasilsin.json        # "Nasılsın?" animasyonu
│   │   │   └── ... (daha fazla)     # Kapsamlı jest kütüphanesi
│   │   ├── images/                  # Uygulama ikonları, arka planlar
│   │   ├── labels/
│   │   │   └── sign_labels.txt      # Jest etiket tanımları
│   │   └── models/                  # ML model dosyaları (özel ise)
│   ├── android/                     # Android yerel yapılandırma
│   ├── ios/                         # iOS yerel yapılandırma
│   └── pubspec.yaml                 # Bağımlılıklar & asset'ler
│
├── signaling_server/                # Node.js Sinyalleşme Sunucusu
│   ├── server.js                    # Express + Socket.IO ana dosya
│   ├── auth.js                      # JWT + bcrypt kimlik doğrulama
│   ├── db.js                        # Hibrit PostgreSQL/Bellek İçi
│   ├── validation.js                # Girdi sanitizasyonu
│   ├── package.json                 # Bağımlılıklar
│   ├── Procfile                     # Render.com dağıtımı
│   ├── render.yaml                  # Render yapılandırması
│   └── .env.example                 # Ortam şablonu
│
├── README.md                        # Bu dokümantasyon
└── LICENSE                          # MIT Lisansı
```

**Kod İstatistikleri:**
- Flutter Uygulaması: ~4,500+ satır Dart
- Backend: ~1,400+ satır JavaScript
- Lottie Animasyonları: Profesyonel kalitede JSON asset'leri
- **Toplam:** ~6,000+ satır üretim kodu

---

## 🚀 Dağıtım (Deployment)

### Üretim Sunucusu (Render.com)

SignAI'nin sinyalleşme sunucusu 7/24 erişilebilirlik için **Render.com**'da dağıtılmıştır:

- **Canlı URL:** `https://signai-5g3q.onrender.com`
- **Bölge:** Frankfurt (AB)
- **SSL:** Otomatik (Let's Encrypt)
- **Veritabanı:** Bellek İçi mod (PostgreSQL gerekmez)

#### Kendi Örneğinizi Dağıtma

1. **Repository'yi fork'layın** GitHub'da

2. **Render hesabı oluşturun** [render.com](https://render.com) adresinde

3. **Yeni Web Servisi** → GitHub repo'nuzu bağlayın

4. **Ayarları yapılandırın:**
   ```
   Ad: signai-server
   Kök Dizin: signaling_server
   Çalışma Zamanı: Node
   Build Komutu: npm install
   Başlatma Komutu: node server.js
   ```

5. **Ortam Değişkenleri:**
   ```
   JWT_SECRET=sizin-süper-gizli-anahtarınız-minimum-32-karakter
   NODE_ENV=production
   ```

6. **Dağıt** → Sunucunuz `https://uygulamanız.onrender.com` adresinde canlı olacak

### APK Derleme Optimizasyonu

SignAI optimize APK boyutları için `--split-per-abi` bayrağını kullanır:

| Mimari | Cihaz Tipi | APK Boyutu |
|--------|------------|------------|
| **arm64-v8a** | Modern telefonlar (2018+) | 54 MB |
| **armeabi-v7a** | Eski telefonlar | 43 MB |
| **x86_64** | Emülatörler, nadir cihazlar | 58 MB |

```bash
# Optimize edilmiş APK'ları derle
flutter build apk --release --split-per-abi

# Çıktı konumu
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## 📥 Kurulum

### Ön Gereksinimler

- Flutter SDK ≥ 3.2.0
- Node.js ≥ 18.0.0
- Android Studio + Android cihaz/emülatör
- (İsteğe bağlı) Kalıcı depolama için PostgreSQL ≥ 14

### 1. Repository'yi Klonlayın

```bash
git clone https://github.com/codewithme13/SignAi.git
cd SignAi
```

### 2. Backend Kurulumu

```bash
cd signaling_server

# Bağımlılıkları yükleyin
npm install

# Seçenek A: Bellek İçi Mod (Veritabanı gerekmez)
export JWT_SECRET="sizin-gizli-anahtarınız"
npm start

# Seçenek B: PostgreSQL Modu (Kalıcı depolama)
createdb signai_db
export DATABASE_URL="postgresql://kullanıcı:şifre@localhost:5432/signai_db"
export JWT_SECRET="sizin-gizli-anahtarınız"
npm start
```

Sunucu `http://localhost:3001` adresinde başlayacak

### 3. Mobil Uygulama Kurulumu

```bash
cd ../signai_app

# Flutter bağımlılıklarını yükleyin
flutter pub get

# Sunucu URL'sini güncelleyin (yerel geliştirme için)
# lib/utils/constants.dart dosyasını düzenleyin:
# static const String signalingServerUrl = 'http://SİZİN_IP:3001';

# Android emülatör için ADB port yönlendirme kullanın:
adb reverse tcp:3001 tcp:3001

# Bağlı cihazda çalıştırın
flutter run

# Veya release APK derleyin
flutter build apk --release --split-per-abi
```

---

## ⚙️ Yapılandırma

### Sunucu Yapılandırması

`signaling_server` için ortam değişkenleri:

| Değişken | Açıklama | Gerekli | Varsayılan |
|----------|----------|---------|------------|
| `JWT_SECRET` | JWT imzalama için gizli anahtar (min 32 karakter) | ✅ Evet | - |
| `DATABASE_URL` | PostgreSQL bağlantı dizesi | ❌ Hayır | Bellek İçi |
| `PORT` | Sunucu portu | ❌ Hayır | `3001` |
| `NODE_ENV` | Ortam modu | ❌ Hayır | `development` |

**Hibrit Veritabanı Modu:**
- `DATABASE_URL` ayarlanmışsa → PostgreSQL kullanır (kalıcı)
- `DATABASE_URL` ayarlanmamışsa → Bellek İçi depolama kullanır (yeniden başlatmada sıfırlanır)

### Uygulama Yapılandırması

`signai_app/lib/utils/constants.dart` dosyasını düzenleyin:

```dart
class AppConstants {
  // Üretim sunucusu (Render.com dağıtımı)
  static const String signalingServerUrl = 'https://signai-5g3q.onrender.com';
  
  // Yerel geliştirme alternatifleri:
  // static const String signalingServerUrl = 'http://localhost:3001';
  // static const String signalingServerUrl = 'http://10.0.2.2:3001'; // Android emülatör
  
  static const int connectionTimeout = 30;
  static const int subtitleDisplayDuration = 3;
}
```

### Android İzinleri

`android/app/src/main/AndroidManifest.xml` dosyasında gerekli izinler:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

---

## 💡 Kullanım

### Son Kullanıcılar İçin

1. **Kayıt Ol/Giriş Yap**
   - Uygulamayı başlatın → Kullanıcı adı ve şifre girin
   - "Kayıt Ol" veya "Giriş Yap" butonuna basın

2. **Arama Başlat**
   - Ana ekranda hedef Kullanıcı ID'sini girin veya çevrimiçi kullanıcılardan seçin
   - "Görüntülü Arama Başlat" butonuna basın
   - İstenirse kamera/mikrofon izinlerini verin

3. **Arama Sırasında**
   - 🤟 İşaret dili jestleri yapın → AI algılar ve mor altyazılar gösterir
   - 🎤 Konuşun → Konuşmadan metne dönüştürür ve cyan altyazılar gösterir
   - 🎬 Konuşmanızda anahtar kelimeler varsa → Karşı tarafta Lottie animasyonları oynar
   - Alt kontrolleri kullanarak kamera/mikrofonu açıp kapatın
   - Aramayı sonlandırmak için kırmızı telefon ikonuna basın

4. **Profili Görüntüle**
   - Profil kartına basın → Fotoğraf yükleyin, tema değiştirin, ayarları görüntüleyin

### Geliştiriciler İçin

#### Android Emülatör ile Test

```bash
# Emülatörü başlatın
~/Library/Android/sdk/emulator/emulator -avd Medium_Phone_API_36 &

# Port yönlendirmeyi ayarlayın
adb reverse tcp:3001 tcp:3001

# Yükleyin ve çalıştırın
flutter run
```

#### İşaret Dili Algılamayı Test Etme

AI jestleri şu durumlarda tanır:
- Yüz karede net olarak görünür
- Eller bel seviyesinin üstünde kaldırılmış
- Jest en az 5 kare boyunca tutulmuş (tutarlılık tamponu)
- Aynı jest arasında 2 saniyelik bekleme

---

## 📡 API Referansı

### REST Endpoint'leri

#### Kimlik Doğrulama

**POST** `/api/auth/register`
```json
İstek:
{
  "username": "ahmet_yılmaz",
  "password": "güvenli123"
}

Yanıt (201):
{
  "success": true,
  "data": {
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "username": "ahmet_yılmaz",
    "token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

**POST** `/api/auth/login`
- Kayıt ile aynı istek/yanıt formatı

#### Kullanıcılar

**GET** `/api/users` (Kimlik doğrulama gerekli)
- Profil fotoğraflarıyla çevrimiçi kullanıcıların listesini döner

**GET** `/api/users/:userId` (Kimlik doğrulama gerekli)
- Belirli kullanıcı detaylarını alır

#### Profil

**POST** `/api/profile/photo` (Kimlik doğrulama gerekli)
- Profil fotoğrafı yükle (multipart/form-data, maks 2MB)
- İzin verilen formatlar: JPEG, PNG, GIF, WEBP

**DELETE** `/api/profile/photo` (Kimlik doğrulama gerekli)
- Profil fotoğrafını sil

#### Arama Geçmişi

**GET** `/api/calls/history` (Kimlik doğrulama gerekli)
- Kimliği doğrulanmış kullanıcı için son 50 arama kaydını döner

### WebSocket Olayları

#### İstemci → Sunucu

| Olay | Veri | Açıklama |
|------|------|----------|
| `register` | `{ userId }` | Kullanıcıyı çevrimiçi olarak kaydet |
| `call-user` | `{ targetUserId, offer, callerName }` | Arama başlat |
| `answer-call` | `{ targetUserId, answer }` | Aramayı kabul et |
| `reject-call` | `{ callerId }` | Aramayı reddet |
| `ice-candidate` | `{ targetUserId, candidate }` | ICE adayı paylaş |
| `end-call` | `{ targetUserId }` | Aramayı sonlandır |
| `subtitle` | `{ targetUserId, text, type }` | Altyazı gönder |

#### Sunucu → İstemci

| Olay | Veri | Açıklama |
|------|------|----------|
| `registered` | `{ userId, onlineUsers }` | Kayıt onaylandı |
| `incoming-call` | `{ callerId, callerName, callerPhoto, offer }` | Gelen arama bildirimi |
| `call-answered` | `{ answer }` | Arama kabul edildi |
| `call-rejected` | `{ reason }` | Arama reddedildi |
| `call-ended` | `{}` | Arama sonlandırıldı |
| `ice-candidate` | `{ candidate }` | Uzak ICE adayı |
| `subtitle` | `{ text, type }` | Uzak altyazı |
| `user-online` | `{ userId, username, photoUrl }` | Kullanıcı çevrimiçi oldu |
| `user-offline` | `{ userId }` | Kullanıcı çevrimdışı oldu |

---

## 🔒 Güvenlik

### İletişim Güvenliği

| Katman | Yöntem | Detaylar |
|--------|--------|----------|
| **Video/Ses** | DTLS-SRTP | WebRTC'nin yerleşik uçtan uca şifrelemesi |
| **Sinyalleşme** | WSS/HTTPS | WebSocket Güvenli (üretimde TLS) |
| **API** | JWT Bearer | Token tabanlı kimlik doğrulama |
| **Socket.IO** | JWT Auth | WebSocket bağlantı kimlik doğrulaması |
| **Şifreler** | bcrypt (12 tur) | Tek yönlü hashleme, kaba kuvvete dayanıklı |

### Sunucu Güvenliği

- **Hız Sınırlama:** 100 istek/dk (REST), 50 olay/dk (Socket)
- **Helmet:** XSS, clickjacking, MIME sniffing koruması
- **CORS:** Yapılandırılabilir kaynak kısıtlaması
- **Girdi Doğrulama:** Tüm girdiler sanitize edilir ve doğrulanır
- **Dosya Yükleme:** 2MB limit, MIME tipi doğrulama

### Gizlilik

- **P2P Bağlantı:** Video/ses verisi sunucudan GEÇMEZ
- **Token Süresi:** 7 gün (yapılandırılabilir)
- **Şifre Gereksinimleri:** Minimum 6 karakter
- **Veri Kaydetmeme:** Altyazı içeriği sunucuda depolanmaz

---

## 🤝 Katkıda Bulunma

Katkıları memnuniyetle karşılıyoruz! Nasıl yardımcı olabilirsiniz:

### Geliştirme Kurulumu

1. Repository'yi fork'layın
2. Özellik dalı oluşturun: `git checkout -b ozellik/harika-ozellik`
3. Değişikliklerinizi yapın
4. Kapsamlı test edin (birim testler, entegrasyon testleri)
5. Commit yapın: `git commit -m 'Harika özellik ekle'`
6. Push yapın: `git push origin ozellik/harika-ozellik`
7. Pull Request açın

### Kod Stili

- **Flutter:** [Effective Dart](https://dart.dev/guides/language/effective-dart) kılavuzlarını takip edin
- **Node.js:** Sağlanan yapılandırma ile ESLint kullanın
- **Commit'ler:** [Conventional Commits](https://www.conventionalcommits.org/) kullanın

### Katkı Alanları

- [ ] Jest tanıma kelime dağarcığını genişlet (daha fazla işaret dili kelimesi ekle)
- [ ] Konuşmadan işarete dönüşüm için daha fazla Lottie animasyonu ekle
- [ ] Ek işaret dilleri için destek (ASL, BSL, vb.)
- [ ] Yerel optimizasyonlarla iOS platform desteği
- [ ] Grup görüntülü arama (çok taraflı WebRTC)
- [ ] Geliştirilmiş doğruluk için özel ML model eğitimi
- [ ] Çevrimdışı jest tanıma modu
- [ ] Farklı işaret dilleri arasında gerçek zamanlı çeviri
- [ ] Erişilebilirlik iyileştirmeleri (VoiceOver, TalkBack)
- [ ] UI/UX geliştirmeleri ve yeni temalar

---

## 📄 Lisans

Bu proje MIT Lisansı altında lisanslanmıştır - detaylar için [LICENSE](LICENSE) dosyasına bakın.

---

## 📞 İletişim

**Proje Sorumlusu:** codewithme13

- GitHub: [@codewithme13](https://github.com/codewithme13)
- Proje Bağlantısı: [https://github.com/codewithme13/SignAi](https://github.com/codewithme13/SignAi)

---

## 🙏 Teşekkürler

- **Google ML Kit** gelişmiş poz algılama ve iskelet takibi yetenekleri için
- **Airbnb Lottie** güzel, performanslı vektör animasyonları için
- **WebRTC** topluluğu peer-to-peer iletişim standartları için
- **Flutter** ekibi mükemmel çapraz platform framework'ü için
- **Render.com** sorunsuz bulut dağıtımı için
- **Türk İşaret Dili (TİD)** kaynakları ve uzmanları
- **OpenRelay** ücretsiz TURN sunucu hizmetleri için

---

<div align="center">

### ⭐ Faydalı bulduysanız yıldız verin!

**SignAI** - İşitme engelli ve işiten bireyler arasında gerçek çift yönlü iletişim

Erişilebilirlik ve kapsayıcılık için ❤️ ile yapıldı

[Başa Dön](#-signai)

</div>
