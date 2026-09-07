#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR="$HOME/.local/bin"
ACTIONS_DIR="$HOME/.local/share/nemo/actions"

INSTALL_DIR="$(realpath -m "$INSTALL_DIR")"
ACTIONS_DIR="$(realpath -m "$ACTIONS_DIR")"

mkdir -p "$INSTALL_DIR"
mkdir -p "$ACTIONS_DIR"

install_file() {
	local source="$1"
	local destination_dir="$2"

	local filename
	filename="$(basename "$source")"

	local destination="$destination_dir/$filename"

	echo "Installing: $source -> $destination"

	sed "s|<absolute_path_to>|$INSTALL_DIR|g" "$source" > "$destination"

	if [[ "$source" == *.sh ]]; then
		chmod +x "$destination"
	fi
}

# *.sh -> INSTALL_DIR
for file in ./*.sh; do
	[[ -f "$file" ]] || continue

# Don't install the installer itself
	[[ "$(basename "$file")" == "install.sh" ]] && continue

	install_file "$file" "$INSTALL_DIR"
done

# *.nemo_action -> ACTIONS_DIR
for file in ./*.nemo_action; do
	[[ -f "$file" ]] || continue
	install_file "$file" "$ACTIONS_DIR"
done

echo "Installation completed."
