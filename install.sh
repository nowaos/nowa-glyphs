#!/usr/bin/env bash
set -eo pipefail

# Destination directory
if [ -n "$1" ]; then
  DEST_DIR="$1"
elif [ "$UID" -eq 0 ]; then
  DEST_DIR="/usr/share/icons"
else
  DEST_DIR="$HOME/.local/share/icons"
fi

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
THEME_NAME="Nowa Glyphs"

THEME_DIR="${DEST_DIR}/${THEME_NAME}"

# Remove old installation
[[ -d "$THEME_DIR" ]] && rm -rf "$THEME_DIR"

echo "Installing theme to: $THEME_DIR"

# Create theme directory
mkdir -p "$THEME_DIR"

# Copy main files
# cp -r "$SRC_DIR"/{COPYING,AUTHORS} "$THEME_DIR"
cp -r "$SRC_DIR"/src/index.theme "$THEME_DIR"
cp -r "$SRC_DIR"/src/cursor.theme "$THEME_DIR"

# Copy icon folders
cp -r "$SRC_DIR"/src/{actions,animations,apps,categories,cursors,devices,emblems,mimes,places,preferences,status} "$THEME_DIR"

flatten_files() {
  local dir="$1"
  [ -d "$dir" ] || return
  find "$dir" -mindepth 2 -type f -exec mv -t "$dir" {} +
  find "$dir" -mindepth 1 -type d -empty -delete
}

flatten_links() {
  local dir="$1"
  [ -d "$dir" ] || return
  find "$dir" -mindepth 2 -type l -exec mv -t "$dir" {} +
  find "$dir" -mindepth 1 -type d -empty -delete
}

# Flatten src subfolders
flatten_files "$THEME_DIR/mimes/scalable"
flatten_files "$THEME_DIR/apps/scalable"
flatten_files "$THEME_DIR/actions/symbolic"

# Copy symlinks
cp -r "$SRC_DIR"/links/{actions,apps,mimes,places,preferences,status} "$THEME_DIR"

# Flatten links subfolders
flatten_links "$THEME_DIR/apps/scalable"
flatten_links "$THEME_DIR/apps/symbolic"
flatten_links "$THEME_DIR/actions/symbolic"
flatten_links "$THEME_DIR/mimes/scalable"
flatten_links "$THEME_DIR/mimes/symbolic"
flatten_links "$THEME_DIR/preferences/32"
flatten_links "$THEME_DIR/places/16"
flatten_links "$THEME_DIR/places/24"
flatten_links "$THEME_DIR/places/scalable"
flatten_links "$THEME_DIR/places/symbolic"
flatten_links "$THEME_DIR/status/16"
flatten_links "$THEME_DIR/status/22"
flatten_links "$THEME_DIR/status/24"
flatten_links "$THEME_DIR/status/32"
flatten_links "$THEME_DIR/status/symbolic"

# Create @2x symlinks
(
  cd "$THEME_DIR"
  for dir in actions animations apps categories devices emblems mimes places preferences status; do
    ln -sf "$dir" "${dir}@2x"
  done
)

# Update GTK icon cache
gtk-update-icon-cache "$THEME_DIR"

echo "Installed successfully!"
