#!/bin/bash
#
# To install direct from github:
#
#   wget -qO - https://raw.githubusercontent.com/nowaos/nowa-glyphs/main/get.sh | bash
#
# Unpacks the repo into a temporary folder and hands over to the install.sh
# inside it. Arguments go straight through.

set -eo pipefail

repo="nowaos/nowa-glyphs"
ref="main"
src="$(mktemp -d)"
url="https://github.com/$repo/archive/refs/heads/$ref.tar.gz"

trap 'rm -rf "$src"' EXIT

echo "Nowa Glyphs  $repo@$ref"
echo

if command -v curl > /dev/null; then
  curl -fsSL "$url"
else
  wget -qO - "$url"
fi | tar xz -C "$src" --strip-components 1

bash "$src/install.sh" "$@"
