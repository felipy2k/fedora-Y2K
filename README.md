# 🎩 Fedora Setup — Script de Pós-Instalação

Script interativo de pós-instalação para **Fedora Workstation 41+** (testado no Fedora 44 com GNOME 50).  
Automatiza repositórios, codecs, drivers, apps RPM, Flatpaks, extensões GNOME e configurações visuais — tudo com menu e execução modular.

---

## ✨ O que o script faz

### 📦 Repositórios
- RPM Fusion Free + Nonfree (com AppStream metadata para GNOME Software)
- RPM Fusion Tainted (firmware e codecs extras)
- `fedora-cisco-openh264` (H.264 para Firefox e WebRTC)
- Google Chrome
- Brave Browser

### 🎬 Codecs de Mídia
- Troca `ffmpeg-free` pelo `ffmpeg` completo (H.264, H.265, AAC, MP3, etc.)
- `dnf group upgrade multimedia` + `sound-and-video` (método oficial)
- GStreamer completo: `libav`, `ugly`, `bad-freeworld`, `openh264`
- Aceleração de hardware VA-API/VDPAU autodetectada por GPU:
  - **AMD** → `mesa-va-drivers-freeworld` + `mesa-vdpau-drivers-freeworld`
  - **Intel** → `intel-media-driver` + `libva-intel-driver`

### 🖥️ Driver NVIDIA + CUDA
- Autodetecção de GPU (filtra apenas dispositivos VGA/3D/Display)
- Aviso e confirmação se **Secure Boot** estiver ativo
- Instala via RPM Fusion: `akmod-nvidia`, `xorg-x11-drv-nvidia-cuda`, `nvidia-settings`, `nvidia-vaapi-driver`
- Compila o módulo com `akmods --force` e regenera o initramfs com `dracut --force`
- Habilita serviços de energia (`nvidia-hibernate`, `nvidia-resume`, `nvidia-suspend`)
- Pergunta interativamente se deseja o **CUDA Toolkit completo** (nvcc, cuBLAS, headers) via repo oficial da NVIDIA, com exclusão dos pacotes que conflitam com o RPM Fusion

### 📥 Pacotes RPM instalados

| Categoria | Apps |
|---|---|
| Navegadores | Firefox, Google Chrome, Brave, Tor Browser |
| Multimídia | VLC, Audacity, Darktable, Handbrake, EasyEffects, OBS Studio |
| Gráficos | GIMP, Inkscape |
| GNOME Apps | Tweaks, Baobab, Déjà Dup, Boxes, Calculator, Calendar, Snapshot, Characters, Connections, Contacts, Simple Scan, Disk Utility, Text Editor, Font Viewer, Color Manager, Software, Clocks, Logs, Evince, Loupe |
| Utilitários | Timeshift, Solaar, fastfetch, pipx |
| Office | FreeOffice 2024 (instalador oficial) |

### 📱 Flatpaks (Flathub)

| Categoria | Apps |
|---|---|
| Sistema | Extension Manager, Resources, Flatseal, PeaZip, Popsicle, File Shredder (Raider), LocalSend, Paper Clip, Switcheroo |
| Multimídia | Shotcut, Video Trimmer, Camera Ctrls, Converseen |
| Produtividade | FreeCAD, Upscayl, Exhibit (3D Viewer), Minder, Motrix |
| Entretenimento | DreamChess, Blanket, Shortwave, Podcasts, Gcolor3, Sticky Notes, Alpaca |

### 🧩 Extensões GNOME (via `gnome-extensions-cli`)
- AppIndicator Support
- Caffeine
- Dash to Dock
- GSConnect (KDE Connect para GNOME)
- Tiling Shell

### 🧹 Bloatware removido

| Tipo | O que é removido |
|---|---|
| Office | LibreOffice (substituído pelo FreeOffice) |
| Vídeo | Showtime, Totem, totem-video-thumbnailer |
| Áudio | Decibels, GNOME Music, Rhythmbox |
| Terminal | GNOME Terminal (mantém **Ptyxis**, padrão do Fedora 41+) |
| Extensões RPM | gnome-extensions-app (substituído pelo Extension Manager Flatpak) |
| Outros | Cheese, GNOME Tour, Mediawriter, GNOME System Monitor, Meteorologia, Mapas, Yelp, dconf-editor, htop, Piper, JACK |
| Flatpaks | Showtime, Decibels, Totem, GNOME Music, Piper, GNOME Help, Bruno |

### 🎨 Configurações visuais
- Tema de ícones: **Papirus**
- Esquema de cores: **Modo escuro**
- Relógio com data e segundos visíveis
- Wallpaper da NASA aplicado automaticamente

---

## 🚀 Como usar

```bash
# Clone o repositório
git clone https://github.com/SEU_USUARIO/fedora-setup.git
cd fedora-setup

# Dê permissão de execução
chmod +x fedora-setup.sh

# Execute como usuário normal (NÃO como root)
./fedora-setup.sh
```

> ⚠️ **Não rode como root.** O script usa `sudo` internamente onde necessário.

---

## 🗂️ Menu de opções

```
╔═══════════════════════════════════════════════════════════════╗
║              Fedora — Setup Personalizado                     ║
╠═══════════════════════════════════════════════════════════════╣
║  [1] Executar TUDO (recomendado)                             ║
║  [2] Apenas atualizar sistema                                ║
║  [3] Apenas remover bloatware                                ║
║  [4] Apenas instalar pacotes RPM                             ║
║  [5] Apenas instalar Flatpaks                                ║
║  [6] Apenas instalar driver NVIDIA + CUDA                    ║
║  [7] Apenas instalar extensões GNOME                         ║
║  [8] Apenas aplicar configurações visuais                    ║
║  [9] Verificação final                                       ║
║  [0] Sair                                                    ║
║  [r] Sair e reiniciar o sistema                              ║
╚═══════════════════════════════════════════════════════════════╝
```

Cada etapa pode ser executada individualmente. A opção `[1] Executar TUDO` garante a **ordem correta**: instala tudo primeiro, remove o bloatware depois — evitando quebra de dependências.

---

## ⚙️ Requisitos

- Fedora Workstation **41 ou superior** (otimizado para Fedora 44 + GNOME 50)
- Conexão com a internet
- Usuário com acesso `sudo`

---

## 📝 Notas importantes

**NVIDIA + Secure Boot**  
Se o Secure Boot estiver ativo, o script avisa e pede confirmação antes de instalar. Após a instalação, o módulo `akmod` precisa ser assinado manualmente. Consulte o guia: [RPM Fusion — Secure Boot](https://rpmfusion.org/Howto/Secure%20Boot)

**CUDA Toolkit**  
O driver instalado via RPM Fusion já inclui suporte a CUDA para aplicativos (Blender, OBS, etc.). O CUDA Toolkit completo (com `nvcc`, cuBLAS e headers) é opcional e instalado via repositório oficial da NVIDIA mediante confirmação interativa.

**FreeOffice**  
Instalado via script oficial da SoftMaker antes da remoção do LibreOffice, garantindo que nunca haja um momento sem suite de escritório disponível.

**Controle Parental (malcontent)**  
O pacote base `malcontent` é dependência do `gnome-control-center` e não pode ser removido sem quebrar o GNOME. O script não toca nele.

**Falhas não bloqueiam**  
O script usa a função `try()` — se um passo falhar (ex.: pacote já instalado, ou não disponível), ele registra o aviso e continua. Nenhum erro aborta o processo inteiro.

---

## 📋 Verificação final

A opção `[9]` roda uma checagem completa do sistema e reporta:
- Pacotes indesejados ainda presentes
- Pacotes RPM esperados instalados
- Status dos codecs (ffmpeg completo vs. ffmpeg-free)
- Flatpaks instalados
- Status do driver NVIDIA e CUDA
- Extensões GNOME ativas

---

## 📄 Licença

MIT — use, modifique e distribua à vontade.

Como usar:
git clone https://github.com/felipy2k/fedora-Y2K.git
cd fedora-Y2K
bash Fedora-Y2K.sh

Observações:
Não rode como root.
O script pede sudo quando necessário.
Requer internet.
Reinicie o sistema após rodar tudo

