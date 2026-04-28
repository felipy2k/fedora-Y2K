#!/usr/bin/env bash

set +e

# --- CONFIGURAÇÕES DE SISTEMA ---

update_system() {
  echo ">> Limpando kernels antigos e ajustando limite EFI"
  run sudo dnf remove $(dnf repoquery --installonly --latest=-1) -y
  run sudo sed -i 's/installonly_limit=3/installonly_limit=2/' /etc/dnf/dnf.conf
  run sudo dnf upgrade --refresh -y
}

setup_rpmfusion() {
  echo ">> Configurando RPM Fusion"
  run sudo dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
}

# --- LIMPEZA DE BLOATWARE (SISTEMA LIMPO) ---

remove_bloat() {
  echo ">> Removendo Apps Nativos e Bloatware"
  run sudo dnf remove -y \
    libreoffice\* \
    totem\* \
    gnome-music \
    rhythmbox \
    cheese \
    gnome-tour \
    mediawriter \
    gnome-contacts \
    gnome-maps \
    gnome-weather \
    gnome-clocks \
    gnome-connections \
    gnome-software-plugin-flatpak # Opcional: se preferir gerenciar flatpak via terminal
  
  run sudo dnf autoremove -y
}

# --- INSTALAÇÃO DE APPS (BASEADO NO SEU PERFIL) ---

install_apps() {
  echo ">> Instalando Apps Essenciais e Suporte Visual"
  run sudo dnf install -y \
    gnome-tweaks gnome-extensions-app papirus-icon-theme \
    ffmpeg ffmpeg-libs libavcodec-freeworld \
    vlc easyeffects audacity git wget curl
    
  # Adicionando suporte à NVIDIA se detectada (Útil para o OptiPlex)
  if lspci | grep -qi nvidia; then
    run sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda nvidia-vaapi-driver
  fi
}

install_flatpaks() {
  echo ">> Instalando Flatpaks (Incluindo seus apps dos prints)"
  run flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  
  # Aqui adicionei o Alpaca, Upscayl e Motrix que vi nos seus prints
  run flatpak install -y flathub \
    net.nokyan.Resources \
    com.github.tchx84.Flatseal \
    com.rafaelmardojai.Blanket \
    org.upscayl.Upscayl \
    org.shotcut.Shotcut \
    com.mattjakeman.ExtensionManager \
    com.github.jeffshee.Alpaca \
    com.motrix.Motrix \
    org.gnome.gitlab.YaLTeR.VideoTrimmer
}

# --- EXECUÇÃO ---

run_all() {
  update_system
  setup_rpmfusion
  remove_bloat
  install_apps
  install_flatpaks
  
  # Aplica o tema de ícones que você gosta
  gsettings set org.gnome.desktop.interface icon-theme 'Papirus'
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  
  echo "Finalizado! Reinicie o PC."
}

run_all
