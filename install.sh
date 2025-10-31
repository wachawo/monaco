#!/usr/bin/env bash
# install.sh — quick installer that downloads fonts and installs it to ~/.fonts
set -euo pipefail

# Default installation directory - check if running as root
if [ "$EUID" -eq 0 ]; then
    ROOT_DIR="/usr/share/fonts/custom"
else
    ROOT_DIR="$HOME/.fonts"
fi

# Default base URL to download fonts from
BASE_URL="https://raw.githubusercontent.com/wachawo/monaco/refs/heads/main/fonts"

show_help(){
  cat <<EOF
Usage: install.sh [options] [font-archive ...]

Downloads font archives from the repository, extracts and installs font files.

Installation directory:
  - For regular users: ~/.fonts/
  - For root user: /usr/share/fonts/custom/

If no font archive names are provided, the script will download and extract MONACO.zip by default.

The script downloads ZIP archives and extracts only the font files to the destination directory.

Options:
  -b URL   Use a different base URL for downloads (default: ${BASE_URL})
  -t DIR   Install into DIR instead of default directory
  -f       Force overwrite existing files
  -n       Dry-run (show actions without performing downloads)
  -h       Show this help

Examples:
  # Download and install MONACO.TTF from MONACO.zip
  install.sh

  # Install specific font archive
  install.sh MONACO.zip

  # Use a custom install directory
  install.sh -t ~/.local/share/fonts

  # Dry-run to see what would be downloaded and extracted
  install.sh -n
EOF
}

DRY_RUN=0
FORCE=0

while getopts ":b:t:fnh" opt; do
  case ${opt} in
    b) BASE_URL="$OPTARG" ;;
    t) ROOT_DIR="$OPTARG" ;;
    f) FORCE=1 ;;
    n) DRY_RUN=1 ;;
    h) show_help; exit 0 ;;
    \?) echo "Unknown option: -$OPTARG" >&2; show_help; exit 2 ;;
  esac
done
shift $((OPTIND-1))

# Default list of font archive basenames to download when no filenames are provided.
# These are fetched from ${BASE_URL}/<name>
DEFAULT_FILENAMES=(
  MONACO.zip
)

# If the user supplied filenames, use them; otherwise use the default list above.
if [ "$#" -eq 0 ]; then
  FILENAMES=("${DEFAULT_FILENAMES[@]}")
else
  FILENAMES=("$@")
fi

mkdir -p "$ROOT_DIR"

download_cmds=()
extract_cmds=()

for name in "${FILENAMES[@]}"; do
  # skip empty names
  [ -z "$name" ] && continue
  
  # construct remote url and temporary destination for zip
  remote_url="$BASE_URL/$name"
  temp_zip="/tmp/${name}"
  
  # determine final font file name based on archive name
  if [[ "$name" == "MONACO.zip" ]]; then
    font_name="MONACO.TTF"
  elif [[ "$name" == *.zip ]]; then
    # For other zip files, assume font name is archive name without .zip
    font_name="${name%.zip}"
  else
    font_name="$name"
  fi
  
  final_dest="$ROOT_DIR/$font_name"

  if [ -e "$final_dest" ] && [ "$FORCE" -ne 1 ]; then
    echo "Skipping existing font: $final_dest (use -f to overwrite)" >&2
    continue
  fi

  # check if unzip is available
  if ! command -v unzip >/dev/null 2>&1; then
    echo "unzip is not available; cannot extract font archives." >&2
    exit 3
  fi

  # choose downloader
  if command -v curl >/dev/null 2>&1; then
    dl_cmd=(curl -fSL -o "$temp_zip" "$remote_url")
  elif command -v wget >/dev/null 2>&1; then
    dl_cmd=(wget -O "$temp_zip" "$remote_url")
  else
    echo "Neither curl nor wget is available; cannot download files." >&2
    exit 3
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    download_cmds+=("${dl_cmd[*]}")
    extract_cmds+=("unzip -j $temp_zip $font_name -d $ROOT_DIR")
    extract_cmds+=("rm $temp_zip")
  else
    echo "Downloading $remote_url -> $temp_zip"
    # attempt download, continue on failure
    if ! "${dl_cmd[@]}"; then
      echo "Failed to download: $remote_url" >&2
      rm -f "$temp_zip" || true
      continue
    fi
    
    echo "Extracting $font_name from $temp_zip to $ROOT_DIR"
    # extract only the font file we need
    if ! unzip -j "$temp_zip" "$font_name" -d "$ROOT_DIR"; then
      echo "Failed to extract font from: $temp_zip" >&2
      rm -f "$temp_zip" || true
      continue
    fi
    
    # cleanup temporary zip file
    rm -f "$temp_zip" || true
  fi
done

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry-run: the following commands would be executed:"
  echo "Download commands:"
  for c in "${download_cmds[@]}"; do
    echo "  $c"
  done
  echo "Extract commands:"
  for c in "${extract_cmds[@]}"; do
    echo "  $c"
  done
  exit 0
fi

echo "Updating font cache for $ROOT_DIR ..."
if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f -v "$ROOT_DIR" || true
else
  echo "fc-cache not found; skipping font cache update." >&2
fi

echo "Done. Fonts installed to: $ROOT_DIR"