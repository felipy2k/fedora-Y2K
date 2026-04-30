# 🎩 Fedora — Setup Personalizado

Script interativo de pós-instalação para Fedora com menu em português. Instala aplicativos, codecs, drivers NVIDIA, extensões GNOME, remove bloatware e aplica configurações visuais — tudo em uma única execução.

---

## ⚡ Como usar

```bash
chmod +x fedora-setup.sh
./fedora-setup.sh
```

> ⚠️ **Não rode como root.** O script pede `sudo` apenas quando necessário.

---

## 🗂️ Menu de opções

```
╔═══════════════════════════════════════════════════════════════╗
║              Fedora — Setup Personalizado                     ║
║           Usuário: seunome                                    ║
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

A opção **[1] Executar TUDO** segue a ordem correta:

```
repos → atualização → RPMs → FreeOffice → Flatpaks → NVIDIA → Extensões → remover bloat → visual → verificação
```

> O bloatware é removido **sempre por último**, após todas as instalações, para evitar quebrar dependências.

---

## 📦 O que é instalado

### Repositórios
- **RPM Fusion** (free + nonfree)
- **Google Chrome** (repositório oficial)
- **Brave Browser** (repositório oficial)

### Codecs e multimídia
- ffmpeg completo (com swap do ffmpeg-free)
- libavcodec-freeworld, lame
- GStreamer plugins (base, good, bad, ugly, openh264)

### Aplicativos RPM

| Categoria | Aplicativos |
|-----------|-------------|
| **Navegadores** | Google Chrome, Brave, Firefox, Tor Browser |
| **Multimídia** | VLC, Audacity, darktable, HandBrake, EasyEffects, OBS Studio |
| **Gráficos** | GIMP, Inkscape |
| **GNOME Apps** | Tweaks, Baobab, Nautilus, Déjà Dup, Boxes, Calculadora, Calendário, Câmera (Snapshot), Caracteres, Relato de Problemas, Conexões, Contatos, Digitalizador, Discos, Editor de Texto, Fontes, Perfil de Cor, Gestor de Extensões, Software, Relógios, Registros, Terminal, Evince, Loupe |
| **Utilitários** | Timeshift, Solaar |

### FreeOffice 2024
Instalado via instalador oficial da SoftMaker, substituindo o LibreOffice:
```bash
curl -fsSL https://softmaker.net/down/install-softmaker-freeoffice-2024.sh | sudo bash
```

### Flatpaks (Flathub)

| Categoria | App | Descrição |
|-----------|-----|-----------|
| **Sistema** | Extension Manager | Gestor de extensões GNOME |
| | Resources | Monitor de recursos |
| | Flatseal | Gerenciador de permissões Flatpak |
| | PeaZip | Compactador de arquivos |
| | Popsicle | Gravador de USB |
| | PowerISO | Gerenciador de ISOs |
| | File Shredder | Destruidor seguro de arquivos |
| | Packet | Analisador de rede |
| | Paper Clip | Editor de metadados PDF |
| | Converter (Switcheroo) | Conversor de imagens |
| **Multimídia** | Shotcut | Editor de vídeo |
| | Video Trimmer | Aparador de vídeo |
| | Cameractrls | Controles de câmera |
| | Converseen | Conversor de imagens em lote |
| **Produtividade** | FreeCAD | Modelagem CAD 3D |
| | Upscayl | Upscale de imagens com IA |
| | Exhibit | Visualizador de modelos 3D |
| | Minder | Mapas mentais |
| | Motrix | Gerenciador de downloads |
| **Entretenimento** | DreamChess | Xadrez 3D |
| | Blanket | Sons ambiente |
| | Shortwave | Rádio online |
| | Podcasts | Podcasts |
| **Outros** | BudsLink | Controle de Galaxy Buds |
| | Seletor de cor | Captura de cores da tela |
| | Sticky Notes | Notas adesivas |
| | Alpaca | Interface local para LLMs (Ollama) |

### Driver NVIDIA (autodetectado)
O script detecta automaticamente se há GPU NVIDIA via `lspci`. Se encontrada, instala:
- `akmod-nvidia` — driver via DKMS
- `xorg-x11-drv-nvidia` e variantes
- `nvidia-vaapi-driver` — aceleração de vídeo
- `cuda-toolkit`
- Habilita serviços: `nvidia-hibernate`, `nvidia-resume`, `nvidia-suspend`

> Se não houver GPU NVIDIA, esta etapa é pulada automaticamente.

### Extensões GNOME

| Extensão | ID |
|----------|----|
| AppIndicator & KStatusNotifierItem Support | `appindicatorsupport@rgcjonas.gmail.com` |
| Caffeine | `caffeine@patapon.info` |
| Dash to Dock | `dash-to-dock@micxgx.gmail.com` |
| GSConnect | `gsconnect@andyholmes.github.io` |
| Tiling Shell | `tilingshell@ferrarodomenico.com` |

> ⚠️ **GSConnect** pode aparecer com erro até a atualização para GNOME 50 — é esperado.

Instaladas via `gnome-extensions-cli` (pipx).

---

## 🗑️ O que é removido (bloatware)

### RPM
| Pacote | Motivo |
|--------|--------|
| `libreoffice*` | Substituído pelo FreeOffice |
| `totem` / `totem-video-thumbnailer` | Substituído pelo VLC |
| `gnome-music` / `rhythmbox` | Substituídos pelo VLC |
| `cheese` | Substituído pelo Snapshot |
| `gnome-weather` | Não utilizado |
| `gnome-maps` | Não utilizado |
| `gnome-tour` | Não utilizado |
| `mediawriter` | Substituído pelo Popsicle |
| `gnome-system-monitor` | Substituído pelo Resources |
| `yelp` | Documentação offline desnecessária |
| `dconf-editor` | Não utilizado |
| `htop` | Substituído pelo Resources |
| `piper` | Substituído pelo Solaar |
| `jack-audio-connection-kit*` / `qjackctl` | Não utilizado |

### Flatpak
| App | ID |
|-----|----|
| Piper | `org.freedesktop.Piper` |
| Ajuda GNOME | `org.gnome.Help` |
| Reprodutor de Vídeo | `org.gnome.Showtime` |
| Leitor de Áudio | `org.gnome.Decibels` |
| Bruno | `com.usebruno.Bruno` |

---

## 🎨 Configurações visuais aplicadas

| Configuração | Valor |
|-------------|-------|
| Tema de ícones | Papirus |
| Esquema de cores | Modo escuro |
| Relógio — mostrar data | Sim |
| Relógio — mostrar segundos | Sim |
| Papel de parede | Foto da NASA (ISS) — aplicada em modo claro e escuro |

O wallpaper é baixado automaticamente da NASA e salvo em `~/Pictures/nasa-wallpaper.jpg`.

---

## ✅ Verificação final

A opção **[9]** executa uma checagem completa do sistema e reporta:
- Pacotes indesejados que ainda estejam presentes
- Pacotes RPM esperados instalados
- Flatpaks esperados instalados
- Status do driver NVIDIA
- Extensões GNOME ativas

---

## 📋 Requisitos

- Fedora (qualquer versão recente)
- Conexão com a internet
- Usuário com permissão `sudo`

---

## 📝 Notas

- O script **não para em caso de erros** — falhas individuais são registradas e a execução continua
- A remoção de bloatware ocorre **sempre após** todas as instalações para não quebrar dependências
- Após a instalação do driver NVIDIA, é necessário **reiniciar** para ativar o módulo do kernel
- O GSConnect ficará com erro de compatibilidade até o GNOME Shell ser atualizado para a versão 50

Como usar:
git clone https://github.com/felipy2k/fedora-Y2K.git
cd fedora-Y2K
bash Fedora-Y2K.sh

Observações:
Não rode como root.
O script pede sudo quando necessário.
Requer internet.
Reinicie o sistema após rodar tudo

