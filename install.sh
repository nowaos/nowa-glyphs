#!/usr/bin/env bash
set -eo pipefail

# Destination directory
if [ "$UID" -eq 0 ]; then
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

# Flatten mimes/scalable subfolders
MIMES_DIR="$THEME_DIR/mimes/scalable"
if [ -d "$MIMES_DIR" ]; then
    find "$MIMES_DIR" -mindepth 2 -type f -exec mv -t "$MIMES_DIR" {} +
    find "$MIMES_DIR" -mindepth 1 -type d -empty -delete
fi

# Copy symlinks
cp -r "$SRC_DIR"/links/{actions,apps,mimes,places,preferences,status} "$THEME_DIR"

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
