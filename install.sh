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

# Flatten mimes/scalable and apps/scalable src subfolders
for FLAT_DIR in "$THEME_DIR/mimes/scalable" "$THEME_DIR/apps/scalable"; do
    if [ -d "$FLAT_DIR" ]; then
        find "$FLAT_DIR" -mindepth 2 -type f -exec mv -t "$FLAT_DIR" {} +
        find "$FLAT_DIR" -mindepth 1 -type d -empty -delete
    fi
done

# Copy symlinks
cp -r "$SRC_DIR"/links/{actions,apps,mimes,places,preferences,status} "$THEME_DIR"

# Flatten links/apps/scalable and links/apps/symbolic subfolders
for LINKS_FLAT in "$THEME_DIR/apps/scalable" "$THEME_DIR/apps/symbolic"; do
    if [ -d "$LINKS_FLAT" ]; then
        find "$LINKS_FLAT" -mindepth 2 -type l -exec mv -t "$LINKS_FLAT" {} +
        find "$LINKS_FLAT" -mindepth 1 -type d -empty -delete
    fi
done

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
