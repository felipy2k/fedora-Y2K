# Fedora-Y2K

Script pós-instalação para Fedora, feito para automatizar meu setup pessoal.

## O que faz

- Atualiza o sistema
- Adiciona RPM Fusion
- Adiciona repositórios do Google Chrome e Brave
- Instala codecs multimídia
- Instala apps RPM essenciais
- Instala Flatpaks principais
- Instala FreeOffice
- Detecta NVIDIA e instala driver automaticamente
- Remove apps padrão que não uso
- Aplica tema Papirus e modo escuro
- Faz verificação final

## Apps RPM

- Google Chrome
- Brave
- Firefox
- VLC
- Audacity
- Darktable
- HandBrake
- Inkscape
- EasyEffects
- GNOME Tweaks
- Boxes
- Calendar
- Contacts
- Connections
- Disks
- Text Editor
- Color Manager
- Papirus Icon Theme

## Flatpaks

- Resources
- Flatseal
- Blanket
- FreeCAD
- Upscayl
- Shotcut
- File Shredder

## Remove

- LibreOffice
- Totem / Reprodutor de Vídeo
- GNOME Music / Rhythmbox
- Cheese
- GNOME Software
- GNOME Extensions App
- Brasero
- GNOME Tour
- Media Writer
- GNOME System Monitor
- Yelp / Ajuda
- dconf-editor
- htop
- piper

## Menu

```text
1) Executar TUDO
2) Apenas atualizar sistema
3) Apenas remover bloatware
4) Apenas instalar pacotes RPM
5) Apenas instalar Flatpaks
6) Apenas instalar driver NVIDIA
7) Apenas aplicar configurações visuais
8) Verificação final
0) Sair

Como usar:
git clone https://github.com/felipy2k/fedora-Y2K.git
cd fedora-Y2K
bash Fedora-Y2K.sh

Observações:
Não rode como root.
O script pede sudo quando necessário.
Requer internet.
Reinicie o sistema após rodar tudo

