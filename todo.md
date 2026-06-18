# Nowa Glyphs — Todo

## Em andamento

## Ícones a criar

> `fallback`: pasta em `links/apps/scalable/` a remover após criar o ícone em `src/`
> `aliases`: symlinks a criar em `links/apps/scalable/<canonical>/`

```yaml
development:
  com.github.git_cola.git-cola:  # git GUI
    aliases: false
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
  info.febvre.Komikku:  # manga/comics reader
    aliases: false
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
  org.gnome.Geary:  # email client
    aliases: false
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
  com.oppzippy.OpenSCQ30:  # Sony/JBL headphone EQ control
    aliases:
      - openscq30_gui.svg
  io.gitlab.daikhan.player:  # media player
    aliases:
      - daikhan.svg
      - io.gitlab.daikhan.stable.svg
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
  asunder:  # CD ripper
    aliases: false

office:
  texstudio:  # redesenhar ícone
    aliases: false
  org.tug.texworks.TeXworks:
    aliases:
      - TeXworks.svg
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
    aliases:
      - org.gnome.gitlab.cheywood.Iotas.svg
      - org.gnome.World.Iotas.svg
  it.mijorus.collector:
    aliases: false
  com.belmoussaoui.Decoder:
    aliases: false

science:
  org.speedcrunch.SpeedCrunch:
    aliases: false
  io.github.Qalculate:  # Qalculate!
    aliases:
      - qalculate-gtk.svg
      - qalculate.svg
      - qalculate-applet.svg
      - qalculate-qt.svg
      - qalculate-kde.svg
      - qalculator.svg
      - io.github.Qalculate.qalculate-qt.svg
      - io.github.qalculate.Qalculate.svg

security:
  com.onepassword.OnePassword:
    aliases:
      - appimagekit-1password.svg
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
  org.freefilesync.FreeFileSync:  # file sync — aproveitar estilo do ícone reload
    aliases:
      - FreeFileSync.svg
  io.github.vinser.burnfix:  # screen burn-in fix tool
    aliases:
      - burnfix.svg
  org.gnome.Boxes:  # VM manager
    aliases:
      - gnome-boxes.svg
      - boxes.svg
      - org.gnome.Boxes.svg
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
  terminator:  # split-pane terminal — links/apps/scalable/terminator/ já existe
    aliases:
      - io.github.gnome_terminator.terminator.svg
      - net.tenshu.Terminator2.svg
      - org.gnome_terminator.Terminator2.svg
  com.raggesilver.BlackBox:  # terminal
    fallback: maui-station
    aliases: false
```

Redesenhar ícones:

```yaml
communication:
  - fractal.svg
```

Adicionar atalhos:

```yaml
brave.svg:
  - com.brave.Browser.svg

sublime-text.svg:
  - sublime.svg
```