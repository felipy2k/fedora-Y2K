#!/usr/bin/env bash

# Fedora Felipe Post-Install
# Menu interativo para pós-instalação do Fedora.
# Rodar com:
#   bash fedora-felipe-postinstall.sh

set -Eeuo pipefail

LOG_FILE="$HOME/fedora-felipe-postinstall.log"
exec > >(tee -a "$LOG_FILE") 2>&1

trap 'echo "\nERRO: falhou na linha $LINENO. Veja o log em: $LOG_FILE"' ERR

FEDORA_VERSION="$(rpm -E %fedora)"

section() {
  echo
  echo "============================================================"
  echo ">> $1"
  echo "============================================================"
}

pause() {
  echo
  read -rp "Pressione Enter para voltar ao menu..."
}

install_dnf() {
  sudo dnf install -y "$@" || true
}

remove_dnf() {
  sudo dnf remove -y "$@" || true
}

install_flatpak() {
  flatpak install -y flathub "$@" || true
}

update_system() {
  section "Atualizar sistema"
  sudo dnf upgrade --refresh -y
}

install_base_tools() {
  section "Ferramentas básicas"
  install_dnf \
    dnf-plugins-core \
    curl \
    wget \
    git \
    unzip \
    p7zip \
    p7zip-plugins \
    nano \
    vim \
    htop \
    fastfetch \
    usbutils \
    pciutils \
    lshw \
    lm_sensors \
    gnome-tweaks \
    gnome-extensions-app \
    flatpak
}

setup_rpmfusion() {
  section "Ativar RPM Fusion Free e Nonfree"
  sudo dnf install -y \
    "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm" \
    "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm" || true

  sudo dnf group upgrade -y core || true
}

install_codecs() {
  section "Codecs e multimídia"
  setup_rpmfusion

  sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing || true

  install_dnf \
    ffmpeg \
    ffmpeg-libs \
    libavcodec-freeworld \
    gstreamer1-libav \
    gstreamer1-plugins-base \
    gstreamer1-plugins-good \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-ugly \
    lame \
    vlc \
    handbrake
}

install_chrome() {
  section "Google Chrome RPM oficial"
  sudo dnf config-manager addrepo --from-repofile=https://dl.google.com/linux/chrome/rpm/stable/x86_64/google-chrome.repo || true
  install_dnf google-chrome-stable
}

install_brave() {
  section "Brave RPM oficial"
  install_dnf dnf-plugins-core
  sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo || true
  sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc || true
  install_dnf brave-browser
}

install_apps_rpm() {
  section "Apps RPM principais"
  install_chrome
  install_brave

  install_dnf \
    audacity \
    brasero \
    darktable \
    easyeffects \
    eog \
    evince \
    file-roller \
    freecad \
    gnome-boxes \
    gnome-calendar \
    gnome-characters \
    gnome-connections \
    gnome-contacts \
    gnome-disk-utility \
    gnome-font-viewer \
    gnome-text-editor \
    gnome-color-manager \
    inkscape \
    simple-scan \
    torbrowser-launcher
}

setup_flathub() {
  section "Ativar Flathub"
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

install_apps_flatpak() {
  section "Apps Flatpak selecionados"
  setup_flathub

  install_flatpak \
    com.github.tchx84.Flatseal \
    net.nokyan.Resources \
    com.rafaelmardojai.Blanket \
    org.gnome.gitlab.YaLTeR.VideoTrimmer
}

install_nvidia() {
  section "Driver NVIDIA via RPM Fusion"
  setup_rpmfusion

  if lspci | grep -qi nvidia; then
    echo "GPU NVIDIA detectada. Instalando driver."
    install_dnf \
      akmod-nvidia \
      xorg-x11-drv-nvidia-cuda \
      xorg-x11-drv-nvidia-power \
      nvidia-vaapi-driver

    echo
    echo "IMPORTANTE: depois de instalar, reinicie."
    echo "Na primeira reinicialização, o akmod pode demorar alguns minutos para compilar."
  else
    echo "Nenhuma GPU NVIDIA detectada. Pulando."
  fi
}

install_intel_media() {
  section "Intel media / VAAPI"
  install_dnf \
    intel-media-driver \
    libva \
    libva-utils \
    mesa-va-drivers \
    mesa-vdpau-drivers
}

install_gnome_extensions() {
  section "Extensões GNOME"
  install_dnf \
    gnome-extensions-app \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-caffeine

  echo
  echo "Extensões instaladas via RPM quando disponíveis."
  echo "GSConnect e Tiling Shell normalmente são melhores pelo site extensions.gnome.org ou Extension Manager."
  echo "Depois abra: Extensões"
}

remove_fedora_apps() {
  section "Remover apps Fedora que você costuma trocar"
  remove_dnf \
    libreoffice\* \
    gnome-system-monitor \
    rhythmbox \
    cheese \
    totem \
    mediawriter \
    gnome-tour \
    yelp
}

apply_gnome_tweaks() {
  section "Ajustes GNOME"
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
  gsettings set org.gnome.desktop.interface enable-hot-corners false || true
  gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']" || true
}

freeoffice_note() {
  section "FreeOffice"
  echo "Instalação automática não incluída por padrão."
  echo "Baixe o RPM oficial da SoftMaker e rode:"
  echo "sudo dnf install ./softmaker-freeoffice-*.x86_64.rpm"
}

epson_note() {
  section "Epson"
  echo "Instalação automática não incluída por padrão."
  echo "Depois de baixar os RPMs Epson, rode na pasta Downloads:"
  echo "sudo dnf install ./epson-*.rpm --nogpgcheck"
}

cleanup_system() {
  section "Limpeza"
  flatpak uninstall --unused -y || true
  sudo dnf autoremove -y || true
  sudo dnf clean all || true
}

run_full_setup() {
  update_system
  install_base_tools
  setup_rpmfusion
  install_codecs
  install_apps_rpm
  install_apps_flatpak
  install_nvidia
  install_intel_media
  install_gnome_extensions
  remove_fedora_apps
  apply_gnome_tweaks
  freeoffice_note
  epson_note
  cleanup_system

  section "Finalizado"
  echo "Reinicie o sistema."
  echo "Log salvo em: $LOG_FILE"
}

show_menu() {
  clear
  echo "============================================================"
  echo " Fedora Felipe Post-Install"
  echo "============================================================"
  echo "Fedora: $FEDORA_VERSION"
  echo "Log: $LOG_FILE"
  echo
  echo "1) Rodar setup completo"
  echo "2) Atualizar sistema"
  echo "3) Instalar ferramentas básicas"
  echo "4) Ativar RPM Fusion"
  echo "5) Instalar codecs e multimídia"
  echo "6) Instalar apps RPM"
  echo "7) Instalar apps Flatpak selecionados"
  echo "8) Instalar driver NVIDIA"
  echo "9) Instalar Intel media / VAAPI"
  echo "10) Instalar extensões GNOME"
  echo "11) Remover apps Fedora que você não usa"
  echo "12) Aplicar ajustes GNOME"
  echo "13) Limpeza"
  echo "14) Notas FreeOffice"
  echo "15) Notas Epson"
  echo "0) Sair"
  echo
}

main_menu() {
  while true; do
    show_menu
    read -rp "Escolha uma opção: " option

    case "$option" in
      1) run_full_setup; pause ;;
      2) update_system; pause ;;
      3) install_base_tools; pause ;;
      4) setup_rpmfusion; pause ;;
      5) install_codecs; pause ;;
      6) install_apps_rpm; pause ;;
      7) install_apps_flatpak; pause ;;
      8) install_nvidia; pause ;;
      9) install_intel_media; pause ;;
      10) install_gnome_extensions; pause ;;
      11) remove_fedora_apps; pause ;;
      12) apply_gnome_tweaks; pause ;;
      13) cleanup_system; pause ;;
      14) freeoffice_note; pause ;;
      15) epson_note; pause ;;
      0) echo "Saindo."; exit 0 ;;
      *) echo "Opção inválida."; sleep 1 ;;
    esac
  done
}

main_menu
