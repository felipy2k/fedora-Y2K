#!/usr/bin/env bash

set -euo pipefail

info() { echo -e "\n▶ $*"; }
step() { echo -e "  → $*"; }
warn() { echo -e "  ⚠ $*"; }
ok()   { echo -e "  ✓ $*"; }

try() {
  "$@" || warn "Falhou: $*"
}

FEDORA_VER="$(rpm -E %fedora)"

update_system() {
  info "Atualizando sistema"
  try sudo dnf upgrade --refresh -y
}

add_repos() {
  info "Repos"

  try sudo dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm

  if [[ ! -f /etc/yum.repos.d/google-chrome.repo ]]; then
    sudo tee /etc/yum.repos.d/google-chrome.repo > /dev/null <<EOF
[google-chrome]
name=Google Chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
  fi

  if [[ ! -f /etc/yum.repos.d/brave-browser.repo ]]; then
    try sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
    try sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
  fi

  try sudo dnf makecache
}

install_codecs() {
  info "Codecs"

  try sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing

  try sudo dnf install -y --skip-unavailable \
    ffmpeg \
    ffmpeg-libs \
    libavcodec-freeworld \
    vlc \
    gstreamer1-libav \
    gstreamer1-plugins-good \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-ugly
}

install_rpms() {
  info "Apps RPM"

  try sudo dnf install -y --skip-unavailable \
    curl \
    wget \
    git \
    flatpak \
    google-chrome-stable \
    brave-browser \
    firefox \
    audacity \
    darktable \
    handbrake-gui \
    inkscape \
    easyeffects \
    gnome-tweaks \
    gnome-boxes \
    gnome-calculator \
    gnome-calendar \
    gnome-characters \
    gnome-connections \
    gnome-contacts \
    gnome-disk-utility \
    gnome-font-viewer \
    gnome-text-editor \
    gnome-color-manager \
    papirus-icon-theme \
    vlc
}

install_flatpaks() {
  info "Flatpaks"

  try flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

  for app in \
    net.nokyan.Resources \
    com.github.tchx84.Flatseal \
    com.rafaelmardojai.Blanket \
    org.freecad.FreeCAD \
    org.upscayl.Upscayl \
    org.shotcut.Shotcut \
    org.gnome.FileShredder \
    com.mattjakeman.ExtensionManager \
    com.usebruno.Bruno
  do
    step "$app"
    try flatpak install -y flathub "$app"
  done
}

install_freeoffice() {
  info "FreeOffice"

  try sudo dnf install -y curl

  TMPFILE="$(mktemp)"
  if curl -fsSL https://softmaker.net/down/install-softmaker-freeoffice-2024.sh -o "$TMPFILE"; then
    try sudo bash "$TMPFILE"
    rm -f "$TMPFILE"
    ok "FreeOffice instalado ou já presente"
  else
    rm -f "$TMPFILE"
    warn "Falha ao baixar instalador do FreeOffice"
  fi
}

install_nvidia() {
  info "NVIDIA"

  if lspci | grep -qi nvidia; then
    try sudo dnf install -y --skip-unavailable \
      akmod-nvidia \
      xorg-x11-drv-nvidia-cuda \
      nvidia-vaapi-driver
  else
    warn "Sem NVIDIA detectada"
  fi
}

remove_bloat() {
  info "Removendo bloat"

  try sudo dnf remove -y \
    'libreoffice*' \
    totem \
    totem-video-thumbnailer \
    gnome-music \
    rhythmbox \
    cheese \
    gnome-tour \
    mediawriter \
    gnome-system-monitor \
    yelp \
    dconf-editor \
    brasero \
    gnome-software \
    gnome-extensions-app \
    htop \
    piper

  try flatpak uninstall -y \
    org.gnome.Brasero \
    org.freedesktop.Piper \
    org.gnome.Totem \
    org.gnome.Music \
    org.gnome.Cheese \
    org.gnome.Software \
    org.gnome.Extensions \
    org.gnome.Help

  try sudo dnf autoremove -y
}

apply_visual() {
  info "Visual"

  gsettings set org.gnome.desktop.interface icon-theme 'Papirus' || true
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
}

verify() {
  info "Verificação"

  echo "Pacotes que não deveriam sobrar:"
  rpm -qa | grep -E "libreoffice|totem|cheese|gnome-music|rhythmbox|gnome-system-monitor|yelp|dconf-editor|brasero|gnome-software|gnome-extensions-app|htop|piper" || echo "Limpo"

  echo
  echo "Flatpaks principais:"
  flatpak list --app | grep -E "Resources|Flatseal|Blanket|FreeCAD|Upscayl|Shotcut|FileShredder|Extension|Bruno" || true
}

run_all() {
  add_repos
  update_system
  install_codecs
  install_rpms
  install_nvidia
  install_freeoffice
  install_flatpaks
  remove_bloat
  apply_visual
  verify
}

while true; do
  clear
  echo "===== Fedora-Y2K ====="
  echo "1) Rodar tudo"
  echo "2) Atualizar sistema"
  echo "3) Verificação"
  echo "0) Sair"

  read -rp "Escolha: " opt

  case $opt in
    1) run_all ;;
    2) update_system ;;
    3) verify ;;
    0) exit ;;
    *) echo "Opção inválida" ;;
  esac

  read -rp "Enter para continuar..."
done
