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

**RPM Fusion update conflicts**  
When Fedora releases a system update (e.g. `ffmpeg-free`, `mesa`) and RPM Fusion hasn't yet published the corresponding freeworld package, DNF/GNOME Software can throw confusing dependency errors. The script sets `best=False` in `/etc/dnf/dnf.conf` **only after all packages are installed** — this tells DNF to skip unresolvable packages rather than abort future updates, without affecting the initial installation.

**NVIDIA + Secure Boot**  
If Secure Boot is enabled, the script detects it and prompts for confirmation before proceeding. After installation, the `akmod` kernel module must be manually signed. See: [RPM Fusion — Secure Boot](https://rpmfusion.org/Howto/Secure%20Boot)

**CUDA Toolkit**  
The RPM Fusion driver already includes CUDA runtime support for applications (Blender, OBS, etc.). The full CUDA Toolkit (`nvcc`, cuBLAS, headers) is optional and installed from the official NVIDIA repository upon interactive confirmation, with automatic exclusion of packages that conflict with RPM Fusion.

**VLC as default player**  
GNOME's system-level `gnome-mimeapps.list` can override user-level defaults. The script uses three methods simultaneously — `xdg-mime`, `gio mime`, and direct writes to `~/.config/mimeapps.list` — to reliably set VLC as the default for all common audio and video formats.

**Chrome touchpad gestures**  
The script enables two-finger swipe back/forward in Chrome by writing `--ozone-platform=wayland` and `--enable-features=TouchpadOverscrollHistoryNavigation` to `~/.config/chrome-flags.conf` and to a user-level copy of the `.desktop` file. The operation is idempotent — safe to run multiple times.

**NordVPN**  
Installed via the official NordVPN installer (`downloads.nordcdn.com`), which handles the repository, GPG key, and package in one step. Both **CLI and GUI** are installed (`-p nordvpn-gui`). The `nordvpnd` daemon is enabled automatically and your user is added to the `nordvpn` group. After installation, run `nordvpn login` and use `newgrp nordvpn` for immediate use without logout.

**FreeOffice**  
Installed via the official SoftMaker script *before* LibreOffice is removed, ensuring no gap in office suite availability. Connectivity is checked first — if offline, the step is skipped with instructions to retry.

**Reliability & recovery**  
The script ships several safety features:
- **Logging** — every run writes a full timestamped log to `~/fedora-y2k-YYYYMMDD-HHMMSS.log`
- **Robust error handling** — failures in any single step are logged as warnings and never abort the script
- **Grouped installs** — RPM packages are installed in 7 independent groups (Base tools, Browsers, Multimedia, Graphics, Gaming, GNOME apps, Utilities), so a failure in one group is visible and isolated
- **Disk space check** — warns if `/` has less than 15 GB free before a full install
- **Package backup** — before removing bloatware, the full RPM list is saved to `~/fedora-y2k-packages-before-cleanup-*.txt`
- **Final summary** — reports total warnings encountered and the log path
- **Idempotent** — safe to re-run; already-applied changes (ffmpeg swap, mesa drivers, Chrome flags, dnf.conf) are skipped

**Non-blocking failures**  
The `try()` function wraps every command — if anything fails, it logs a warning and continues. No single failure aborts the process.

---

## ✨ What the script does

### 📦 Repositories
- RPM Fusion Free + Nonfree (with AppStream metadata for GNOME Software)
- RPM Fusion Tainted (extra firmware and codecs)
- `fedora-cisco-openh264` (H.264 for Firefox and WebRTC)
- Google Chrome
- Brave Browser

### 🎬 Multimedia Codecs
- Swaps `ffmpeg-free` for full `ffmpeg` (H.264, H.265, AAC, MP3, and more) — idempotent
- Individual GStreamer packages installed directly — compatible with **DNF5 (Fedora 43+)**:
  `base`, `good`, `bad-free`, `bad-freeworld`, `ugly`, `ugly-free`, `plugin-libav`, `openh264`
- `lame` + `lame-libs` (MP3 encoding), `mozilla-openh264` (H.264 for Firefox/WebRTC)
- Hardware acceleration (VA-API/VDPAU) auto-detected by GPU — idempotent swaps:
  - **AMD** → `mesa-va-drivers-freeworld` + `mesa-vdpau-drivers-freeworld`
  - **Intel** → `intel-media-driver` + `libva-intel-driver`
  - **NVIDIA** → handled by the dedicated driver section

### 🖥️ NVIDIA Driver + CUDA
- GPU auto-detection using PCI class codes (`0300`, `0302`, `0380`) — avoids false positives
- Secure Boot detection with warning and confirmation prompt
- Installs via RPM Fusion: `akmod-nvidia`, `xorg-x11-drv-nvidia-cuda`, `nvidia-settings`, `nvidia-vaapi-driver`
- Builds the kernel module with `akmods --force` and regenerates initramfs via `dracut --force`
- Enables power management services (`nvidia-hibernate`, `nvidia-resume`, `nvidia-suspend`)
- Optional: full CUDA Toolkit (`nvcc`, cuBLAS, headers) via official NVIDIA repo, with automatic conflict exclusion

### 📥 RPM Packages Installed

| Category | Apps |
|---|---|
| Browsers | Firefox, Google Chrome, **Brave**, Tor Browser |
| Multimedia | VLC, Audacity, Darktable, Handbrake, EasyEffects, OBS Studio |
| Graphics / 3D | GIMP, Inkscape, Blender |
| Gaming | Steam |
| GNOME Apps | Tweaks, Baobab, Déjà Dup, Boxes, Calculator, Calendar, Snapshot, Characters, Connections, Contacts, Simple Scan, Disk Utility, Text Editor, Font Viewer, Color Manager, Software, Clocks, Logs, Evince, Loupe |
| Utilities | Timeshift, Solaar, fastfetch, pipx, DreamChess, lm_sensors |
| VPN | **NordVPN** CLI + GUI (official installer, daemon enabled, user added to group) |
| Office | FreeOffice 2024 (via official SoftMaker installer) |

### 📱 Flatpaks (Flathub)

| Category | Apps |
|---|---|
| System | Extension Manager, Resources, Flatseal, PeaZip, Popsicle, File Shredder (Raider), LocalSend, Switcheroo, Podman Desktop |
| Multimedia | Shotcut, Video Trimmer, Camera Ctrls, Converseen |
| Productivity | FreeCAD, Upscayl, Exhibit (3D Viewer), Minder, Motrix |
| Entertainment | Blanket, Shortwave, Podcasts, Gcolor3, Sticky Notes, Alpaca |

### 🧩 GNOME Extensions (via `gnome-extensions-cli`)
- AppIndicator Support
- Caffeine
- Clipboard Indicator
- Dash to Dock
- GSConnect (KDE Connect for GNOME)
- Tiling Shell
- Vitals (CPU, RAM, temperatures, fan speed, network — uses `lm_sensors` for hardware data)

### 🎯 Default Applications & Settings
- **Web browser** → Google Chrome
- **Video player** → VLC (xdg-mime + gio mime + mimeapps.list, 10 video MIME types)
- **Audio player** → VLC (same 3-method approach, 9 audio MIME types)
- **Title bar buttons** → Minimize + Maximize + Close, right side
- **Dock shortcuts** → Chrome · Files · Text Editor · Ptyxis · Calculator · App Grid
- **Chrome touchpad** → Two-finger swipe back/forward via Wayland flags

### 🧹 Bloatware Removed

| Type | What is removed |
|---|---|
| Office | LibreOffice (replaced by FreeOffice) |
| Video | Showtime, Totem, totem-video-thumbnailer |
| Audio | Decibels, GNOME Music, Rhythmbox |
| Terminal | GNOME Terminal (keeps **Ptyxis**, default since Fedora 41) |
| Extensions | gnome-extensions-app RPM (replaced by Extension Manager Flatpak) |
| Other | Cheese, GNOME Tour, Mediawriter, Weather, Maps, Yelp, dconf-editor, htop, Piper, JACK |
| Flatpaks | Showtime, Decibels, Totem, GNOME Music, Piper, GNOME Help, Bruno |

### 🎨 Visual Settings
- Icon theme: **Papirus**
- Color scheme: **Dark mode**
- Clock with date and seconds visible
- Minimize and Maximize buttons enabled (right side of title bar)
- Dock shortcuts configured
- Chrome configured for Wayland with two-finger touchpad gestures
- NASA wallpaper applied automatically

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

Option **[1] Run EVERYTHING** ensures the correct execution order:

```
repos → update → RPMs (+ NordVPN) → FreeOffice → Flatpaks → NVIDIA → Extensions → Remove bloat → Settings → best=False
```
