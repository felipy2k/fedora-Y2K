#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "\n${GREEN}▶ $*${NC}"; }
step()    { echo -e "  ${CYAN}→ $*${NC}"; }
warning() { echo -e "  ${YELLOW}⚠ $*${NC}"; }
fail()    { echo -e "${RED}✗ $*${NC}"; }
ok()      { echo -e "  ${GREEN}✓ $*${NC}"; }

try() {
  if ! "$@"; then
    warning "Failed, continuing: $*"
  fi
}

if [[ "$EUID" -eq 0 ]]; then
  fail "Do not run as root. Run as a regular user."
  exit 1
fi

FEDORA_VER="$(rpm -E %fedora)"

show_menu() {
  clear
  echo -e "${BOLD}${BLUE}"
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║          Fedora — Custom Post-Install Setup                   ║"
  echo "║          User: ${USER}                                        ║"
  echo "╠═══════════════════════════════════════════════════════════════╣"
  echo "║  [1] Run EVERYTHING (recommended)                            ║"
  echo "║  [2] Update system only                                      ║"
  echo "║  [3] Remove bloatware only                                   ║"
  echo "║  [4] Install RPM packages only                               ║"
  echo "║  [5] Install Flatpaks only                                   ║"
  echo "║  [6] Install NVIDIA driver + CUDA only                       ║"
  echo "║  [7] Install GNOME extensions only                           ║"
  echo "║  [8] Apply visual settings only                              ║"
  echo "║  [9] Final verification                                      ║"
  echo "║  [0] Exit                                                    ║"
  echo "║  [r] Exit and reboot the system                              ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  read -rp "  Choose an option: " CHOICE
}

# ─────────────────────────────────────────────
# REPOS
# ─────────────────────────────────────────────
add_repos() {
  info "[REPOS] Adding repositories"

  step "RPM Fusion (free + nonfree)"
  try sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm"

  step "Enabling RPM Fusion AppStream metadata for GNOME Software"
  try sudo dnf install -y rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted 2>/dev/null || true

  step "Enabling fedora-cisco-openh264 repo (required for Firefox/WebRTC)"
  try sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1

  step "Google Chrome"
  if [[ ! -f /etc/yum.repos.d/google-chrome.repo ]]; then
    sudo tee /etc/yum.repos.d/google-chrome.repo > /dev/null <<'EOF'
[google-chrome]
name=Google Chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
  fi

  try sudo dnf makecache
}

# ─────────────────────────────────────────────
# SYSTEM UPDATE
# ─────────────────────────────────────────────
update_system() {
  info "[SYSTEM] Updating system"
  # Keep only 2 old kernels to save disk space
  try sudo sed -i 's/^installonly_limit=.*/installonly_limit=2/' /etc/dnf/dnf.conf
  try sudo dnf upgrade --refresh -y
}

# ─────────────────────────────────────────────
# CODECS — Official Fedora 43+ method (RPM Fusion)
# Based on: docs.fedoraproject.org + RPM Fusion
# ─────────────────────────────────────────────
install_codecs() {
  info "[CODECS] Installing multimedia codecs (official method)"

  step "Swapping ffmpeg-free for full ffmpeg (with proprietary codecs)"
  try sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing

  step "Upgrading @multimedia group (resolves H.264, H.265, AAC, etc.)"
  try sudo dnf group upgrade -y multimedia \
    --setopt="install_weak_deps=False" \
    --exclude=PackageKit-gstreamer-plugin

  step "Upgrading @sound-and-video group"
  try sudo dnf group upgrade -y sound-and-video

  step "Explicit GStreamer packages (coverage guarantee)"
  try sudo dnf install -y --skip-unavailable \
    gstreamer1-libav \
    gstreamer1-plugins-base \
    gstreamer1-plugins-good \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-ugly \
    gstreamer1-plugin-openh264 \
    libavcodec-freeworld \
    lame \
    lame-libs \
    mozilla-openh264

  step "Hardware video acceleration (VA-API/VDPAU)"
  # Auto-detects GPU to apply the correct freeworld drivers
  if lspci | grep -i 'vga\|3d\|display' | grep -qi 'amd\|radeon\|ati'; then
    step "AMD GPU detected — installing mesa freeworld drivers"
    try sudo dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld
    try sudo dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
  fi

  if lspci | grep -i 'vga\|3d\|display' | grep -qi 'intel'; then
    step "Intel GPU detected — installing intel-media-driver"
    try sudo dnf install -y --skip-unavailable intel-media-driver libva-intel-driver
  fi
}

# ─────────────────────────────────────────────
# RPMs
# Install EVERYTHING before removing anything
# to avoid breaking dependencies
# ─────────────────────────────────────────────
install_rpms() {
  info "[RPM] Installing RPM packages"

  install_codecs

  try sudo dnf install -y --skip-unavailable \
    \
    `# Base tools` \
    dnf-plugins-core \
    git \
    wget \
    curl \
    flatpak \
    fastfetch \
    pipx \
    papirus-icon-theme \
    \
    `# Browsers` \
    google-chrome-stable \
    firefox \
    torbrowser-launcher \
    \
    `# Multimedia` \
    vlc \
    audacity \
    darktable \
    handbrake-gui \
    easyeffects \
    obs-studio \
    \
    `# Graphics / Editing / 3D` \
    gimp \
    inkscape \
    blender \
    \
    `# Gaming` \
    steam \
    \
    `# GNOME Apps` \
    gnome-tweaks \
    baobab \
    nautilus \
    deja-dup \
    gnome-boxes \
    gnome-calculator \
    gnome-calendar \
    snapshot \
    gnome-characters \
    gnome-abrt \
    gnome-connections \
    gnome-contacts \
    simple-scan \
    gnome-disk-utility \
    gnome-text-editor \
    gnome-font-viewer \
    gnome-color-manager \
    gnome-software \
    gnome-clocks \
    gnome-logs \
    evince \
    loupe \
    \
    `# Utilities` \
    timeshift \
    solaar
}

# ─────────────────────────────────────────────
# FREEOFFICE
# Replaces LibreOffice (removed afterwards)
# ─────────────────────────────────────────────
install_freeoffice() {
  info "[FREEOFFICE] Installing FreeOffice 2024"

  step "Downloading and running official installer"
  if curl -fsSL https://softmaker.net/down/install-softmaker-freeoffice-2024.sh | sudo bash; then
    ok "FreeOffice installed successfully."
  else
    warning "Failed to install FreeOffice. Try manually:"
    echo "  curl -fsSL https://softmaker.net/down/install-softmaker-freeoffice-2024.sh | sudo bash"
  fi
}

# ─────────────────────────────────────────────
# FLATPAKS
# ─────────────────────────────────────────────
install_flatpaks() {
  info "[FLATPAK] Installing apps from Flathub"

  try flatpak remote-add --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo

  FLATPAK_IDS=(
    # System utilities
    com.mattjakeman.ExtensionManager        # GNOME Extension Manager
    net.nokyan.Resources                    # Resource monitor
    com.github.tchx84.Flatseal              # Flatpak permissions manager
    io.github.peazip.PeaZip                 # Archive manager
    com.system76.Popsicle                   # USB image flasher
    com.github.ADBeveridge.Raider           # File Shredder
    org.localsend.localsend_app             # LocalSend (LAN file sharing)
    io.gitlab.adhami3310.Converter          # Switcheroo (image format converter)

    # Multimedia
    org.shotcut.Shotcut                     # Video editor
    org.gnome.gitlab.YaLTeR.VideoTrimmer    # Video trimmer
    hu.irl.cameractrls                      # Camera controls
    net.fasterland.converseen               # Batch image converter

    # Productivity / Creativity
    org.freecad.FreeCAD                     # 3D CAD
    org.upscayl.Upscayl                     # AI image upscaler
    io.github.nokse22.Exhibit               # 3D model viewer
    com.github.phase1geo.Minder             # Mind mapping
    com.motrix.Motrix                       # Download manager

    # Entertainment / Sound / Other
    net.dreamchess.dreamchess               # Chess
    com.rafaelmardojai.Blanket              # Ambient sounds
    de.haeckerfelix.Shortwave               # Internet radio
    org.gnome.Podcasts                      # Podcasts
    nl.hjdskes.gcolor3                      # Color picker
    com.vixalien.sticky                     # Sticky Notes
    com.jeffser.Alpaca                      # Alpaca (local LLM)
  )

  for app in "${FLATPAK_IDS[@]}"; do
    # Strip inline comments
    app="${app%%#*}"
    app="${app//[[:space:]]/}"
    [[ -z "$app" ]] && continue
    step "$app"
    try flatpak install -y flathub "$app"
  done
}

# ─────────────────────────────────────────────
# NVIDIA + CUDA
# Auto-detects GPU — installs only if found
# Filters by VGA/3D/Display to avoid false positives
# ─────────────────────────────────────────────
install_nvidia() {
  info "[NVIDIA] Detecting GPU"

  # Precise filter: only VGA/3D/Display class devices
  if ! lspci | grep -i 'vga\|3d\|display' | grep -qi nvidia; then
    warning "No NVIDIA GPU detected. Skipping driver installation."
    return
  fi

  GPU_INFO="$(lspci | grep -i 'vga\|3d\|display' | grep -i nvidia | head -1)"
  ok "NVIDIA GPU detected: $GPU_INFO"

  # Secure Boot warning
  if command -v mokutil &>/dev/null && mokutil --sb-state 2>/dev/null | grep -qi enabled; then
    warning "Secure Boot is ENABLED."
    warning "After installation you will need to manually sign the akmod module."
    warning "See: https://rpmfusion.org/Howto/Secure%20Boot"
    read -rp "  Continue anyway? [y/N]: " SB_CONFIRM
    [[ "${SB_CONFIRM,,}" != "y" ]] && { warning "NVIDIA installation cancelled."; return; }
  fi

  step "Installing NVIDIA driver from RPM Fusion (akmod)"
  # cuda-toolkit does NOT exist in RPM Fusion. xorg-x11-drv-nvidia-cuda already
  # enables CUDA/NVENC/NVDEC support for apps (Blender, OBS, etc.).
  # For the full CUDA Toolkit (nvcc, headers), see the prompt below.
  try sudo dnf install -y --skip-unavailable \
    akmod-nvidia \
    xorg-x11-drv-nvidia \
    xorg-x11-drv-nvidia-cuda \
    xorg-x11-drv-nvidia-cuda-libs \
    xorg-x11-drv-nvidia-power \
    nvidia-settings \
    nvidia-vaapi-driver \
    libva-utils \
    vdpauinfo

  step "Building akmod module (may take a few minutes...)"
  try sudo akmods --force

  step "Regenerating initramfs"
  try sudo dracut --force

  step "Enabling NVIDIA power management services"
  try sudo systemctl enable nvidia-hibernate nvidia-resume nvidia-suspend

  echo
  echo -e "${BOLD}── Full CUDA Toolkit? ──${NC}"
  echo "The installed driver already provides CUDA support for apps (Blender, OBS, etc.)."
  echo "The FULL CUDA Toolkit (nvcc, cuBLAS headers, samples) requires the official NVIDIA repo."
  read -rp "  Add the official NVIDIA CUDA repo now? [y/N]: " CUDA_CONFIRM
  if [[ "${CUDA_CONFIRM,,}" == "y" ]]; then
    step "Adding official NVIDIA CUDA repository for Fedora ${FEDORA_VER}"
    try sudo dnf config-manager addrepo \
      --from-repofile="https://developer.download.nvidia.com/compute/cuda/repos/fedora${FEDORA_VER}/$(uname -m)/cuda-fedora${FEDORA_VER}.repo"
    try sudo dnf clean all

    # Exclude packages that conflict with RPM Fusion
    try sudo dnf config-manager setopt \
      "cuda-fedora${FEDORA_VER}-$(uname -m).exclude=nvidia-driver,nvidia-modprobe,nvidia-persistenced,nvidia-settings,nvidia-libXNVCtrl,nvidia-xconfig"

    step "Installing cuda-toolkit (nvcc, libs, headers)"
    try sudo dnf install -y cuda-toolkit
    ok "CUDA Toolkit installed. Run 'nvcc --version' after rebooting."
  else
    ok "Driver-only CUDA support (no nvcc). Sufficient for most applications."
  fi

  ok "NVIDIA driver installed. Reboot to load the kernel module."
}

# ─────────────────────────────────────────────
# GNOME EXTENSIONS
# ─────────────────────────────────────────────
install_gnome_extensions() {
  info "[EXTENSIONS] Installing GNOME extensions"

  export PATH="$HOME/.local/bin:$PATH"

  if ! command -v gext &>/dev/null; then
    step "Installing gnome-extensions-cli via pipx"
    try pipx install gnome-extensions-cli
    export PATH="$HOME/.local/bin:$PATH"
  fi

  EXTENSIONS=(
    appindicatorsupport@rgcjonas.gmail.com    # AppIndicator (system tray support)
    caffeine@patapon.info                     # Caffeine (prevent suspend)
    dash-to-dock@micxgx.gmail.com             # Dash to Dock
    gsconnect@andyholmes.github.io            # GSConnect (KDE Connect for GNOME)
    tilingshell@ferrarodomenico.com           # Tiling Shell
  )

  if command -v gext &>/dev/null; then
    for ext in "${EXTENSIONS[@]}"; do
      ext="${ext%%#*}"
      ext="${ext//[[:space:]]/}"
      [[ -z "$ext" ]] && continue
      step "$ext"
      try gext install "$ext"
      try gext enable "$ext"
    done
    ok "Extensions installed. Some may show errors until the next GNOME Shell update."
  else
    warning "gext not available. Install manually via Extension Manager."
    echo "  Required extensions:"
    printf '    - %s\n' "${EXTENSIONS[@]}"
  fi
}

# ─────────────────────────────────────────────
# BLOATWARE REMOVAL
# Run AFTER installing everything to avoid
# breaking dependencies during installation
# ─────────────────────────────────────────────
remove_bloat() {
  info "[CLEANUP] Removing bloatware"
  warning "Run this step AFTER installing everything to avoid dependency issues."

  step "Removing LibreOffice (replaced by FreeOffice)"
  try sudo dnf remove -y 'libreoffice*'

  step "Removing default GNOME media players (replaced by VLC)"
  # Covers both: Fedora ≤42 (Totem) and Fedora ≥43 (Showtime/Decibels)
  try sudo dnf remove -y \
    showtime \
    decibels \
    totem \
    totem-video-thumbnailer \
    gnome-music \
    rhythmbox

  step "Removing duplicate terminal (keeping Ptyxis, default since Fedora 41)"
  try sudo dnf remove -y gnome-terminal

  step "Removing RPM Extensions app (replaced by Extension Manager Flatpak)"
  try sudo dnf remove -y gnome-extensions-app

  step "Removing unnecessary apps"
  try sudo dnf remove -y \
    cheese \
    gnome-tour \
    mediawriter \
    gnome-system-monitor \
    gnome-weather \
    gnome-maps \
    yelp \
    dconf-editor \
    htop \
    piper \
    'jack-audio-connection-kit*' \
    qjackctl

  step "Removing unnecessary Flatpaks"
  try flatpak uninstall -y \
    org.gnome.Showtime \
    org.gnome.Decibels \
    org.gnome.Totem \
    org.gnome.Music \
    org.freedesktop.Piper \
    org.gnome.Help \
    com.usebruno.Bruno 2>/dev/null || true

  step "Cleaning orphan dependencies"
  try sudo dnf autoremove -y

  ok "Cleanup complete."
}

# ─────────────────────────────────────────────
# VISUAL SETTINGS & DEFAULT APPS
# ─────────────────────────────────────────────
apply_settings() {
  info "[SETTINGS] Applying GNOME settings and default apps"

  # ── Appearance ──
  try gsettings set org.gnome.desktop.interface icon-theme         'Papirus'
  try gsettings set org.gnome.desktop.interface color-scheme       'prefer-dark'
  try gsettings set org.gnome.desktop.interface clock-show-date    true
  try gsettings set org.gnome.desktop.interface clock-show-seconds true

  # ── Title bar buttons: add Minimize and Maximize (right side) ──
  try gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'

  # ── Default browser: Google Chrome ──
  step "Setting Google Chrome as default web browser"
  try xdg-settings set default-web-browser google-chrome.desktop

  # ── Default media player: VLC ──
  # Uses three methods combined for reliability on modern GNOME:
  #   1. xdg-mime  — writes to ~/.config/mimeapps.list
  #   2. gio mime  — GNOME's own tool, overrides gnome-mimeapps.list entries
  #   3. Direct write to mimeapps.list — guarantees persistence across sessions
  step "Setting VLC as default audio and video player"

  MEDIA_TYPES=(
    video/mp4
    video/x-matroska
    video/webm
    video/avi
    video/quicktime
    video/x-msvideo
    video/mpeg
    video/x-flv
    video/3gpp
    video/ogg
    audio/mpeg
    audio/ogg
    audio/flac
    audio/x-wav
    audio/aac
    audio/mp4
    audio/x-m4a
    audio/opus
    audio/webm
  )

  for mime in "${MEDIA_TYPES[@]}"; do
    try xdg-mime default vlc.desktop "$mime"
    gio mime "$mime" vlc.desktop 2>/dev/null || true
  done

  # Direct write to mimeapps.list as final guarantee
  MIMEAPPS="$HOME/.config/mimeapps.list"
  mkdir -p "$HOME/.config"

  # Ensure [Default Applications] section exists
  if ! grep -q '^\[Default Applications\]' "$MIMEAPPS" 2>/dev/null; then
    echo '[Default Applications]' >> "$MIMEAPPS"
  fi

  # For each MIME type: remove any existing entry then add VLC
  for mime in "${MEDIA_TYPES[@]}"; do
    sed -i "/^${mime//\//\\/}=/d" "$MIMEAPPS" 2>/dev/null || true
    sed -i "/^\[Default Applications\]/a ${mime}=vlc.desktop" "$MIMEAPPS"
  done

  ok "VLC set as default for audio and video (xdg-mime + gio mime + mimeapps.list)."

  # ── Wallpaper ──
  step "Downloading and applying wallpaper"
  WALLPAPER_URL="https://images-assets.nasa.gov/image/art002e009287/art002e009287~large.jpg?w=1920&h=1280&fit=clip&crop=faces%2Cfocalpoint"
  WALLPAPER_PATH="$HOME/Pictures/nasa-wallpaper.jpg"
  mkdir -p "$HOME/Pictures"
  if curl -fsSL "$WALLPAPER_URL" -o "$WALLPAPER_PATH"; then
    try gsettings set org.gnome.desktop.background picture-uri      "file://$WALLPAPER_PATH"
    try gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_PATH"
    try gsettings set org.gnome.desktop.background picture-options  'zoom'
    ok "Wallpaper applied."
  else
    warning "Failed to download wallpaper. Check your connection."
  fi

  ok "Settings applied."
}

# ─────────────────────────────────────────────
# FINAL VERIFICATION
# ─────────────────────────────────────────────
verify_final() {
  info "[VERIFICATION] Checking final system state"

  echo
  echo -e "${BOLD}── Packages that should have been REMOVED ──${NC}"
  REMOVED_CHECK=$(rpm -qa | grep -E \
    "libreoffice|^showtime|^decibels|^totem|totem-video-thumbnailer|gnome-music|^rhythmbox|^cheese|gnome-tour|^mediawriter|gnome-system-monitor|gnome-weather|gnome-maps|^yelp|^dconf-editor|^htop|^piper|^gnome-terminal$|gnome-extensions-app" \
    2>/dev/null || true)
  if [[ -z "$REMOVED_CHECK" ]]; then
    ok "No unwanted packages found."
  else
    warning "Still present:"
    echo "$REMOVED_CHECK"
  fi

  echo
  echo -e "${BOLD}── RPM packages that should exist ──${NC}"
  rpm -qa | grep -E \
    "google-chrome-stable|firefox|^vlc|audacity|darktable|handbrake|inkscape|easyeffects|^gimp|^blender|^steam|obs-studio|gnome-software|papirus|softmaker|freeoffice|^solaar|timeshift|deja-dup" \
    2>/dev/null || warning "Some RPM packages may not be installed."

  echo
  echo -e "${BOLD}── Essential codecs ──${NC}"
  if rpm -q ffmpeg &>/dev/null && ! rpm -q ffmpeg-free &>/dev/null; then
    ok "Full ffmpeg installed (ffmpeg-free replaced)."
  else
    warning "ffmpeg-free still present — proprietary codecs may be missing."
  fi

  echo
  echo -e "${BOLD}── Default applications ──${NC}"
  BROWSER=$(xdg-settings get default-web-browser 2>/dev/null || echo "not set")
  echo "  Default browser : $BROWSER"
  VIDEO_DEFAULT=$(xdg-mime query default video/mp4 2>/dev/null || echo "not set")
  echo "  Default video   : $VIDEO_DEFAULT"
  AUDIO_DEFAULT=$(xdg-mime query default audio/mpeg 2>/dev/null || echo "not set")
  echo "  Default audio   : $AUDIO_DEFAULT"
  BUTTONS=$(gsettings get org.gnome.desktop.wm.preferences button-layout 2>/dev/null || echo "not set")
  echo "  Title bar btns  : $BUTTONS"
  [[ "$BROWSER" == *"google-chrome"* ]] && ok "Chrome is default browser." || warning "Chrome is NOT the default browser."
  [[ "$VIDEO_DEFAULT" == *"vlc"* ]]     && ok "VLC is default video player." || warning "VLC is NOT the default video player."
  [[ "$AUDIO_DEFAULT" == *"vlc"* ]]     && ok "VLC is default audio player." || warning "VLC is NOT the default audio player."
  [[ "$BUTTONS" == *"minimize,maximize"* ]] && ok "Minimize/Maximize buttons active." || warning "Minimize/Maximize buttons not set."

  echo
  echo -e "${BOLD}── Installed Flatpaks ──${NC}"
  flatpak list --app --columns=application 2>/dev/null | grep -E \
    "Alpaca|Resources|Flatseal|Blanket|Raider|FreeCAD|Upscayl|Shotcut|VideoTrimmer|cameractrls|converseen|dreamchess|nokse22.Exhibit|Minder|Motrix|localsend|PeaZip|Podcasts|Popsicle|Shortwave|sticky|Converter|ExtensionManager" \
    || warning "Some expected Flatpaks may not be installed."

  echo
  echo -e "${BOLD}── NVIDIA GPU ──${NC}"
  if lspci | grep -i 'vga\|3d\|display' | grep -qi nvidia; then
    if rpm -q akmod-nvidia &>/dev/null; then
      ok "NVIDIA driver installed."
      nvidia-smi 2>/dev/null | head -4 || warning "nvidia-smi not available (reboot to load the module)."
      if command -v nvcc &>/dev/null; then
        ok "Full CUDA Toolkit present: $(nvcc --version | grep release)"
      else
        echo "  ℹ CUDA Toolkit (nvcc) not installed — driver-only CUDA support active."
      fi
    else
      warning "NVIDIA GPU detected but driver NOT installed."
    fi
  else
    ok "No NVIDIA GPU (no driver needed)."
  fi

  echo
  echo -e "${BOLD}── GNOME Extensions ──${NC}"
  if command -v gnome-extensions &>/dev/null; then
    gnome-extensions list --enabled 2>/dev/null || true
  else
    warning "gnome-extensions not available."
  fi
}

# ─────────────────────────────────────────────
# RUN EVERYTHING
# Correct order: install everything → remove bloat
# ─────────────────────────────────────────────
run_all() {
  echo
  echo -e "${YELLOW}This will run all steps in the correct order.${NC}"
  echo -e "${CYAN}Order: repos → update → RPMs → FreeOffice → Flatpaks → NVIDIA → Extensions → Remove bloat → Settings${NC}"
  echo
  read -rp "Confirm? [y/N]: " CONFIRM
  [[ "${CONFIRM,,}" != "y" ]] && { warning "Cancelled."; return; }

  add_repos
  update_system
  install_rpms        # Installs everything (including codecs)
  install_freeoffice  # FreeOffice before removing LibreOffice
  install_flatpaks
  install_nvidia      # Auto-detects — skips if no NVIDIA GPU found
  install_gnome_extensions
  remove_bloat        # Removes LibreOffice and bloat AFTER installing everything
  apply_settings      # Visual settings + default apps
  verify_final

  echo
  ok "Setup complete!"
  echo -e "${YELLOW}⚠ Reboot the system to activate all drivers and settings.${NC}"
}

# ─────────────────────────────────────────────
# MAIN LOOP
# ─────────────────────────────────────────────
while true; do
  show_menu

  case "$CHOICE" in
    1) run_all ;;
    2) add_repos; update_system ;;
    3) remove_bloat ;;
    4) add_repos; install_rpms ;;
    5) install_flatpaks ;;
    6) add_repos; install_nvidia ;;
    7) install_gnome_extensions ;;
    8) apply_settings ;;
    9) verify_final ;;
    0) echo "Exiting."; exit 0 ;;
    r|R) echo "Rebooting..."; sudo reboot ;;
    *) warning "Invalid option." ;;
  esac

  echo
  read -rp "Press ENTER to return to the menu..." _
done
