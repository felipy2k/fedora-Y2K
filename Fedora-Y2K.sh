#!/usr/bin/env bash

# Fedora-Y2K
# Pós-instalação Fedora: apps, codecs, FreeOffice, Papirus, Flatpak e NVIDIA automática.

set +e

section() {
  echo
  echo "=============================="
  echo ">> $1"
  echo "=============================="
}

pause() {
  read -rp "Enter para voltar..."
}

run() {
  "$@"
  if [ $? -ne 0 ]; then
    echo "Aviso: comando falhou, continuando..."
  fi
}

update_system() {
  section "Atualizando sistema"
  run sudo dnf upgrade --refresh -y
}

setup_rpmfusion() {
  section "RPM Fusion"
  run sudo dnf install -y \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
}

install_codecs() {
  section "Codecs"
  run sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing

  run sudo dnf install -y \
    ffmpeg \
    vlc \
    gstreamer1-libav \
    gstreamer1-plugins-good \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-ugly
}

install_apps_rpm() {
  section "Apps RPM"

  run sudo dnf install -y dnf-plugins-core curl flatpak

  if [ ! -f /etc/yum.repos.d/google-chrome.repo ]; then
    run sudo dnf config-manager addrepo --from-repofile=https://dl.google.com/linux/chrome/rpm/stable/x86_64/google-chrome.repo
  fi

  if [ ! -f /etc/yum.repos.d/brave-browser.repo ]; then
    run sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
    run sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
  fi

  run sudo dnf install -y \
    google-chrome-stable \
    brave-browser \
    audacity \
    inkscape \
    darktable \
    handbrake \
    gnome-tweaks \
    gnome-extensions-app \
    papirus-icon-theme
}

install_flatpaks() {
  section "Flatpaks"

  run flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

  run flatpak install -y flathub \
    net.nokyan.Resources \
    com.github.tchx84.Flatseal \
    com.rafaelmardojai.Blanket \
    org.freecad.FreeCAD
}

install_freeoffice() {
  section "FreeOffice"
  run sudo dnf install -y curl
  curl -fsSL https://softmaker.net/down/install-softmaker-freeoffice-2024.sh | sudo bash
}

install_nvidia_if_needed() {
  if lspci | grep -qi nvidia; then
    section "NVIDIA detectada"
    run sudo dnf install -y \
      akmod-nvidia \
      xorg-x11-drv-nvidia-cuda \
      nvidia-vaapi-driver
  else
    section "Sem NVIDIA detectada"
  fi
}

remove_bloat() {
  section "Removendo apps padrão"

  run sudo dnf remove -y \
    libreoffice\* \
    gnome-system-monitor \
    cheese \
    totem \
    gnome-tour \
    mediawriter

  run sudo dnf autoremove -y
}

apply_visual() {
  section "Visual GNOME"
  run gsettings set org.gnome.desktop.interface icon-theme 'Papirus'
  run gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
}

full_setup() {
  update_system
  setup_rpmfusion
  install_codecs
  install_apps_rpm
  install_nvidia_if_needed
  install_freeoffice
  install_flatpaks
  remove_bloat
  apply_visual

  section "Finalizado"
  echo "Reinicie o sistema."
}

while true; do
  clear
  echo "===== Fedora-Y2K ====="
  echo
  echo "1) Rodar tudo"
  echo "2) Atualizar sistema"
  echo "0) Sair"
  echo

  read -rp "Escolha: " opt

  case $opt in
    1) full_setup; pause ;;
    2) update_system; pause ;;
    0) exit ;;
    *) echo "Opção inválida"; sleep 1 ;;
  esac
done
