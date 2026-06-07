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

## Ícones faltando em `src/categories/32/`

- [ ] `applications-accessories` (oficial)
- [ ] `applications-audiovideo` (oficial)
- [ ] `applications-development` (oficial)
- [ ] `applications-graphics` (oficial)
- [ ] `applications-internet` (oficial)
- [ ] `applications-office` (oficial)
- [ ] `applications-all` (extensão GNOME Software)
- [ ] `applications-featured` (extensão GNOME Software)
- [ ] `applications-settings` (extensão GNOME Control Center)

## Ícones a criar

> `fallback`: pasta em `links/apps/scalable/` a remover após criar o ícone em `src/`
> `aliases`: symlinks a criar em `links/apps/scalable/<canonical>/`

```yaml
development:
  io.github.fkinoshita.Wildcard:  # regex tester
    fallback: regextester
    aliases:
      - com.felipekinoshita.Wildcard.svg

education:
  org.gramps_project.Gramps:  # genealogy software
    aliases: false
  com.cyberbotics.Webots:  # robotics simulator — atualmente com ícone herdado do bug-buddy
    aliases: false

games:
  org.gnome.Sudoku:
    aliases: false
  org.libretro.RetroArch:  # emulation platform
    fallback: gnome-arcade
    aliases: false
  org.ryujinx.Ryujinx:  # Nintendo Switch emulator
    fallback: yuzu
    aliases: false

graphics:
  io.github.bgrabitmap.LazPaint:
    aliases: false
  org.geeqie.Geeqie:  # image viewer
    fallback: accessories-image-viewer
    aliases:
      - geeqie.svg
  org.gnome.gThumb:
    aliases: false
  mtpaint:
    aliases:
      - com.github.wjaguar.mtpaint.svg
      - com.github.wjaguar.mtPaint.svg
      - mypaint.svg  # MyPaint como fallback até ter ícone próprio
  tuxpaint:
    aliases:
      - org.tuxpaint.Tuxpaint.svg

internet:
  io.gitlab.news_flash.NewsFlash:
    aliases: false
  org.gabmus.gfeeds:
    aliases:
      - org.gabmus.gnome-feeds.svg
  org.nickvision.tubeconverter:  # Tube Converter
    fallback: clip
    aliases: false
  io.github.giantpinkrobots.varia:  # download manager
    fallback: xdman
    aliases: false

media:
  org.gnome.Podcasts:
    fallback: accessories-podcast
    aliases: false
  org.gnome.Pitivi:  # video editor
    fallback: avidemux
    aliases:
      - pitivi.svg
      - org.pitivi.Pitivi.svg
  org.gnome.gitlab.YaLTeR.VideoTrimmer:
    fallback: curlew
    aliases: false
  io.gitlab.adhami3310.Footage:
    fallback: curlew
    aliases: false
  io.github.celluloid_player.Celluloid:  # media player
    fallback: gnome-mpv
    aliases:
      - io.github.celluloid-player.Celluloid.svg
      - io.github.Celluloid.svg
  com.github.ryonakano.reco:  # audio recorder
    fallback: gnome-sound-recorder
    aliases:
      - reco.svg

office:
  org.gnome.gitlab.somas.Apostrophe:  # ex-UberWriter — verificar identidade visual atual
    aliases: false
  evince:  # Document Viewer
    aliases: false
  io.github.diegoivan.pdf_metadata_editor:
    aliases: false
  fbreader:  # ebook reader
    fallback: calibre-gui
    aliases:
      - FBReader.svg

productivity:
  org.gnome.Gnote:  # GNOME notes app
    aliases: false
  com.vixalien.sticky:
    aliases: false
  com.github.lainsce.notejot:
    aliases:
      - io.github.lainsce.Notejot.svg
  errands:  # Substituir ícone do anydo
    aliases: false
  io.github.alainm23.planify:  # Planify task manager
    fallback: planner
    aliases: false
  org.gnome.World.Iotas:  # GNOME notes
    fallback: bookmarks-organize
    aliases:
      - org.gnome.gitlab.cheywood.Iotas.svg
  it.mijorus.collector:
    aliases: false
  com.belmoussaoui.Decoder:
    aliases: false

science:
  qalculate-gtk:  # Qalculate!
    fallback: calculator
    aliases:
      - qalculate.svg
      - qalculate-applet.svg
      - qalculate-qt.svg
      - io.github.Qalculate.qalculate-qt.svg
      - io.github.qalculate.Qalculate.svg
      - io.github.Qalculate.svg

security:
  org.gnome.seahorse.Application:  # Seahorse — gerenciador de senhas/GPG
    aliases:
      - seahorse.svg
      - seahorse-preferences.svg
  keepassx:  # KeePassX/KeePassXC
    aliases:
      - keepassx2.svg
      - keepassxc.svg
      - org.keepassxc.KeePassXC.svg
      - appimagekit-org.keepassxc.KeePassXC.svg

system:
  boxbuddy-rs:  # BoxBuddy — GUI do Distrobox
    aliases: false
  org.gnome.Screenshot:
    fallback: accessories-screenshot
    aliases:
      - gnome-screenshot.svg
      - gnome-panel-screenshot.svg
  org.gnome.Sysprof:  # profiler — fallback atual: jockey.svg (incorreto)
    aliases:
      - org.gnome.Sysprof2.svg
      - org.gnome.Sysprof3.svg
      - sysprof.svg
  org.gnome.World.PikaBackup:  # backup
    fallback: deja-dup
    aliases: false
  io.github.giantpinkrobots.bootqt:  # USB writer
    fallback: gnome-multi-writer
    aliases:
      - bootqt.svg
  plank:  # Plank dock — redesenhar: mudar cor e adicionar âncora
    aliases: false

terminals:
  com.raggesilver.BlackBox:  # terminal
    fallback: maui-station
    aliases: false
```
