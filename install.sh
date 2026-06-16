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

# Copy src
cp -r "$SRC_DIR"/src/. "$THEME_DIR"

# Flatten _* category subdirs
find "$THEME_DIR" -type d -name '_*' | while read dir; do
  find "$dir" -type f -exec mv -t "$(dirname "$dir")" {} +
  rmdir "$dir"
done

# Copy symlinks, dropping the target-named subdir
find "$SRC_DIR/links" -type l -printf '%h\n' | sort -u | while read leaf; do
  relative_path="${leaf#$SRC_DIR/links/}"
  cp -P "$leaf"/* "$THEME_DIR/$(dirname "$relative_path")/"
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
