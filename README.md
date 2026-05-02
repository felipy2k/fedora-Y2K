# 🎩 Fedora Post-Install Setup Script

An interactive post-installation script for **Fedora Workstation 41+**, optimized for **Fedora 44 with GNOME 50**.  
Automates repositories, codecs, drivers, RPM packages, Flatpaks, GNOME extensions, default apps, dock layout, and visual settings — all through a modular interactive menu.

---

## ⚙️ Requirements

- Fedora Workstation **41 or later** (optimized for Fedora 44 + GNOME 50)
- Internet connection
- A user account with `sudo` access

---

## 📝 Important Notes

**NVIDIA + Secure Boot**  
If Secure Boot is enabled, the script detects it and prompts for confirmation before proceeding. After installation, the `akmod` kernel module must be manually signed. See: [RPM Fusion — Secure Boot](https://rpmfusion.org/Howto/Secure%20Boot)

**CUDA Toolkit**  
The RPM Fusion driver already includes CUDA runtime support for applications (Blender, OBS, etc.). The full CUDA Toolkit (`nvcc`, cuBLAS, headers) is optional and installed from the official NVIDIA repository upon interactive confirmation, with automatic exclusion of packages that conflict with RPM Fusion.

**VLC as default player**  
GNOME's system-level `gnome-mimeapps.list` can override user-level defaults. The script uses three methods simultaneously — `xdg-mime`, `gio mime`, and direct writes to `~/.config/mimeapps.list` — to reliably set VLC as the default for all common audio and video formats.

**Chrome touchpad gestures**  
The script enables two-finger swipe back/forward in Chrome by writing `--ozone-platform=wayland` and `--enable-features=TouchpadOverscrollHistoryNavigation` to `~/.config/chrome-flags.conf` and to a user-level copy of the `.desktop` file. The operation is idempotent — safe to run multiple times. If Chrome isn't installed yet when option `[8]` is run in isolation, the script warns and prompts you to re-run after installation.

**FreeOffice**  
Installed via the official SoftMaker script *before* LibreOffice is removed, ensuring no gap in office suite availability.

**Non-blocking failures**  
The script uses a `try()` function — if any step fails (package already installed, unavailable, network error, etc.), it logs a warning and continues. No single failure aborts the entire process.

---

## ✨ What the script does

### 📦 Repositories
- RPM Fusion Free + Nonfree (with AppStream metadata for GNOME Software)
- RPM Fusion Tainted (extra firmware and codecs)
- `fedora-cisco-openh264` (H.264 for Firefox and WebRTC)
- Google Chrome

### 🎬 Multimedia Codecs
- Swaps `ffmpeg-free` for full `ffmpeg` (H.264, H.265, AAC, MP3, and more)
- `dnf group upgrade multimedia` + `sound-and-video` (official Fedora/RPM Fusion method)
- Full GStreamer stack: `libav`, `ugly`, `bad-freeworld`, `openh264`
- Hardware acceleration (VA-API/VDPAU) auto-detected by GPU:
  - **AMD** → `mesa-va-drivers-freeworld` + `mesa-vdpau-drivers-freeworld`
  - **Intel** → `intel-media-driver` + `libva-intel-driver`
  - **NVIDIA** → handled by the dedicated driver section

### 🖥️ NVIDIA Driver + CUDA
- GPU auto-detection filtered to VGA/3D/Display class devices only (avoids false positives)
- Secure Boot detection with warning and confirmation prompt before proceeding
- Installs via RPM Fusion: `akmod-nvidia`, `xorg-x11-drv-nvidia-cuda`, `nvidia-settings`, `nvidia-vaapi-driver`
- Builds the kernel module with `akmods --force` and regenerates initramfs via `dracut --force`
- Enables power management services (`nvidia-hibernate`, `nvidia-resume`, `nvidia-suspend`)
- Optional: adds the official NVIDIA CUDA repository for the full Toolkit (`nvcc`, cuBLAS, headers), with automatic conflict exclusion against RPM Fusion packages

### 📥 RPM Packages Installed

| Category | Apps |
|---|---|
| Browsers | Firefox, Google Chrome, **Brave**, Tor Browser |
| Multimedia | VLC, Audacity, Darktable, Handbrake, EasyEffects, OBS Studio |
| Graphics / 3D | GIMP, Inkscape, Blender |
| Gaming | Steam |
| GNOME Apps | Tweaks, Baobab, Déjà Dup, Boxes, Calculator, Calendar, Snapshot, Characters, Connections, Contacts, Simple Scan, Disk Utility, Text Editor, Font Viewer, Color Manager, Software, Clocks, Logs, Evince, Loupe |
| Utilities | Timeshift, Solaar, fastfetch, pipx, DreamChess |
| VPN | **NordVPN** (official repo, daemon enabled, user added to `nordvpn` group) |
| Office | FreeOffice 2024 (via official SoftMaker installer) |

### 📱 Flatpaks (Flathub)

| Category | Apps |
|---|---|
| System | Extension Manager, Resources, Flatseal, PeaZip, Popsicle, File Shredder (Raider), LocalSend, Switcheroo, **Podman Desktop** |
| Multimedia | Shotcut, Video Trimmer, Camera Ctrls, Converseen |
| Productivity | FreeCAD, Upscayl, Exhibit (3D Viewer), Minder, Motrix |
| Entertainment | Blanket, Shortwave, Podcasts, Gcolor3, Sticky Notes, Alpaca |

### 🧩 GNOME Extensions (via `gnome-extensions-cli`)
- AppIndicator Support
- Caffeine
- Dash to Dock
- GSConnect (KDE Connect for GNOME)
- Tiling Shell

### 🎯 Default Applications & Settings

- **Web browser** → Google Chrome (`xdg-settings`)
- **Video player** → VLC — applied via `xdg-mime`, `gio mime`, and direct `mimeapps.list` write (3 methods), covering 10 video MIME types
- **Audio player** → VLC — same 3-method approach, covering 9 audio MIME types
- **Title bar buttons** → Minimize + Maximize + Close, positioned on the right (`gsettings`)
- **Dock shortcuts** → Chrome · Files · Text Editor · Terminal (Ptyxis) · Calculator · App Grid
- **Chrome touchpad gestures** → Two-finger swipe back/forward enabled via `--ozone-platform=wayland` and `--enable-features=TouchpadOverscrollHistoryNavigation`, written to `chrome-flags.conf` and the user-level `.desktop` file

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
- Minimize and Maximize buttons enabled (right side of title bar)
- Dock shortcuts configured (Chrome, Files, Text Editor, Ptyxis, Calculator)
- Chrome configured for Wayland with two-finger touchpad back/forward gestures
- NASA wallpaper applied automatically (https://images-assets.nasa.gov/image/art002e009287/art002e009287~large.jpg?w=1920&h=1280&fit=clip&crop=faces%2Cfocalpoint)

---

## 🚀 How to use

```bash
git clone https://github.com/felipy2k/fedora-Y2K.git
cd fedora-Y2K
bash Fedora-Y2K.sh
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

Each step can be run individually. Option **[1] Run EVERYTHING** ensures the correct execution order:

```
repos → update → RPMs → FreeOffice → Flatpaks → NVIDIA → Extensions → Remove bloat → Settings
```

Installing everything before removing bloatware prevents dependency issues (e.g. FreeOffice is installed before LibreOffice is removed).
