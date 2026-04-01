<p align="center">
  <img src="assets/header_icon.svg" width="80" height="80" alt="Video Downloader Logo">
</p>

<h1 align="center">🎬 Video Downloader</h1>

<p align="center">
  <b>🇺🇸 English</b> | <a href="README_ko.md">🇰🇷 한국어</a>
</p>

<p align="center">
  <strong>A multi-purpose desktop app that securely backs up public videos with a single URL</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Windows">
  <img src="https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python 3.10+">
  <img src="https://img.shields.io/badge/UI-PySide6_(LGPL)-41CD52?style=for-the-badge&logo=qt&logoColor=white" alt="PySide6">
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="MIT License">
</p>

<p align="center">
  <a href="https://github.com/weallnoob/Video_Downloader/releases/tag/Installer">
    <img src="https://img.shields.io/badge/⬇_DOWNLOAD_INSTALLER-2563EB?style=for-the-badge&logoColor=white" alt="Download">
  </a>
  &nbsp;
  <a href="https://www.buymeacoffee.com/aminora">
    <img src="https://img.shields.io/badge/☕_Buy_Me_a_Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" alt="Buy Me a Coffee">
  </a>
</p>

<p align="center">
  <a href="https://github.com/weallnoob/Video_Downloader">
    <img src="assets/github_star.png" width="400" alt="Please Star the Repository">
  </a>
</p>

<h3 align="center">⭐ If you find this project useful, please consider giving it a star! ⭐</h3>

---

## ✨ Features

- 🖱️ **One-Click Download:** Simply paste the URL and hit the download button to back up instantly with zero complicated setups.
- 🛡️ **Strict Safelist Policy:** Automatically blocks Pay-Per-View/OTT and DRM contents. Supports over 60+ legal public platforms.
- 🍪 **Absolute Privacy:** Never collects your browser cookies or personal login sessions.
- ⚡ **Ultra-Fast Parallel Downloading:** Integrates `aria2c` for 16-way concurrent chunk downloading, multiplying your original speed.
- 🎛️ **Granular Quality Control:** Choose exactly what you want—from 4K video resolution down to custom audio bitrates and forced formats (MP3, M4A, etc).
- 📋 **Integrated History Management:** Massive local download records accompanied by thumbnails and 1-click quick retries.
- 🎨 **Modern Desktop UI:** Clean, responsive, and rounded-corner design built on top of PySide6.

---

## 🚀 Getting Started

![Simple UI](image.png)

### For End-Users

1. Head over to the [**Releases**](https://github.com/weallnoob/Video_Downloader/releases/tag/Installer) page and download `VideoDownloaderInstaller.exe`.
2. Run the installer. (During installation, it will automatically download necessary binaries like `yt-dlp`, `aria2c`, and `ffmpeg` from their official sources).
3. Find **Video Downloader** on your Desktop or Start Menu and run it!

> **💡 Internet connection is required** — Essential binaries are dynamically downloaded during the installation process to save bundle space.

### For Developers

```powershell
# Install dependencies
python -m pip install -r requirements.txt

# Run directly
python app.py
```

---

## 🔧 Building from Source

To compile the executable, [**Inno Setup 6**](https://jrsoftware.org/isdl.php) is required.

```powershell
# Full build pipeline (PyInstaller → Inno Setup Installer)
.\build.ps1

# Options
.\build.ps1 -OfflineMode              # Offline mode (skips auto-downloading components)
.\build.ps1 -SkipInstaller            # Only build the application dist folder
.\build.ps1 -SkipInstall -SkipDownload # Skip updating packages/binaries
```

<details>
<summary>📦 <b>Detailed Build Pipeline</b></summary>

| Step | Description |
|------|-------------|
| 1. Install | Install requirements via `requirements-build.txt` |
| 2. PyInstaller | Bundle the codebase via `VideoDownloader.spec` into `dist/VideoDownloader/` |
| 3. Optimize | Exclude heavy modules like `yt_dlp`, `cryptography`, and `opengl32sw.dll` to shrink size |
| 4. Inno Setup | Compile the setup wizard into a single executable → `dist/VideoDownloaderInstaller.exe` |

- The wizard works in **Online Mode** by default—fetching `yt-dlp.exe`, `aria2c.exe`, and `ffmpeg.exe` only during the user's installation.
- This results in an incredibly lightweight, distributable artifact over GitHub Releases.

</details>

---

## 🌐 Supported Platforms

<details>
<summary>✅ <b>Allowed Platforms (60+)</b> — Click to Expand</summary>

| Category | Platforms |
|----------|-----------|
| **Global Video** | YouTube, Vimeo, Dailymotion, Rumble, Odysee, BitChute, PeerTube, DTube |
| **Social Media** | Facebook Watch, Instagram, X/Twitter, TikTok, Snapchat, Triller, LinkedIn |
| **Streaming** | Twitch, Kick, Trovo, AfreecaTV, Chzzk |
| **Korea** | Naver TV, KakaoTV, AfreecaTV, Chzzk |
| **China** | Bilibili, Youku, iQIYI, Tencent Video, Douyin, AcFun, Mango TV |
| **Japan / Russia** | Niconico, NHK World, VK Video, Rutube |
| **Public Broadcaster**| BBC iPlayer, ITVX, All 4, My5, ARD, ZDF, France.tv |
| **News / Edu** | TED, Coursera, Udemy, Al Jazeera, Bloomberg, CNN |
| **Free VoD** | Tubi, Pluto TV, Crackle, FilmRise, MagellanTV |

</details>

<details>
<summary>🚫 <b>Blocked Platforms (Premium OTT)</b></summary>

Netflix, Hulu, Amazon Prime Video, Disney+, Apple TV+, HBO Max, Paramount+,
Peacock, Crunchyroll, YouTube TV, ESPN+, Discovery+, FuboTV, Sling TV, etc.

</details>

---

## 🏗️ Technology Stack

| Component | Tech | Role |
|-----------|------|------|
| **GUI** | PySide6 (Qt 6, LGPL) | Cross-platform desktop interface |
| **Downloader** | yt-dlp | Core stream extraction & downloading engine |
| **Accelerator** | aria2c | Hardware-accelerated 16-way concurrent chunks |
| **Post-Processor** | ffmpeg | Video/Audio merging and format conversion |
| **Build Agent** | PyInstaller + Inno Setup | Creating standalone distribution |

---

## ⚖️ Legal Notice

<details>
<summary><b>Read Full Legal Disclaimers</b></summary>

- Upon launch, users are presented with a **Legal Consent Notice**, which is strictly required to proceed.
- This tool is strictly intended for **legal archiving** of publicly available contents.
- Downloading copyrighted material without the explicitly granted permission from the rightful owner is **prohibited**.
- The redistribution, sale, commercial usage, and uploading of the downloaded files are **strictly forbidden**.
- The user holds **sole legal and civil responsibility** for any misuse or violation of these prohibited actions.
- **DRM-protected contents** are inherently not supported and actively blocked.
- We **do not** automatically extract or scrape your browser login sessions or cookies.
- Users must abide by their local jurisdiction's laws and the respective platform's Terms of Service.
- This application **does not** feature any DRM circumvention mechanism.

</details>

## 📬 DMCA / Incident Contact

For issues or inquiries, please contact us via **GitHub Issues**.

---

## ☕ Support

If you found this tool helpful, consider buying us a coffee!

<a href="https://www.buymeacoffee.com/aminora">
  <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="217">
</a>

---

<p align="center">
  Made with ❤️ for the open-source community
</p>
