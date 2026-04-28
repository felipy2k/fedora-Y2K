#!/usr/bin/env bash
# ==============================================================
# Fedora 44 Post-Install Setup
# Baseado na lista real de aplicativos do usuário
#
# Execute como usuário normal: bash fedora-setup.sh
# NÃO rode com sudo — o script pede sudo internamente
# ==============================================================
set -euo pipefail

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "\n${GREEN}▶ $*${NC}"; }
step()    { echo -e "  ${CYAN}→ $*${NC}"; }
warning() { echo -e "  ${YELLOW}⚠ $*${NC}"; }
fail()    { echo -e "${RED}✗ $*${NC}"; }
try()     { if ! "$@"; then warning "Falhou (continuando): $*"; fi; }

if [[ "$EUID" -eq 0 ]]; then
  fail "Não rode este script como root. Ele pede sudo internamente."
  exit 1
fi

FEDORA_VER=$(rpm -E %fedora)

# ==============================================================
update_system() {
  info "[1/7] SISTEMA — Limpando kernels antigos e atualizando"
  OLD_KERNELS=$(sudo dnf repoquery --installonly --latest=-1 -q 2>/dev/null || true)
  if [[ -n "$OLD_KERNELS" ]]; then
    # shellcheck disable=SC2086
    try sudo dnf remove -y $OLD_KERNELS
  else
    warning "Nenhum kernel antigo encontrado."
  fi
  sudo sed -i 's/^installonly_limit=.*/installonly_limit=2/' /etc/dnf/dnf.conf
  try sudo dnf upgrade --refresh -y
}

# ==============================================================
add_repos() {
  info "[2/7] REPOSITÓRIOS — Adicionando fontes externas"

  step "RPM Fusion (Free + Nonfree)..."
  try sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm"

  step "Google Chrome..."
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

  step "Brave Browser..."
  if [[ ! -f /etc/yum.repos.d/brave-browser.repo ]]; then
    try sudo dnf config-manager --add-repo \
      "https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo"
  fi

  try sudo dnf makecache
}

# ==============================================================
remove_bloat() {
  info "[3/7] LIMPEZA — Removendo bloatware (mantém: Calendário, Contatos, Relógios, Backups)"

  try sudo dnf remove -y \
    'libreoffice*' \
    totem \
    gnome-music \
    rhythmbox \
    gnome-tour \
    mediawriter \
    gnome-maps \
    gnome-weather \
    gnome-connections \
    cheese \
    gnome-boxes \
    simple-scan

  try sudo dnf autoremove -y
}

# ==============================================================
install_base_rpm() {
  info "[4/7] RPM — Instalando pacotes, codecs e apps"

  step "Codecs e multimídia..."
  try sudo dnf install -y --skip-unavailable \
    ffmpeg ffmpeg-libs \
    libavcodec-freeworld \
    vlc \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-good \
    gstreamer1-plugins-base \
    gstreamer1-plugin-openh264 \
    lame

  step "GNOME utilitários e tema..."
  try sudo dnf install -y --skip-unavailable \
    gnome-tweaks \
    gnome-extensions-app \
    papirus-icon-theme \
    dconf-editor

  step "Hardware (mouse, fone)..."
  try sudo dnf install -y --skip-unavailable \
    piper \
    solaar

  step "Ferramentas de sistema..."
  try sudo dnf install -y --skip-unavailable \
    git wget curl \
    timeshift \
    brasero \
    htop powertop

  step "Áudio..."
  try sudo dnf install -y --skip-unavailable \
    easyeffects \
    audacity

  step "Gráficos e vídeo..."
  try sudo dnf install -y --skip-unavailable \
    inkscape \
    darktable \
    handbrake-gui \
    shotcut

  step "Navegadores..."
  try sudo dnf install -y --skip-unavailable \
    google-chrome-stable \
    brave-browser
}

# ==============================================================
install_flatpaks() {
  info "[5/7] FLATPAK — Instalando apps do Flathub"

  step "Adicionando Flathub..."
  flatpak remote-add --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo || true

  # Lista completa baseada nas suas capturas de tela
  FLATPAK_IDS=(
    # ── Sistema e GNOME ────────────────────────────────────────
    com.mattjakeman.ExtensionManager   # Gestor de Extensões (imagem 6)
    net.nokyan.Resources               # Monitor de recursos (imagem 6)
    com.github.tchx84.Flatseal         # Permissões Flatpak (imagem 6)

    # ── Utilitários de arquivo ─────────────────────────────────
    io.github.peazip.PeaZip            # Compactador (imagem 6)
    io.github.Switcheroo.Switcheroo    # Conversor de imagens (imagem 7)
    com.github.fabiocolacio.marker     # Marknota - editor Markdown (imagem 6)

    # ── Mídia e entretenimento ─────────────────────────────────
    com.rafaelmardojai.Blanket         # Sons ambientes (imagem 6)
    de.haeckerfelix.Shortwave          # Rádio online (imagem 7)
    org.gnome.Podcasts                 # Podcasts (imagem 7)
    org.gnome.gitlab.YaLTeR.VideoTrimmer  # Video Trimmer (imagem 7)

    # ── Gráficos e IA ─────────────────────────────────────────
    org.upscayl.Upscayl                # Upscale com IA (imagem 6, 3)
    com.github.jeffshee.Alpaca         # IA local (imagem 6)
    io.gitlab.adhami3310.Converter     # Converseen / conversor (imagem 7)
    app.devsuite.Exhibit               # Visualizador de modelos 3D (imagem 7)

    # ── Engenharia ─────────────────────────────────────────────
    org.freecad.FreeCAD                # FreeCAD (imagem 6)

    # ── Internet e downloads ───────────────────────────────────
    com.nordvpn.NordVPN                # NordVPN (imagem 6)
    com.motrix.Motrix                  # Gerenciador de downloads (imagem 6)

    # ── Dev e APIs ─────────────────────────────────────────────
    com.usebruno.Bruno                 # Cliente de API REST (imagem 2)
    com.obsproject.Studio              # OBS Studio (imagem 7)

    # ── Produtividade / mapas mentais ──────────────────────────
    com.github.phase1geo.Minder        # Minder - mapas mentais (imagem 2)

    # ── Notas ─────────────────────────────────────────────────
    com.vixalien.sticky                # Sticky Notes (imagem 7)

    # ── Jogos ─────────────────────────────────────────────────
    net.dreamchess.dreamchess          # DreamChess - xadrez (imagem 7)

    # ── Hardware / periféricos ─────────────────────────────────
    me.timschneeberger.GalaxyBudsClient  # BudsLink - Galaxy Buds (imagem 8)

    # ── Imagem 8 ───────────────────────────────────────────────
    io.github.deskreen.Deskreen        # Deskreen CE - espelhar tela
    # Reddit: sem Flatpak oficial — usar via browser
    # Packet: provavelmente é com.github.Clacky.Packet (confirmar no Flathub)
  )

  FAILED_FLATPAKS=()

  for app in "${FLATPAK_IDS[@]}"; do
    [[ "$app" == \#* ]] && continue
    [[ -z "${app// }" ]] && continue

    step "↳ $app"
    if ! flatpak install -y flathub "$app" 2>/dev/null; then
      warning "Não encontrado: $app"
      FAILED_FLATPAKS+=("$app")
    fi
  done

  if [[ ${#FAILED_FLATPAKS[@]} -gt 0 ]]; then
    echo ""
    warning "Flatpaks não encontrados (verifique IDs em flathub.org):"
    for f in "${FAILED_FLATPAKS[@]}"; do
      echo "      - $f"
    done
  fi
}

# ==============================================================
install_espanso() {
  info "[6/7] ESPANSO — Acelerador de digitação (imagem 4)"

  if command -v espanso &>/dev/null; then
    warning "Espanso já instalado. Pulando."
    return
  fi

  step "Baixando Espanso RPM..."
  ESPANSO_URL="https://github.com/espanso/espanso/releases/latest/download/espanso-rpm-x86_64-unknown-linux-gnu.rpm"
  ESPANSO_TMP=$(mktemp /tmp/espanso-XXXXXX.rpm)

  if wget -q --show-progress -O "$ESPANSO_TMP" "$ESPANSO_URL"; then
    try sudo dnf install -y "$ESPANSO_TMP"
    rm -f "$ESPANSO_TMP"
    step "Registrando Espanso como serviço..."
    try espanso service register
    try espanso start
    step "✓ Espanso instalado."
  else
    warning "Download falhou. Instale manualmente: https://espanso.org/install/linux/"
  fi
}

# ==============================================================
apply_settings() {
  info "[7/7] CONFIGURAÇÕES — Tema e preferências visuais"

  gsettings set org.gnome.desktop.interface icon-theme          'Papirus'
  gsettings set org.gnome.desktop.interface color-scheme        'prefer-dark'
  gsettings set org.gnome.desktop.interface font-antialiasing   'rgba'
  gsettings set org.gnome.desktop.interface font-hinting        'slight'
  gsettings set org.gnome.desktop.interface clock-show-seconds  true
  gsettings set org.gnome.desktop.interface clock-show-date     true
  gsettings set org.gnome.desktop.wm.preferences button-layout  'appmenu:minimize,maximize,close'
  gsettings set org.gnome.desktop.peripherals.keyboard numlock-state true

  step "✓ Configurações aplicadas para o usuário: $USER"
}

# ==============================================================
# EXECUÇÃO
# ==============================================================
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║         Fedora 44 — Setup Personalizado                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

update_system
add_repos
remove_bloat
install_base_rpm
install_flatpaks
install_espanso
apply_settings

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  ✓  Setup finalizado! Reinicie para aplicar tudo.        ║"
echo "║                                                           ║"
echo "║  Pós-instalação manual:                                   ║"
echo "║  • NordVPN:  nordvpn login                               ║"
echo "║  • Espanso:  espanso edit  (configurar atalhos)          ║"
echo "║  • Extensões GNOME: abrir Extension Manager              ║"
echo "║  • Reddit / Packet: confirmar IDs em flathub.org         ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
