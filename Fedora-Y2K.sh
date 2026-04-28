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
    warning "Falhou, continuando: $*"
  fi
}

if [[ "$EUID" -eq 0 ]]; then
  fail "Não rode como root. Rode como usuário normal."
  exit 1
fi

FEDORA_VER="$(rpm -E %fedora)"

show_menu() {
  clear
  echo -e "${BOLD}${BLUE}"
  echo "╔═══════════════════════════════════════════════════════════╗"
  echo "║         Fedora ${FEDORA_VER} — Setup Personalizado        ║"
  echo "║         Usuário: ${USER}                                  ║"
  echo "╠═══════════════════════════════════════════════════════════╣"
  echo "║  [1] Executar TUDO                                       ║"
  echo "║  [2] Apenas atualizar sistema                            ║"
  echo "║  [3] Apenas remover bloatware                            ║"
  echo "║  [4] Apenas instalar pacotes RPM                         ║"
  echo "║  [5] Apenas instalar Flatpaks                            ║"
  echo "║  [6] Apenas instalar driver NVIDIA                       ║"
  echo "║  [7] Apenas aplicar configurações visuais                ║"
  echo "║  [8] Verificação final                                   ║"
  echo "║  [0] Sair                                                ║"
  echo "╚═══════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  read -rp "  Escolha uma opção: " CHOICE
}

update_system() {
  info "[SISTEMA] Atualizando sistema"
  try sudo sed -i 's/^installonly_limit=.*/installonly_limit=2/' /etc/dnf/dnf.conf
  try sudo dnf upgrade --refresh -y
}

add_repos() {
  info "[REPOS] Adicionando repositórios"

  try sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm"

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

  if [[ ! -f /etc/yum.repos.d/brave-browser.repo ]]; then
    try sudo dnf config-manager --add-repo \
      "https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo"
    try sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
  fi

  try sudo dnf makecache
}

install_codecs() {
  info "[CODECS] Instalando codecs e VLC"

  try sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing

  try sudo dnf install -y --skip-unavailable \
    ffmpeg \
    ffmpeg-libs \
    libavcodec-freeworld \
    vlc \
    lame \
    gstreamer1-libav \
    gstreamer1-plugins-base \
    gstreamer1-plugins-good \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-ugly \
    gstreamer1-plugin-openh264
}

remove_bloat() {
  info "[LIMPEZA] Removendo bloatware"

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
    org.freedesktop.Piper \
    org.gnome.Totem \
    org.gnome.Music \
    org.gnome.Cheese \
    org.gnome.Software \
    org.gnome.Extensions \
    org.gnome.Help \
    com.usebruno.Bruno

  try sudo dnf autoremove -y
}

install_nvidia() {
  info "[NVIDIA] Detectando GPU"

  if ! lspci | grep -qiE "nvidia|geforce|quadro|tesla"; then
    warning "Nenhuma GPU NVIDIA detectada. Pulando."
    return
  fi

  step "GPU NVIDIA detectada"

  try sudo dnf install -y --skip-unavailable \
    akmod-nvidia \
    xorg-x11-drv-nvidia \
    xorg-x11-drv-nvidia-cuda \
    xorg-x11-drv-nvidia-power \
    nvidia-settings \
    nvidia-vaapi-driver

  try sudo akmods --force
}

install_rpms() {
  info "[RPM] Instalando pacotes RPM"

  install_codecs

  try sudo dnf install -y --skip-unavailable \
    dnf-plugins-core \
    git \
    wget \
    curl \
    flatpak \
    fastfetch \
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

install_freeoffice() {
  info "[FREEOFFICE] Instalando FreeOffice"

  try sudo dnf install -y curl

  TMPFILE="$(mktemp)"
  if curl -fsSL https://softmaker.net/down/install-softmaker-freeoffice-2024.sh -o "$TMPFILE"; then
    try sudo bash "$TMPFILE"
    rm -f "$TMPFILE"
    ok "FreeOffice instalado ou já presente."
  else
    rm -f "$TMPFILE"
    warning "Falha ao baixar FreeOffice."
  fi
}

install_flatpaks() {
  info "[FLATPAK] Instalando apps do Flathub"

  try flatpak remote-add --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo

  FLATPAK_IDS=(
    net.nokyan.Resources
    com.github.tchx84.Flatseal
    com.rafaelmardojai.Blanket
    org.gnome.FileShredder
    org.freecad.FreeCAD
    org.upscayl.Upscayl
    org.shotcut.Shotcut
  )

  for app in "${FLATPAK_IDS[@]}"; do
    step "$app"
    try flatpak install -y flathub "$app"
  done
}

apply_settings() {
  info "[VISUAL] Aplicando configurações"

  try gsettings set org.gnome.desktop.interface icon-theme 'Papirus'
  try gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  try gsettings set org.gnome.desktop.interface clock-show-date true
  try gsettings set org.gnome.desktop.interface clock-show-seconds true
}

verify_final() {
  info "[VERIFICAÇÃO] Checando estado final"

  echo
  echo "Pacotes que deveriam ter saído:"
  rpm -qa | grep -E "libreoffice|totem|cheese|gnome-music|rhythmbox|gnome-system-monitor|yelp|dconf-editor|brasero|gnome-software|gnome-extensions-app|htop|piper" || ok "Nada crítico encontrado."

  echo
  echo "Flatpaks esperados:"
  flatpak list --app | grep -E "Resources|Flatseal|Blanket|FreeCAD|Upscayl|Shotcut|FileShredder" || warning "Algum Flatpak esperado pode não ter instalado."

  echo
  echo "FreeOffice:"
  rpm -qa | grep -i softmaker || warning "FreeOffice não encontrado via RPM."
}

run_all() {
  echo
  echo -e "${YELLOW}Isso irá executar todas as etapas. Pode demorar.${NC}"
  read -rp "Confirmar? [s/N]: " CONFIRM
  [[ "${CONFIRM,,}" != "s" ]] && { warning "Cancelado."; return; }

  add_repos
  update_system
  install_rpms
  install_nvidia
  install_freeoffice
  install_flatpaks
  remove_bloat
  apply_settings
  verify_final

  echo
  ok "Setup finalizado. Reinicie o sistema."
}

while true; do
  show_menu

  case "$CHOICE" in
    1) run_all ;;
    2) add_repos; update_system ;;
    3) remove_bloat ;;
    4) add_repos; install_rpms; install_freeoffice ;;
    5) install_flatpaks ;;
    6) add_repos; install_nvidia ;;
    7) apply_settings ;;
    8) verify_final ;;
    0) echo "Saindo."; exit 0 ;;
    *) warning "Opção inválida." ;;
  esac

  echo
  read -rp "Pressione ENTER para voltar ao menu..." _
done
