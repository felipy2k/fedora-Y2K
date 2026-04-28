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
  echo "║  [7] Apenas instalar extensões GNOME                     ║"
  echo "║  [8] Apenas aplicar configurações visuais                ║"
  echo "║  [9] Verificação final                                   ║"
  echo "║  [0] Sair                                                ║"
  echo "╚═══════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  read -rp "  Escolha uma opção: " CHOICE
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

update_system() {
  info "[SISTEMA] Atualizando sistema"
  try sudo sed -i 's/^installonly_limit=.*/installonly_limit=2/' /etc/dnf/dnf.conf
  try sudo dnf upgrade --refresh -y
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
    papirus-icon-theme \
    google-chrome-stable \
    brave-browser \
    firefox \
    torbrowser-launcher \
    vlc \
    audacity \
    darktable \
    handbrake-gui \
    inkscape \
    easyeffects \
    gimp \
    obs-studio \
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
    gnome-extensions-app \
    gnome-software \
    gnome-clocks \
    gnome-logs \
    gnome-terminal \
    evince \
    loupe \
    timeshift \
    solaar
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
    com.mattjakeman.ExtensionManager
    net.nokyan.Resources
    com.github.tchx84.Flatseal
    com.rafaelmardojai.Blanket
    org.gnome.FileShredder
    org.freecad.FreeCAD
    org.upscayl.Upscayl
    org.shotcut.Shotcut
    org.gnome.gitlab.YaLTeR.VideoTrimmer
    com.jeffser.Alpaca
    hu.irl.cameractrls
    net.fasterland.converseen
    net.dreamchess.dreamchess
    app.devsuite.Exhibit
    com.github.phase1geo.Minder
    com.motrix.Motrix
    io.github.nozwock.Packet
    io.github.peazip.PeaZip
    org.gnome.Podcasts
    com.system76.Popsicle
    com.poweriso.PowerISO
    nl.hjdskes.gcolor3
    de.haeckerfelix.Shortwave
    com.vixalien.sticky
    io.gitlab.adhami3310.Converter
    io.github.maniacx.BudsLink
    com.usebruno.Bruno
  )

  for app in "${FLATPAK_IDS[@]}"; do
    step "$app"
    try flatpak install -y flathub "$app"
  done
}

install_nvidia() {
  info "[NVIDIA] Detectando GPU"

  if ! lspci | grep -qiE "nvidia|geforce|quadro|tesla"; then
    warning "Nenhuma GPU NVIDIA detectada. Pulando."
    return
  fi

  try sudo dnf install -y --skip-unavailable \
    akmod-nvidia \
    xorg-x11-drv-nvidia \
    xorg-x11-drv-nvidia-cuda \
    xorg-x11-drv-nvidia-power \
    nvidia-settings \
    nvidia-vaapi-driver

  try sudo akmods --force
}

install_gnome_extensions() {
  info "[EXTENSÕES] Instalando extensões GNOME"

  try sudo dnf install -y --skip-unavailable \
    gnome-extensions-app \
    pipx

  export PATH="$HOME/.local/bin:$PATH"

  if ! command -v gext &>/dev/null; then
    step "Instalando gnome-extensions-cli"
    try pipx install gnome-extensions-cli
  fi

  export PATH="$HOME/.local/bin:$PATH"

  EXTENSIONS=(
    appindicatorsupport@rgcjonas.gmail.com
    caffeine@patapon.info
    dash-to-dock@micxgx.gmail.com
    gsconnect@andyholmes.github.io
    tilingshell@ferrarodomenico.com
  )

  if command -v gext &>/dev/null; then
    for ext in "${EXTENSIONS[@]}"; do
      step "$ext"
      try gext install "$ext"
      try gext enable "$ext"
    done
  else
    warning "gext não disponível. Instale pelo Extension Manager."
    echo "Extensões:"
    printf '  - %s\n' "${EXTENSIONS[@]}"
  fi
}

remove_bloat() {
  info "[LIMPEZA] Removendo somente o que saiu da lista"

  try sudo dnf remove -y \
    'libreoffice*' \
    brasero \
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
    htop \
    piper

  try flatpak uninstall -y \
    org.freedesktop.Piper \
    org.gnome.Help

  try sudo dnf autoremove -y
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
  rpm -qa | grep -E "libreoffice|^brasero|^totem|totem-video-thumbnailer|^cheese|gnome-music|rhythmbox|gnome-tour|mediawriter|gnome-system-monitor|yelp|dconf-editor|^htop|^piper" || ok "Nada crítico encontrado."

  echo
  echo "Pacotes que devem existir:"
  rpm -qa | grep -E "google-chrome-stable|brave-browser|firefox|vlc|audacity|darktable|handbrake|inkscape|easyeffects|gimp|obs-studio|gnome-software|gnome-extensions-app|papirus|softmaker|freeoffice|solaar|timeshift|deja-dup" || true

  echo
  echo "Flatpaks esperados:"
  flatpak list --app | grep -E "Alpaca|Resources|Flatseal|Blanket|FileShredder|FreeCAD|Upscayl|Shotcut|Video|Cameractrls|Converseen|DreamChess|Exhibit|Minder|Motrix|Packet|PeaZip|Podcasts|Popsicle|PowerISO|Shortwave|Sticky|Switcheroo|BudsLink|Bruno" || warning "Algum Flatpak esperado pode não ter instalado."
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
  install_gnome_extensions
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
    7) install_gnome_extensions ;;
    8) apply_settings ;;
    9) verify_final ;;
    0) echo "Saindo."; exit 0 ;;
    *) warning "Opção inválida." ;;
  esac

  echo
  read -rp "Pressione ENTER para voltar ao menu..." _
done
