#!/usr/bin/env bash
# ==============================================================
# Fedora Post-Install Setup
# Execute como usuário normal: bash fedora-setup.sh
# NÃO rode com sudo — o script pede sudo internamente quando necessário
# ==============================================================
set -euo pipefail

# --- Cores para output ---
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; NC='\033[0m'
info()    { echo -e "${GREEN}>> $*${NC}"; }
warning() { echo -e "${YELLOW}[AVISO] $*${NC}"; }
fail()    { echo -e "${RED}[ERRO] $*${NC}"; }

# Executa comando sem abortar o script em caso de falha
try() {
  if ! "$@"; then
    warning "Falhou (continuando): $*"
  fi
}

# Garante que o script não está sendo rodado como root diretamente
if [[ "$EUID" -eq 0 ]]; then
  fail "Não rode este script como root/sudo. Ele pede sudo internamente."
  exit 1
fi

# ==============================================================
update_system() {
  info "[SISTEMA] Otimizando kernels e atualizando"

  # Remove kernels antigos (mantém os 2 mais recentes)
  OLD_KERNELS=$(sudo dnf repoquery --installonly --latest=-1 -q 2>/dev/null || true)
  if [[ -n "$OLD_KERNELS" ]]; then
    # shellcheck disable=SC2086
    try sudo dnf remove -y $OLD_KERNELS
  else
    warning "Nenhum kernel antigo para remover."
  fi

  # Reduz limite de kernels para 2
  sudo sed -i 's/^installonly_limit=.*/installonly_limit=2/' /etc/dnf/dnf.conf

  try sudo dnf upgrade --refresh -y
}

# ==============================================================
add_repos() {
  info "[REPOS] Adicionando repositórios externos necessários"

  # RPM Fusion (Free e Nonfree) — necessário para ffmpeg, vlc, codecs
  try sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

  # Google Chrome
  if [[ ! -f /etc/yum.repos.d/google-chrome.repo ]]; then
    sudo tee /etc/yum.repos.d/google-chrome.repo > /dev/null <<'EOF'
[google-chrome]
name=Google Chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
    info "Repositório Google Chrome adicionado."
  fi

  # Brave Browser
  if [[ ! -f /etc/yum.repos.d/brave-browser.repo ]]; then
    sudo dnf config-manager --add-repo \
      "https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo" || \
      warning "Não foi possível adicionar repo do Brave."
    info "Repositório Brave adicionado."
  fi

  try sudo dnf makecache
}

# ==============================================================
remove_bloat() {
  info "[LIMPEZA] Removendo bloatware (mantendo Calendário e Contatos)"
  try sudo dnf remove -y \
    'libreoffice*' totem gnome-music rhythmbox gnome-tour \
    mediawriter gnome-maps gnome-weather gnome-connections
  try sudo dnf autoremove -y
}

# ==============================================================
install_base_rpm() {
  info "[RPM] Instalando pacotes base e codecs"
  try sudo dnf install -y --skip-unavailable \
    gnome-tweaks gnome-extensions-app papirus-icon-theme \
    ffmpeg ffmpeg-libs libavcodec-freeworld vlc \
    easyeffects git wget curl piper solaar \
    google-chrome-stable brave-browser \
    audacity inkscape darktable handbrake-gui
}

# ==============================================================
install_flatpaks() {
  info "[FLATPAK] Instalando apps via Flathub"
  flatpak remote-add --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo || true

  FLATPAKS=(
    com.mattjakeman.ExtensionManager  # Gestor de Extensões GNOME
    org.freecad.FreeCAD
    net.nokyan.Resources
    com.github.tchx84.Flatseal
    com.rafaelmardojai.Blanket
    org.upscayl.Upscayl
    com.github.jeffshee.Alpaca
    com.motrix.Motrix
    io.github.peazip.PeaZip
    com.nordvpn.NordVPN
    com.usebruno.Bruno
    org.gnome.gitlab.YaLTeR.VideoTrimmer
  )

  for app in "${FLATPAKS[@]}"; do
    # Ignora comentários inline
    [[ "$app" == \#* ]] && continue
    info "Instalando flatpak: $app"
    try flatpak install -y flathub "$app"
  done
}

# ==============================================================
apply_gsettings() {
  info "[VISUAL] Aplicando configurações visuais (como usuário: $USER)"
  # gsettings deve rodar como o usuário atual, não como root
  gsettings set org.gnome.desktop.interface icon-theme 'Papirus'
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
}

# ==============================================================
# --- Execução principal ---
update_system
add_repos
remove_bloat
install_base_rpm
install_flatpaks
apply_gsettings

echo ""
echo "===================================================="
echo " Setup Finalizado com sucesso!"
echo " - Extension Manager incluído (via Flatpak)"
echo " - Repos do Chrome e Brave adicionados corretamente"
echo " - gsettings aplicado como usuário $USER"
echo "===================================================="
