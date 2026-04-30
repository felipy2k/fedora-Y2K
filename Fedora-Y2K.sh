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
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║           Fedora ${FEDORA_VER} — Setup Personalizado          ║"
  echo "║           Usuário: ${USER}                                    ║"
  echo "╠═══════════════════════════════════════════════════════════════╣"
  echo "║  [1] Executar TUDO (recomendado)                             ║"
  echo "║  [2] Apenas atualizar sistema                                ║"
  echo "║  [3] Apenas remover bloatware                                ║"
  echo "║  [4] Apenas instalar pacotes RPM                             ║"
  echo "║  [5] Apenas instalar Flatpaks                                ║"
  echo "║  [6] Apenas instalar driver NVIDIA + CUDA                    ║"
  echo "║  [7] Apenas instalar extensões GNOME                         ║"
  echo "║  [8] Apenas aplicar configurações visuais                    ║"
  echo "║  [9] Verificação final                                       ║"
  echo "║  [0] Sair                                                    ║"
  echo "║  [r] Sair e reiniciar o sistema                              ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  read -rp "  Escolha uma opção: " CHOICE
}

# ─────────────────────────────────────────────
# REPOS
# ─────────────────────────────────────────────
add_repos() {
  info "[REPOS] Adicionando repositórios"

  step "RPM Fusion"
  try sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm"

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

  step "Brave Browser"
  if [[ ! -f /etc/yum.repos.d/brave-browser.repo ]]; then
    try sudo dnf config-manager --add-repo \
      "https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo"
    try sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
  fi

  try sudo dnf makecache
}

# ─────────────────────────────────────────────
# SISTEMA
# ─────────────────────────────────────────────
update_system() {
  info "[SISTEMA] Atualizando sistema"
  # Mantém apenas 2 kernels antigos para economizar espaço
  try sudo sed -i 's/^installonly_limit=.*/installonly_limit=2/' /etc/dnf/dnf.conf
  try sudo dnf upgrade --refresh -y
}

# ─────────────────────────────────────────────
# CODECS
# ─────────────────────────────────────────────
install_codecs() {
  info "[CODECS] Instalando codecs multimídia"

  # Troca ffmpeg livre pelo completo (com patentes)
  try sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing

  try sudo dnf install -y --skip-unavailable \
    ffmpeg \
    ffmpeg-libs \
    libavcodec-freeworld \
    lame \
    gstreamer1-libav \
    gstreamer1-plugins-base \
    gstreamer1-plugins-good \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-ugly \
    gstreamer1-plugin-openh264
}

# ─────────────────────────────────────────────
# RPMs
# Instala TUDO antes de remover qualquer coisa
# para não quebrar dependências
# ─────────────────────────────────────────────
install_rpms() {
  info "[RPM] Instalando pacotes RPM"

  install_codecs

  try sudo dnf install -y --skip-unavailable \
    \
    `# Ferramentas base` \
    dnf-plugins-core \
    git \
    wget \
    curl \
    flatpak \
    fastfetch \
    pipx \
    papirus-icon-theme \
    \
    `# Navegadores` \
    google-chrome-stable \
    brave-browser \
    firefox \
    torbrowser-launcher \
    \
    `# Multimídia` \
    vlc \
    audacity \
    darktable \
    handbrake-gui \
    easyeffects \
    obs-studio \
    \
    `# Gráficos / Edição` \
    gimp \
    inkscape \
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
    gnome-extensions-app \
    gnome-software \
    gnome-clocks \
    gnome-logs \
    gnome-terminal \
    evince \
    loupe \
    \
    `# Utilitários` \
    timeshift \
    solaar
}

# ─────────────────────────────────────────────
# FREEOFFICE
# Substitui o LibreOffice (removido depois)
# ─────────────────────────────────────────────
install_freeoffice() {
  info "[FREEOFFICE] Instalando FreeOffice 2024"

  step "Baixando e executando instalador oficial"
  if curl -fsSL https://softmaker.net/down/install-softmaker-freeoffice-2024.sh | sudo bash; then
    ok "FreeOffice instalado com sucesso."
  else
    warning "Falha ao instalar FreeOffice. Tente manualmente:"
    echo "  curl -fsSL https://softmaker.net/down/install-softmaker-freeoffice-2024.sh | sudo bash"
  fi
}

# ─────────────────────────────────────────────
# FLATPAKS
# ─────────────────────────────────────────────
install_flatpaks() {
  info "[FLATPAK] Instalando apps do Flathub"

  try flatpak remote-add --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo

  FLATPAK_IDS=(
    # Utilitários do sistema
    com.mattjakeman.ExtensionManager        # Gestor de Extensões GNOME
    net.nokyan.Resources                    # Monitor de recursos
    com.github.tchx84.Flatseal             # Permissões Flatpak
    io.github.peazip.PeaZip                # Compactador
    com.system76.Popsicle                   # Gravador USB
    com.poweriso.PowerISO                   # ISO manager
    org.gnome.FileShredder                  # Destruidor de arquivos
    io.github.nozwock.Packet               # Packet (rede)
    io.github.jejakeen.paper-clip          # Paper Clip (metadados PDF)
    io.gitlab.adhami3310.Converter         # Switcheroo (conversor de imagens)

    # Multimídia
    org.shotcut.Shotcut                     # Editor de vídeo
    org.gnome.gitlab.YaLTeR.VideoTrimmer   # Aparador de vídeo
    hu.irl.cameractrls                      # Controles de câmera
    net.fasterland.converseen              # Conversor de imagens em lote

    # Produtividade / Criatividade
    org.freecad.FreeCAD                    # CAD 3D
    org.upscayl.Upscayl                    # Upscale de imagens (IA)
    app.devsuite.Exhibit                   # Visualizador 3D/modelos
    com.github.phase1geo.Minder            # Mapas mentais
    com.motrix.Motrix                      # Gerenciador de downloads
    com.usebruno.Bruno                     # Cliente API REST

    # Entretenimento / Som / Outros
    net.dreamchess.dreamchess              # Xadrez
    com.rafaelmardojai.Blanket             # Sons ambiente
    de.haeckerfelix.Shortwave              # Rádio online
    org.gnome.Podcasts                     # Podcasts
    nl.hjdskes.gcolor3                     # Seletor de cor
    com.vixalien.sticky                    # Sticky Notes
    io.github.maniacx.BudsLink            # BudsLink (Galaxy Buds)
    com.jeffser.Alpaca                     # Alpaca (LLM local)
  )

  for app in "${FLATPAK_IDS[@]}"; do
    # Ignora comentários inline
    app="${app%%#*}"
    app="${app//[[:space:]]/}"
    [[ -z "$app" ]] && continue
    step "$app"
    try flatpak install -y flathub "$app"
  done
}

# ─────────────────────────────────────────────
# NVIDIA
# Autodetecta GPU — instala apenas se encontrar
# ─────────────────────────────────────────────
install_nvidia() {
  info "[NVIDIA] Detectando GPU"

  if ! lspci | grep -qiE "nvidia|geforce|quadro|tesla"; then
    warning "Nenhuma GPU NVIDIA detectada. Pulando instalação do driver."
    return
  fi

  ok "GPU NVIDIA detectada: $(lspci | grep -iE 'nvidia|geforce|quadro|tesla' | head -1)"

  step "Instalando driver NVIDIA + CUDA"
  try sudo dnf install -y --skip-unavailable \
    akmod-nvidia \
    xorg-x11-drv-nvidia \
    xorg-x11-drv-nvidia-cuda \
    xorg-x11-drv-nvidia-cuda-libs \
    xorg-x11-drv-nvidia-power \
    nvidia-settings \
    nvidia-vaapi-driver \
    cuda-toolkit

  step "Compilando módulo akmod (pode demorar alguns minutos...)"
  try sudo akmods --force

  step "Habilitando serviços de energia NVIDIA"
  try sudo systemctl enable nvidia-hibernate nvidia-resume nvidia-suspend

  ok "Driver NVIDIA instalado. Reinicie para ativar."
}

# ─────────────────────────────────────────────
# EXTENSÕES GNOME
# GSConnect mantido — erro é de versão do Shell,
# resolve após atualização para GNOME 50
# ─────────────────────────────────────────────
install_gnome_extensions() {
  info "[EXTENSÕES] Instalando extensões GNOME"

  export PATH="$HOME/.local/bin:$PATH"

  if ! command -v gext &>/dev/null; then
    step "Instalando gnome-extensions-cli via pipx"
    try pipx install gnome-extensions-cli
    export PATH="$HOME/.local/bin:$PATH"
  fi

  EXTENSIONS=(
    appindicatorsupport@rgcjonas.gmail.com   # AppIndicator (bandejas)
    caffeine@patapon.info                     # Caffeine (evitar suspensão)
    dash-to-dock@micxgx.gmail.com            # Dash to Dock
    gsconnect@andyholmes.github.io           # GSConnect (KDE Connect para GNOME)
    tilingshell@ferrarodomenico.com          # Tiling Shell
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
    ok "Extensões instaladas. GSConnect pode mostrar erro até atualização do GNOME Shell para v50."
  else
    warning "gext não disponível. Instale manualmente pelo Extension Manager."
    echo "  Extensões necessárias:"
    printf '    - %s\n' "${EXTENSIONS[@]}"
  fi
}

# ─────────────────────────────────────────────
# REMOÇÃO DE BLOATWARE
# Executada DEPOIS de instalar tudo para não
# quebrar dependências durante a instalação
# ─────────────────────────────────────────────
remove_bloat() {
  info "[LIMPEZA] Removendo bloatware"
  warning "Execute esta etapa DEPOIS de instalar tudo para evitar problemas de dependência."

  step "Removendo LibreOffice (substituído pelo FreeOffice)"
  try sudo dnf remove -y 'libreoffice*'

  step "Removendo apps desnecessários"
  try sudo dnf remove -y \
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

  step "Removendo Flatpaks desnecessários"
  try flatpak uninstall -y \
    org.freedesktop.Piper \
    org.gnome.Help 2>/dev/null || true

  step "Limpando dependências órfãs"
  try sudo dnf autoremove -y

  ok "Limpeza concluída."
}

# ─────────────────────────────────────────────
# CONFIGURAÇÕES VISUAIS
# ─────────────────────────────────────────────
apply_settings() {
  info "[VISUAL] Aplicando configurações GNOME"

  try gsettings set org.gnome.desktop.interface icon-theme       'Papirus'
  try gsettings set org.gnome.desktop.interface color-scheme     'prefer-dark'
  try gsettings set org.gnome.desktop.interface clock-show-date  true
  try gsettings set org.gnome.desktop.interface clock-show-seconds true

  ok "Configurações aplicadas."
}

# ─────────────────────────────────────────────
# VERIFICAÇÃO FINAL
# ─────────────────────────────────────────────
verify_final() {
  info "[VERIFICAÇÃO] Checando estado final do sistema"

  echo
  echo -e "${BOLD}── Pacotes que devem ter sido REMOVIDOS ──${NC}"
  REMOVED_CHECK=$(rpm -qa | grep -E \
    "libreoffice|^totem|totem-video-thumbnailer|gnome-music|^rhythmbox|^cheese|gnome-tour|^mediawriter|gnome-system-monitor|^yelp|^dconf-editor|^htop|^piper" \
    2>/dev/null || true)
  if [[ -z "$REMOVED_CHECK" ]]; then
    ok "Nenhum app indesejado encontrado."
  else
    warning "Ainda presentes:"
    echo "$REMOVED_CHECK"
  fi

  echo
  echo -e "${BOLD}── Pacotes RPM que devem existir ──${NC}"
  rpm -qa | grep -E \
    "google-chrome-stable|brave-browser|firefox|^vlc|audacity|darktable|handbrake|inkscape|easyeffects|^gimp|obs-studio|gnome-software|gnome-extensions-app|papirus|softmaker|freeoffice|^solaar|timeshift|deja-dup" \
    2>/dev/null || warning "Alguns pacotes RPM podem não estar instalados."

  echo
  echo -e "${BOLD}── Flatpaks instalados ──${NC}"
  flatpak list --app --columns=application 2>/dev/null | grep -E \
    "Alpaca|Resources|Flatseal|Blanket|FileShredder|FreeCAD|Upscayl|Shotcut|VideoTrimmer|cameractrls|converseen|dreamchess|Exhibit|Minder|Motrix|Packet|paper.clip|PeaZip|Podcasts|Popsicle|PowerISO|Shortwave|sticky|Converter|BudsLink|Bruno" \
    || warning "Alguns Flatpaks esperados podem não estar instalados."

  echo
  echo -e "${BOLD}── GPU NVIDIA ──${NC}"
  if lspci | grep -qiE "nvidia|geforce|quadro|tesla"; then
    if rpm -q akmod-nvidia &>/dev/null; then
      ok "Driver NVIDIA instalado."
      nvidia-smi 2>/dev/null | head -4 || warning "nvidia-smi não disponível (reinicie para ativar o módulo)."
    else
      warning "GPU NVIDIA detectada mas driver NÃO instalado."
    fi
  else
    ok "Sem GPU NVIDIA (nenhum driver necessário)."
  fi

  echo
  echo -e "${BOLD}── Extensões GNOME ──${NC}"
  if command -v gnome-extensions &>/dev/null; then
    gnome-extensions list --enabled 2>/dev/null || true
  else
    warning "gnome-extensions não disponível."
  fi
}

# ─────────────────────────────────────────────
# EXECUTAR TUDO
# Ordem correta: instalar tudo → remover bloat
# ─────────────────────────────────────────────
run_all() {
  echo
  echo -e "${YELLOW}Isso irá executar todas as etapas na ordem correta.${NC}"
  echo -e "${CYAN}Ordem: repos → update → RPMs → FreeOffice → Flatpaks → NVIDIA → Extensões → Remover bloat → Visual${NC}"
  echo
  read -rp "Confirmar? [s/N]: " CONFIRM
  [[ "${CONFIRM,,}" != "s" ]] && { warning "Cancelado."; return; }

  add_repos
  update_system
  install_rpms        # Instala tudo (incluindo LibreOffice como dep se necessário)
  install_freeoffice  # FreeOffice antes de remover o LibreOffice
  install_flatpaks
  install_nvidia      # Autodetecta — pula se não houver GPU NVIDIA
  install_gnome_extensions
  remove_bloat        # Remove LibreOffice e bloat APÓS instalar tudo
  apply_settings
  verify_final

  echo
  ok "Setup finalizado!"
  echo -e "${YELLOW}⚠ Reinicie o sistema para ativar todos os drivers e configurações.${NC}"
}

# ─────────────────────────────────────────────
# LOOP PRINCIPAL
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
    0) echo "Saindo."; exit 0 ;;
    r|R) echo "Reiniciando..."; sudo reboot ;;
    *) warning "Opção inválida." ;;
  esac

  echo
  read -rp "Pressione ENTER para voltar ao menu..." _
done
