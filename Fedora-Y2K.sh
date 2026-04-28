#!/usr/bin/env bash

# Fedora-Y2K (versão simplificada)
# Menu direto e focado no que você usa

set -e

section() {
  echo
  echo "=============================="
  echo ">> $1"
  echo "=============================="
}

pause() {
  read -rp "Enter para voltar..."
}

# =============================
# FUNÇÕES
# =============================

update_system() {
  section "Atualizando sistema"
  sudo dnf upgrade --refresh -y
}

setup_rpmfusion() {
  section "RPM Fusion"
  sudo dnf install -y \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
}

install_codecs() {
  section "Codecs"
  sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing || true
  sudo dnf install -y ffmpeg vlc gstreamer1-libav
}

install_apps() {
  section "Apps principais (RPM)"

  # Chrome
  sudo dnf config-manager addrepo --from-repofile=https://dl.google.com/linux/chrome/rpm/stable/x86_64/google-chrome.repo || true

  # Brave
  sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo || true
  sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc || true

  sudo dnf install -y \
    google-chrome-stable \
    brave-browser \
    audacity \
    inkscape \
    darktable \
    freecad \
    handbrake \
    gnome-tweaks \
    gnome-extensions-app
}

install_nvidia() {
  section "NVIDIA"
  sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda nvidia-vaapi-driver
}

install_flatpak_apps() {
  section "Flatpak (extras)"
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

  flatpak install -y flathub \
    net.nokyan.Resources \
    com.github.tchx84.Flatseal \
    com.rafaelmardojai.Blanket
}

install_freeoffice() {
  section "FreeOffice"
  sudo dnf install -y curl
  curl -fsSL https://softmaker.net/down/install-softmaker-freeoffice-2024.sh | sudo bash
}

remove_bloat() {
  section "Removendo apps padrão"
  sudo dnf remove -y libreoffice\* gnome-system-monitor cheese totem || true
}

# =============================
# MENU
# =============================

while true; do
  clear
  echo "===== Fedora-Y2K ====="
  echo
  echo "1) Setup completo"
  echo "2) Atualizar sistema"
  echo "3) Instalar codecs"
  echo "4) Instalar apps"
  echo "5) Instalar NVIDIA"
  echo "6) Instalar FreeOffice"
  echo "7) Flatpak extras"
  echo "8) Remover apps padrão"
  echo "0) Sair"
  echo

  read -rp "Escolha: " opt

  case $opt in
    1)
      update_system
      setup_rpmfusion
      install_codecs
      install_apps
      install_nvidia
      install_freeoffice
      install_flatpak_apps
      remove_bloat
      pause
      ;;
    2) update_system; pause ;;
    3) setup_rpmfusion; install_codecs; pause ;;
    4) install_apps; pause ;;
    5) setup_rpmfusion; install_nvidia; pause ;;
    6) install_freeoffice; pause ;;
    7) install_flatpak_apps; pause ;;
    8) remove_bloat; pause ;;
    0) exit ;;
    *) echo "Opção inválida"; sleep 1 ;;
  esac

done

