#!/usr/bin/env bash

set +e

run() {
  "$@"
  if [ $? -ne 0 ]; then
    echo "Aviso: comando falhou, continuando..."
  fi
}

update_system() {
  echo ">> [EFI] Limpando kernels e travando limite em 2"
  run sudo dnf remove $(dnf repoquery --installonly --latest=-1) -y
  run sudo sed -i 's/installonly_limit=3/installonly_limit=2/' /etc/dnf/dnf.conf
  run sudo dnf upgrade --refresh -y
}

remove_bloat() {
  echo ">> [LIMPEZA] Removendo apenas o desnecessário (Mantendo Calendário/Contatos)"
  run sudo dnf remove -y \
    libreoffice\* \
    totem\* \
    gnome-music \
    rhythmbox \
    gnome-tour \
    mediawriter \
    gnome-maps \
    gnome-weather \
    gnome-connections
  
  run sudo dnf autoremove -y
}

install_essentials() {
  echo ">> [RPM] Instalando Base e Suporte Visual"
  run sudo dnf install -y \
    gnome-tweaks gnome-extensions-app papirus-icon-theme \
    ffmpeg ffmpeg-libs libavcodec-freeworld vlc \
    easyeffects git wget curl piper solaar cameractrls
}

install_flatpaks() {
  echo ">> [FLATPAK] Instalando apps dos seus prints (IA, Rede, Util)"
  run flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  
  # Adicionados conforme seus prints: Alpaca, PeaZip, NordVPN, Motrix...
  run flatpak install -y flathub \
    net.nokyan.Resources \
    com.github.tchx84.Flatseal \
    com.rafaelmardojai.Blanket \
    org.upscayl.Upscayl \
    com.github.jeffshee.Alpaca \
    com.motrix.Motrix \
    io.github.peazip.PeaZip \
    com.nordvpn.NordVPN \
    com.mattjakeman.ExtensionManager \
    org.gnome.gitlab.YaLTeR.VideoTrimmer \
    com.github.fabiocolacio.marker \
    com.usebruno.Bruno
}

# Execução do Setup
update_system
remove_bloat
install_essentials
install_flatpaks

# Configurações de Interface (Papirus + Dark Mode)
gsettings set org.gnome.desktop.interface icon-theme 'Papirus'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

echo "===================================================="
echo "Setup Concluído! Calendário e Contatos preservados."
echo "Reinicie para validar drivers e espaço no EFI."
echo "===================================================="
