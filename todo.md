# Nowa Glyphs — Todo

## Em andamento

Auditando as pastas de `src/apps/scalable/` **em ordem alfabética** para remover ícones de outras
DEs, apps abandonados, Chrome hash IDs e ícones genéricos sem app real associado.

Pastas analisadas:
- [x] browsers
- [x] communication
- [x] databases
- [x] desktop-environments
- [x] development
- [x] distributors
- [x] education
- [x] finance
- [x] games
- [x] gnome-core
- [x] graphics
- [x] internet
- [x] media
- [x] office
- [x] preferences
- [x] productivity
- [x] science
- [x] security
- [x] system
- [x] terminals
- [x] wine

## Organizar `src/actions/symbolic/` em categorias

- [x] Categorização concluída — 1.186 ícones organizados em 17 subpastas

### Subpastas criadas

| Pasta | Ícones | Descrição |
|---|---:|---|
| `de-budgie/` | 11 | `budgie-*`, `shuffler-*` |
| `de-cinnamon/` | 12 | `cinnamon-*`, `nemo-*` |
| `maps/` | 107 | POIs de mapa (bank, bar, hospital, route-transit-*, etc.) |
| `system/` | 47 | `am-*` (hardware monitor) + ações de sistema (hibernate, shutdown, etc.) |
| `drawing/` | 405 | Ferramentas Inkscape (align, path, node, layer, paint, etc.) |
| `typography/` | 59 | `format-text-*`, `font-*`, `glyph-*`, `text-*`, bold, italic, etc. |
| `development/` | 65 | `builder-*`, `lang-*`, `debug-*`, `xml-*`, vcs, etc. |
| `calendar/` | 15 | Alarmes, lembretes, compromissos, aniversários |
| `communication/` | 42 | Mail, chat, chamadas, contatos, mensagens |
| `media/` | 36 | Áudio/vídeo (play, pause, volume, screencast, etc.) |
| `security/` | 21 | `permissions-*`, `app-safety-*`, `auditable-code`, etc. |
| `parental-control/` | 14 | Controle parental (cigarette, drug-use, gambling, nudity, violence, etc.) |
| `filesystem/` | 34 | Arquivos, pastas, documentos, impressão |
| `apps/` | 12 | Gestão de aplicativos (instalar, remover, flatpak, snap, etc.) |
| `internet/` | 17 | `ephy-*` (GNOME Web) + ícones web (globe, webpage, etc.) |
| `3rd-apps/` | 9 | Ícones privados de apps específicos (twitter, dino, dconf-editor, brisk-menu) |
| `ui/` | 280 | Catch-all: ações genéricas de interface (view-*, window-*, go-*, edit-*, etc.) |

## Ícones a criar

- Add `org.gnome.gitlab.somas.Apostrophe.svg` (ex-UberWriter, ícone novo — verificar identidade visual atual)
- Add `io.github.alainm23.planify.svg` icon (Planify, task manager)
- Add `org.gnome.Gnote.svg` icon (Gnote, GNOME notes app)
- Add `com.cyberbotics.Webots.svg` icon (Webots, robotics simulator) — atualmente usando ícone herdado do bug-buddy
- Add `plank.svg` icon (Plank dock) — redesenhar: mudar cor e adicionar âncora ao ícone
- Add `boxbuddy-rs.svg` icon (BoxBuddy, GUI do Distrobox)
- Add `tuxpaint.svg`
- Add `com.belmoussaoui.Decoder.svg`
- Add `io.github.diegoivan.pdf_metadata_editor.svg`
- Add `it.mijorus.collector.svg`
- Add `mtpaint.svg` (aliases: `com.github.wjaguar.mtpaint.svg`, `com.github.wjaguar.mtPaint.svg`, `mypaint.svg`)
- Add `io.github.bgrabitmap.LazPaint.svg`
- Add `evince.svg`
- Add `io.gitlab.news_flash.NewsFlash.svg`
- Add `org.gabmus.gfeeds.svg` / `org.gabmus.gnome-feeds.svg`
- Add `com.vixalien.sticky.svg`
- Add `com.github.lainsce.notejot.svg` / `io.github.lainsce.Notejot.svg`
- Add `org.gnome.Sudoku.svg`
- Add `org.gnome.gThumb.svg`
- Add `seahorse.svg` / `org.gnome.seahorse.Application.svg` (Seahorse — gerenciador de senhas e chaves GPG do GNOME; atualmente usando fallback genérico `keyring-manager.svg`)
- Add `org.gnome.Sysprof.svg` / `org.gnome.Sysprof2.svg` (GNOME Sysprof — profiler; atualmente usando fallback incorreto `jockey.svg`)
- Add `keepassx.svg` + `keepassx2.svg` (KeePassX/KeePassXC — atualmente usando fallback do seahorse)
- Replace "anydo" -> "Errands" icon

## Ícones a criar + remover fallback em links/

> Após criar o ícone em `src/`, remover o symlink correspondente de `links/apps/scalable/`

- Add `org.gnome.Podcasts.svg` (GNOME Podcasts; fallback: `links/apps/scalable/accessories-podcast/`)
- Add `geeqie.svg` / `org.geeqie.Geeqie.svg` (Geeqie — visualizador de imagens; fallback: `links/apps/scalable/accessories-image-viewer/`)
- Add `org.gnome.Screenshot.svg` / `gnome-screenshot.svg` (GNOME Screenshot; fallback: `links/apps/scalable/accessories-screenshot/`)
- Add `org.gnome.Pitivi.svg` / `pitivi.svg` (Pitivi — editor de vídeo GNOME; fallback: `links/apps/scalable/avidemux/`)
- Add `org.gnome.World.Iotas.svg` (Iotas — notas GNOME; fallback: `links/apps/scalable/bookmarks-organize/`)
- Add `qalculate-gtk.svg` / `qalculate.svg` (Qalculate!; fallback: `links/apps/scalable/calculator/`)
- Add `fbreader.svg` / `FBReader.svg` (FBReader — leitor de ebook; fallback: `links/apps/scalable/calibre-gui/`)
- Add `org.gnome.World.PikaBackup.svg` (Pika Backup; fallback: `links/apps/scalable/deja-dup/`)
- Add `org.nickvision.tubeconverter.svg` (Tube Converter; fallback: `links/apps/scalable/clip/`)
- Add `org.gnome.gitlab.YaLTeR.VideoTrimmer.svg` (Video Trimmer; fallback: `links/apps/scalable/curlew/`)
- Add `io.gitlab.adhami3310.Footage.svg` (Footage; fallback: `links/apps/scalable/curlew/`)
- Add `io.github.celluloid_player.Celluloid.svg` (Celluloid — media player GNOME; fallback: `links/apps/scalable/gnome-mpv/`)
- Add `org.libretro.RetroArch.svg` (RetroArch — plataforma de emulação; fallback: `links/apps/scalable/gnome-arcade/`)
- Add `com.github.ryonakano.reco.svg` (Reco — gravador de áudio GNOME; fallback: `links/apps/scalable/gnome-sound-recorder/`)
- Add `io.github.giantpinkrobots.bootqt.svg` (BootQt — gravador de USB; fallback: `links/apps/scalable/gnome-multi-writer/`)
- Add `com.raggesilver.BlackBox.svg` (BlackBox — terminal GNOME; fallback: `links/apps/scalable/maui-station/`)
- Add `io.github.fkinoshita.Wildcard.svg` (Wildcard — regex tester GNOME; fallback: `links/apps/scalable/regextester/`)
- Add `io.github.giantpinkrobots.varia.svg` (Varia — download manager GNOME; fallback: `links/apps/scalable/xdman/`)
- Add `org.ryujinx.Ryujinx.svg` (Ryujinx — emulador Nintendo Switch; fallback: `links/apps/scalable/yuzu/`)
