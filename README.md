# 🎩 Fedora Post-Install Setup Script

An interactive post-installation script for **Fedora Workstation 41+**, optimized for **Fedora 44 with GNOME 50**.  
Automates repositories, codecs, drivers, RPM packages, Flatpaks, GNOME extensions, default apps, and visual settings — all through a modular menu.

---

## ✨ What the script does

### 📦 Repositories
- RPM Fusion Free + Nonfree (with AppStream metadata for GNOME Software)
- RPM Fusion Tainted (extra firmware and codecs)
- `fedora-cisco-openh264` (H.264 for Firefox and WebRTC)
- Google Chrome

### 🎬 Multimedia Codecs
- Swaps `ffmpeg-free` for full `ffmpeg` (H.264, H.265, AAC, MP3, etc.)
- `dnf group upgrade multimedia` + `sound-and-video` (official Fedora method)
- Full GStreamer stack: `libav`, `ugly`, `bad-freeworld`, `openh264`
- Hardware acceleration (VA-API/VDPAU) auto-detected by GPU:
  - **AMD** → `mesa-va-drivers-freeworld` + `mesa-vdpau-drivers-freeworld`
  - **Intel** → `intel-media-driver` + `libva-intel-driver`

### 🖥️ NVIDIA Driver + CUDA
- GPU auto-detection filtered to VGA/3D/Display class devices only
- Secure Boot warning with confirmation prompt before proceeding
- Installs via RPM Fusion: `akmod-nvidia`, `xorg-x11-drv-nvidia-cuda`, `nvidia-settings`, `nvidia-vaapi-driver`
- Builds the kernel module with `akmods --force` and regenerates initramfs via `dracut --force`
- Enables power management services (`nvidia-hibernate`, `nvidia-resume`, `nvidia-suspend`)
- Optional: adds the official NVIDIA CUDA repository for the full Toolkit (`nvcc`, cuBLAS, headers), with automatic conflict exclusion against RPM Fusion packages

### 📥 RPM Packages Installed

| Category | Apps |
|---|---|
| Browsers | Firefox, Google Chrome, Tor Browser |
| Multimedia | VLC, Audacity, Darktable, Handbrake, EasyEffects, OBS Studio |
| Graphics / 3D | GIMP, Inkscape, Blender |
| Gaming | Steam |
| GNOME Apps | Tweaks, Baobab, Déjà Dup, Boxes, Calculator, Calendar, Snapshot, Characters, Connections, Contacts, Simple Scan, Disk Utility, Text Editor, Font Viewer, Color Manager, Software, Clocks, Logs, Evince, Loupe |
| Utilities | Timeshift, Solaar, fastfetch, pipx |
| Office | FreeOffice 2024 (via official SoftMaker installer) |

### 📱 Flatpaks (Flathub)

| Category | Apps |
|---|---|
| System | Extension Manager, Resources, Flatseal, PeaZip, Popsicle, File Shredder (Raider), LocalSend, Switcheroo |
| Multimedia | Shotcut, Video Trimmer, Camera Ctrls, Converseen |
| Productivity | FreeCAD, Upscayl, Exhibit (3D Viewer), Minder, Motrix |
| Entertainment | DreamChess, Blanket, Shortwave, Podcasts, Gcolor3, Sticky Notes, Alpaca |

### 🧩 GNOME Extensions (via `gnome-extensions-cli`)
- AppIndicator Support
- Caffeine
- Dash to Dock
- GSConnect (KDE Connect for GNOME)
- Tiling Shell

### 🎯 Default Applications
- **Web browser** → Google Chrome (`xdg-settings`)
- **Video player** → VLC (set for all common video MIME types via `xdg-mime`)
- **Audio player** → VLC (set for all common audio MIME types via `xdg-mime`)

### 🧹 Bloatware Removed

| Type | What is removed |
|---|---|
| Office | LibreOffice (replaced by FreeOffice) |
| Video | Showtime, Totem, totem-video-thumbnailer |
| Audio | Decibels, GNOME Music, Rhythmbox |
| Terminal | GNOME Terminal (keeps **Ptyxis**, default since Fedora 41) |
| Extensions | gnome-extensions-app RPM (replaced by Extension Manager Flatpak) |
| Other | Cheese, GNOME Tour, Mediawriter, GNOME System Monitor, Weather, Maps, Yelp, dconf-editor, htop, Piper, JACK |
| Flatpaks | Showtime, Decibels, Totem, GNOME Music, Piper, GNOME Help, Bruno |

### 🎨 Visual Settings
- Icon theme: **Papirus**
- Color scheme: **Dark mode**
- Clock with date and seconds visible
- NASA wallpaper applied automatically

---

## 🚀 How to use

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/fedora-setup.git
cd fedora-setup

# Make it executable
chmod +x fedora-setup.sh

# Run as a regular user (NOT as root)
./fedora-setup.sh
```

> ⚠️ **Do not run as root.** The script uses `sudo` internally where needed.

---

## 🗂️ Menu

```
╔═══════════════════════════════════════════════════════════════╗
║          Fedora — Custom Post-Install Setup                   ║
╠═══════════════════════════════════════════════════════════════╣
║  [1] Run EVERYTHING (recommended)                            ║
║  [2] Update system only                                      ║
║  [3] Remove bloatware only                                   ║
║  [4] Install RPM packages only                               ║
║  [5] Install Flatpaks only                                   ║
║  [6] Install NVIDIA driver + CUDA only                       ║
║  [7] Install GNOME extensions only                           ║
║  [8] Apply visual settings only                              ║
║  [9] Final verification                                      ║
║  [0] Exit                                                    ║
║  [r] Exit and reboot the system                              ║
╚═══════════════════════════════════════════════════════════════╝
```

Each step can be run individually. Option **[1] Run EVERYTHING** ensures the correct order: install everything first, remove bloatware after — preventing dependency issues.

---

## ⚙️ Requirements

- Fedora Workstation **41 or later** (optimized for Fedora 44 + GNOME 50)
- Internet connection
- A user account with `sudo` access

---

## 📝 Important Notes

**NVIDIA + Secure Boot**  
If Secure Boot is enabled, the script warns and requires confirmation before proceeding. After installation, the `akmod` kernel module must be manually signed. See the guide: [RPM Fusion — Secure Boot](https://rpmfusion.org/Howto/Secure%20Boot)

**CUDA Toolkit**  
The RPM Fusion driver already includes CUDA runtime support for applications (Blender, OBS, etc.). The full CUDA Toolkit (`nvcc`, cuBLAS, headers) is optional and installed from the official NVIDIA repository upon interactive confirmation.

**FreeOffice**  
Installed via the official SoftMaker script *before* LibreOffice is removed, ensuring no gap in office suite availability.

**Non-blocking failures**  
The script uses a `try()` function — if any step fails (package already installed, unavailable, etc.), it logs a warning and continues. No single failure aborts the entire process.

---

## ✅ Final Verification

Option **[9]** runs a full system check and reports:
- Unwanted packages still present
- Expected RPM packages installed (including Blender and Steam)
- Codec status (full ffmpeg vs. ffmpeg-free)
- Default browser, video, and audio player
- Installed Flatpaks
- NVIDIA driver and CUDA status
- Active GNOME extensions

---

## 📄 License

MIT — use, modify, and distribute freely.

How to use:
git clone https://github.com/felipy2k/fedora-Y2K.git
cd fedora-Y2K
bash Fedora-Y2K.sh
