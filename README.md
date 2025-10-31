# Quick install for MONACO Font

* Original Font Name: Monaco
* Info: Classic monospace font originally developed by Apple, perfect for coding and terminal use


## Install using curl
```bash
curl -fsSL https://raw.githubusercontent.com/wachawo/monaco/main/install.sh | bash -s --
```

## Or using wget
```bash
wget -qO- https://raw.githubusercontent.com/wachawo/monaco/main/install.sh | bash -s --
```

## Install for all users (run as root)
```bash
sudo curl -fsSL https://raw.githubusercontent.com/wachawo/monaco/main/install.sh | bash -s --
```

If you have cloned this repository, run the local script instead:

```bash
git clone https://github.com/wachawo/monaco.git
cd ./monaco
./install.sh -n
sudo ./install.sh  # for system-wide installation
```

This script downloads the MONACO font file from the repository and installs it into the appropriate font directory.

File: `install.sh` (also available at https://raw.githubusercontent.com/wachawo/monaco/main/install.sh)

Features:
- Downloads MONACO.TTF from GitHub repository.
- Installs into `~/.fonts/` for regular users or `/usr/share/fonts/monaco/` for root user.
- Updates the font cache using `fc-cache`.
- Supports dry-run (`-n`) and force overwrite (`-f`).
- Automatically detects if running as root and chooses appropriate installation directory.

Installation directories:
- **Regular users**: `~/.fonts/`
- **Root user**: `/usr/share/fonts/monaco/`
- **Custom**: Use `-t` option to specify custom directory
