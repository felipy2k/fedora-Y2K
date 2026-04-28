
#!/usr/bin/env bash

# Fedora-Y2K
# Pós-instalação Fedora com apps, codecs, FreeOffice, Papirus e detecção automática de NVIDIA.

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
  sudo dnf install -y \
    ffmpeg \
    vlc \
    gstreamer1-libav \
    gstreamer1-plugins-good \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-ugly
}

install_apps() {
  section "Apps principais RPM"

  sudo dnf install -y dnf-plugins-core curl

  # Google Chrome
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
    gnome-extensions-app \
    papirus-icon-theme
}

install_nvidia_if_needed() {
  if lspci | grep -qi nvidia; then
    section "NVIDIA detectada - instalando driver"
    sudo dnf install -y \
      akmod-nvidia \
      xorg-x11-drv-nvidia-cuda \
      nvidia-vaapi-driver
  else
    section "Sem NVIDIA - pulando driver NVIDIA"
  fi
}

install_flatpak_apps() {
  section "Flatpak extras"

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
  sudo dnf remove -y \
    libreoffice\* \
    gnome-system-monitor \
    cheese \
    totem || true
}

apply_visual() {
  section "Visual GNOME"
  gsettings set org.gnome.desktop.interface icon-theme 'Papirus' || true
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
}

full_setup() {
  update_system
  setup_rpmfusion
  install_codecs
  install_apps
  install_nvidia_if_needed
  install_freeoffice
  install_flatpak_apps
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
