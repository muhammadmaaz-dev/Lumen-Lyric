# 🎵 LumenLyric — Open Source Music Player & Downloader

**LumenLyric** is a full-featured **Flutter-based music application** that combines local playback, royalty-free streaming, and YouTube audio downloading into a single, clean experience.

Built with a strong focus on **performance**, **offline usability**, and **open-source freedom**, LumenLyric is licensed under **GPL-3.0**, ensuring transparency and long-term community ownership.

---

## ✨ Features

### 📥 Music Downloader
- Convert **YouTube links** into high-quality MP3 audio
- Background downloads with progress tracking
- Automatic metadata tagging

### 🎧 Local Music Player
- Scan and play audio directly from device storage
- Fast indexing using `on_audio_query`
- Smooth playback powered by `just_audio`

### 📂 Library Management
- Liked songs
- Downloaded tracks
- Custom playlists
- Persistent local storage

### 🌗 Theming
- Fully supported **Light & Dark modes**
- Consistent black-and-white UI philosophy

---

## 📱 Screenshots

<div align="center" style="white-space:nowrap; overflow-x:auto;">
<img src="https://github.com/user-attachments/assets/82576c34-9f23-41b0-8e71-ca1f713a8d52" width="180"/>
<img src="https://github.com/user-attachments/assets/33b8ee96-4c10-4716-8b97-bb99996d8681" width="180"/>
<img src="https://github.com/user-attachments/assets/90530acc-1a0d-4827-9d64-06ad2e5edc93" width="180"/>
<img src="https://github.com/user-attachments/assets/a3fdef71-e36f-4173-9d87-732677f769a0" width="180"/>
<img src="https://github.com/user-attachments/assets/b8dfa15f-3cb1-45c2-962f-d1e5fd0c90a0" width="180"/>
</div>


---

## 🛠️ Tech Stack

### Core
- **Framework:** Flutter (Dart)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Code Generation:** `freezed`, `riverpod_annotation`

### Audio & Media
- `just_audio`
- `on_audio_query`
- `flutter_audio_tagger`
- `audio_video_progress_bar`
- `miniplayer`

### UI / UX
- `flutter_screenutil`
- `lottie`
- `flutter_animate`
- `marquee`
- `interactive_slider`
- `cupertino_icons`

### Storage & Permissions
- `shared_preferences`
- `permission_handler`

> The codebase is fully functional but open to architectural refinement.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Android Studio or VS Code
- Android device or emulator

### Installation

```bash
git clone https://github.com/muhammadmaaz-dev/Lumen-Lyric.git
cd musicapp
flutter pub get
flutter run
