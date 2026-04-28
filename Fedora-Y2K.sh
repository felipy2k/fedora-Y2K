#!/usr/bin/env bash
# ==============================================================
# Fedora 44 Post-Install Setup
# Execute como usuário normal: bash fedora-setup.sh
# NÃO rode com sudo — o script pede sudo internamente
# ==============================================================
set -euo pipefail

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
info()    { echo -e "\n${GREEN}▶ $*${NC}"; }
step()    { echo -e "  ${CYAN}→ $*${NC}"; }
warning() { echo -e "  ${YELLOW}⚠ $*${NC}"; }
fail()    { echo -e "${RED}✗ $*${NC}"; }
ok()      { echo -e "  ${GREEN}✓ $*${NC}"; }
try()     { if ! "$@"; then warning "Falhou (continuando): $*"; fi; }

if [[ "$EUID" -eq 0 ]]; then
  fail "Não rode como root. O script pede sudo internamente quando necessário."
  exit 1
fi

FEDORA_VER=$(rpm -E %fedora)

# ==============================================================
# MENU INTERATIVO
# ==============================================================
show_menu() {
  clear
  echo -e "${BOLD}${BLUE}"
  echo "╔═══════════════════════════════════════════════════════════╗"
  echo "║         Fedora ${FEDORA_VER} — Setup Personalizado                   ║"
  echo "║         Usuário: ${USER}                                   ║"
  echo "╠═══════════════════════════════════════════════════════════╣"
  echo "║                                                           ║"
  echo "║  [1] Executar TUDO  (recomendado para instalação nova)   ║"
  echo "║  [2] Apenas atualizar sistema e kernels                  ║"
  echo "║  [3] Apenas remover bloatware                            ║"
  echo "║  [4] Apenas instalar pacotes RPM                         ║"
  echo "║  [5] Apenas instalar Flatpaks                            ║"
  echo "║  [6] Apenas instalar driver NVIDIA (auto-detect)         ║"
  echo "║  [7] Apenas instalar extensões GNOME                     ║"
  echo "║  [8] Apenas aplicar configurações visuais                ║"
  echo "║  [0] Sair                                                ║"
  echo "║                                                           ║"
  echo "╚═══════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  read -rp "  Escolha uma opção: " CHOICE
}

# ==============================================================
# 1. SISTEMA
# ==============================================================
update_system() {
  info "[SISTEMA] Limpando kernels antigos e atualizando"

  OLD_KERNELS=$(sudo dnf repoquery --installonly --latest=-1 -q 2>/dev/null || true)
  if [[ -n "$OLD_KERNELS" ]]; then
    step "Removendo kernels antigos..."
    # shellcheck disable=SC2086
    try sudo dnf remove -y $OLD_KERNELS
  else
    warning "Nenhum kernel antigo encontrado."
  fi

  step "Ajustando limite de kernels para 2..."
  sudo sed -i 's/^installonly_limit=.*/installonly_limit=2/' /etc/dnf/dnf.conf

  step "Atualizando sistema..."
  try sudo dnf upgrade --refresh -y
  ok "Sistema atualizado."
}

# ==============================================================
# 2. REPOSITÓRIOS
# ==============================================================
add_repos() {
  info "[REPOS] Adicionando repositórios externos"

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
  ok "Repositórios configurados."
}

# ==============================================================
# 3. LIMPEZA
# ==============================================================
remove_bloat() {
  info "[LIMPEZA] Removendo bloatware (mantém: Calendário, Contatos, Relógios, Backups)"

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
  ok "Bloatware removido."
}

# ==============================================================
# 4. NVIDIA AUTO-DETECT
# ==============================================================
install_nvidia() {
  info "[NVIDIA] Detectando GPU..."

  # Verifica se há GPU NVIDIA presente
  if ! lspci | grep -iE "nvidia|geforce|quadro|tesla" &>/dev/null; then
    warning "Nenhuma GPU NVIDIA detectada. Pulando instalação de driver."
    return
  fi

  GPU_NAME=$(lspci | grep -iE "nvidia|geforce|quadro|tesla" | head -1 | sed 's/.*: //')
  step "GPU detectada: ${GPU_NAME}"

  # Verifica se driver proprietário já está instalado
  if rpm -q akmod-nvidia &>/dev/null; then
    ok "Driver NVIDIA (akmod-nvidia) já está instalado."
    return
  fi

  echo ""
  echo -e "  ${YELLOW}GPU NVIDIA detectada: ${GPU_NAME}${NC}"
  read -rp "  Instalar driver proprietário NVIDIA? [s/N]: " NVIDIA_CONFIRM
  if [[ "${NVIDIA_CONFIRM,,}" != "s" ]]; then
    warning "Instalação do driver NVIDIA cancelada pelo usuário."
    return
  fi

  step "Instalando driver NVIDIA via RPM Fusion Nonfree..."
  # Garante que RPM Fusion nonfree está habilitado
  try sudo dnf install -y \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm"

  try sudo dnf install -y \
    akmod-nvidia \
    xorg-x11-drv-nvidia \
    xorg-x11-drv-nvidia-cuda \
    xorg-x11-drv-nvidia-power \
    nvidia-settings \
    nvidia-vaapi-driver

  step "Aguardando compilação do módulo kmod (pode demorar ~5 min)..."
  try sudo akmods --force

  ok "Driver NVIDIA instalado. REINICIE o sistema antes de continuar."
  echo ""
  read -rp "  Deseja reiniciar agora? [s/N]: " REBOOT_NOW
  if [[ "${REBOOT_NOW,,}" == "s" ]]; then
    sudo reboot
  fi
}

# ==============================================================
# 5. PACOTES RPM
# ==============================================================
install_base_rpm() {
  info "[RPM] Instalando pacotes base, codecs e apps"

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

  # Piper via Flatpak (mais atualizado que RPM) — incluído na lista de flatpaks
  # Solaar via RPM é suficiente
  step "Hardware (mouse Logitech)..."
  try sudo dnf install -y --skip-unavailable solaar

  ok "Pacotes RPM instalados."
}

# ==============================================================
# 6. FLATPAKS
# ==============================================================
install_flatpaks() {
  info "[FLATPAK] Instalando apps do Flathub"

  step "Adicionando Flathub..."
  flatpak remote-add --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo || true

  FLATPAK_IDS=(
    # ── Sistema e GNOME ────────────────────────────────────────
    com.mattjakeman.ExtensionManager        # Gestor de Extensões
    net.nokyan.Resources                    # Monitor de recursos
    com.github.tchx84.Flatseal             # Permissões Flatpak

    # ── Hardware / periféricos ─────────────────────────────────
    org.freedesktop.Piper                   # Piper - config mouse gaming (Flatpak mais atual)
    me.timschneeberger.GalaxyBudsClient     # BudsLink - Galaxy Buds

    # ── Utilitários ────────────────────────────────────────────
    io.github.peazip.PeaZip                 # Compactador
    io.github.Switcheroo.Switcheroo         # Conversor de imagens
    com.vixalien.sticky                     # Sticky Notes

    # ── Mídia ──────────────────────────────────────────────────
    com.rafaelmardojai.Blanket              # Sons ambientes
    de.haeckerfelix.Shortwave              # Rádio online
    org.gnome.Podcasts                      # Podcasts
    org.gnome.gitlab.YaLTeR.VideoTrimmer   # Video Trimmer
    com.obsproject.Studio                   # OBS Studio

    # ── Gráficos e IA ─────────────────────────────────────────
    org.upscayl.Upscayl                     # Upscale com IA
    com.github.jeffshee.Alpaca              # IA local (Ollama frontend)
    io.gitlab.adhami3310.Converter          # Conversor de imagens (Converter)
    app.devsuite.Exhibit                    # Visualizador de modelos 3D

    # ── Engenharia ─────────────────────────────────────────────
    org.freecad.FreeCAD                     # FreeCAD

    # ── Internet e downloads ───────────────────────────────────
    com.nordvpn.NordVPN                     # NordVPN
    com.motrix.Motrix                       # Gerenciador de downloads

    # ── Dev ────────────────────────────────────────────────────
    com.usebruno.Bruno                      # Bruno - cliente API REST

    # ── Produtividade ──────────────────────────────────────────
    com.github.phase1geo.Minder             # Minder - mapas mentais

    # ── Jogos ─────────────────────────────────────────────────
    net.dreamchess.dreamchess               # DreamChess - xadrez

    # ── Tela / apresentação ────────────────────────────────────
    io.github.deskreen.Deskreen             # Deskreen CE - espelhar tela
  )

  FAILED_FLATPAKS=()

  for app in "${FLATPAK_IDS[@]}"; do
    [[ "$app" == \#* ]] && continue
    [[ -z "${app// }" ]] && continue
    # Extrai só o ID (antes do comentário inline)
    APP_ID=$(echo "$app" | awk '{print $1}')
    step "↳ ${APP_ID}"
    if ! flatpak install -y flathub "${APP_ID}" 2>/dev/null; then
      warning "Não encontrado: ${APP_ID}"
      FAILED_FLATPAKS+=("${APP_ID}")
    fi
  done

  if [[ ${#FAILED_FLATPAKS[@]} -gt 0 ]]; then
    echo ""
    warning "Flatpaks não encontrados — confirme em flathub.org:"
    for f in "${FAILED_FLATPAKS[@]}"; do
      echo "      - $f"
    done
  fi

  ok "Flatpaks instalados."
}

# ==============================================================
# 7. EXTENSÕES GNOME
# ==============================================================
install_gnome_extensions() {
  info "[EXTENSÕES] Instalando extensões GNOME"

  # Instala gnome-extensions-cli (gext) se não existir
  if ! command -v gext &>/dev/null; then
    step "Instalando gnome-extensions-cli (pip)..."
    try pip3 install --user gnome-extensions-cli
    # Adiciona ao PATH se necessário
    export PATH="$HOME/.local/bin:$PATH"
  fi

  if ! command -v gext &>/dev/null; then
    warning "gext não encontrado no PATH. Tentando via pipx..."
    try sudo dnf install -y pipx
    try pipx install gnome-extensions-cli
    export PATH="$HOME/.local/bin:$PATH"
  fi

  # Extensões da sua captura de tela (imagem enviada agora)
  declare -A EXTENSIONS=(
    ["appindicatorsupport@rgcjonas.gmail.com"]="AppIndicator and KStatusNotifierItem Support"
    ["caffeine@patapon.info"]="Caffeine (evita suspensão)"
    ["dash-to-dock@micxgx.gmail.com"]="Dash to Dock"
    ["gsconnect@andyholmes.github.io"]="GSConnect (integração Android)"
    ["tilingshell@ferrarodomenico.com"]="Tiling Shell (tiling automático)"
  )

  step "Instalando ${#EXTENSIONS[@]} extensões..."

  for UUID in "${!EXTENSIONS[@]}"; do
    NAME="${EXTENSIONS[$UUID]}"
    step "↳ ${NAME}"
    if gext install "${UUID}" 2>/dev/null; then
      ok "${NAME} instalada."
    else
      # Fallback: tenta via URL direta do extensions.gnome.org
      warning "gext falhou para ${NAME} — tente instalar manualmente em extensions.gnome.org"
    fi
  done

  step "Habilitando extensões..."
  for UUID in "${!EXTENSIONS[@]}"; do
    try gext enable "${UUID}" 2>/dev/null || true
  done

  # Configurações específicas do Dash to Dock
  step "Configurando Dash to Dock..."
  try gsettings set org.gnome.shell.extensions.dash-to-dock dock-position   'BOTTOM'
  try gsettings set org.gnome.shell.extensions.dash-to-dock extend-height    false
  try gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed       false
  try gsettings set org.gnome.shell.extensions.dash-to-dock autohide         true
  try gsettings set org.gnome.shell.extensions.dash-to-dock intellihide      true

  ok "Extensões GNOME instaladas e habilitadas."
  warning "NOTA: GSConnect requer parear com o app Android KDE Connect."
}

# ==============================================================
# 8. ESPANSO (acelerador de digitação)
# ==============================================================
install_espanso() {
  info "[ESPANSO] Acelerador de digitação"

  if command -v espanso &>/dev/null; then
    ok "Espanso já instalado. Pulando."
    return
  fi

  step "Baixando Espanso RPM..."
  ESPANSO_URL="https://github.com/espanso/espanso/releases/latest/download/espanso-rpm-x86_64-unknown-linux-gnu.rpm"
  ESPANSO_TMP=$(mktemp /tmp/espanso-XXXXXX.rpm)

  if wget -q --show-progress -O "$ESPANSO_TMP" "$ESPANSO_URL"; then
    try sudo dnf install -y "$ESPANSO_TMP"
    rm -f "$ESPANSO_TMP"
    try espanso service register
    try espanso start
    ok "Espanso instalado e iniciado."
  else
    warning "Download falhou. Instale manualmente: https://espanso.org/install/linux/"
  fi
}

# ==============================================================
# 9. CONFIGURAÇÕES VISUAIS
# ==============================================================
apply_settings() {
  info "[VISUAL] Aplicando configurações visuais para: $USER"

  gsettings set org.gnome.desktop.interface icon-theme         'Papirus'
  gsettings set org.gnome.desktop.interface color-scheme       'prefer-dark'
  gsettings set org.gnome.desktop.interface font-antialiasing  'rgba'
  gsettings set org.gnome.desktop.interface font-hinting       'slight'
  gsettings set org.gnome.desktop.interface clock-show-seconds true
  gsettings set org.gnome.desktop.interface clock-show-date    true
  gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
  gsettings set org.gnome.desktop.peripherals.keyboard numlock-state true

  ok "Configurações aplicadas."
}

# ==============================================================
# EXECUÇÃO COMPLETA
# ==============================================================
run_all() {
  echo ""
  echo -e "${YELLOW}  Isso irá executar todas as etapas. Pode demorar 20-40 minutos.${NC}"
  read -rp "  Confirmar? [s/N]: " CONFIRM
  [[ "${CONFIRM,,}" != "s" ]] && { echo "  Cancelado."; return; }

  add_repos
  update_system
  remove_bloat
  install_nvidia
  install_base_rpm
  install_flatpaks
  install_gnome_extensions
  install_espanso
  apply_settings

  echo ""
  echo -e "${GREEN}${BOLD}"
  echo "╔═══════════════════════════════════════════════════════════╗"
  echo "║  ✓  Setup finalizado! Reinicie o sistema.                ║"
  echo "║                                                           ║"
  echo "║  Pós-instalação manual:                                   ║"
  echo "║  • NordVPN:   nordvpn login                              ║"
  echo "║  • Espanso:   espanso edit  (configurar atalhos)         ║"
  echo "║  • GSConnect: parear via app KDE Connect no Android      ║"
  echo "║  • Packet / Reddit: confirmar IDs em flathub.org         ║"
  echo "╚═══════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

# ==============================================================
# LOOP DO MENU
# ==============================================================
while true; do
  show_menu
  case "$CHOICE" in
    1) run_all ;;
    2) add_repos; update_system ;;
    3) remove_bloat ;;
    4) add_repos; install_base_rpm ;;
    5) install_flatpaks ;;
    6) add_repos; install_nvidia ;;
    7) install_gnome_extensions ;;
    8) apply_settings ;;
    0) echo "  Saindo."; exit 0 ;;
    *) warning "Opção inválida. Tente novamente." ;;
  esac

  echo ""
  read -rp "  Pressione ENTER para voltar ao menu..." _
done
