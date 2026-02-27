# OpenCode Remote Control Skill

Enable remote access to your local OpenCode session using Tailscale VPN.

## Overview

This skill automatically sets up secure remote access to OpenCode, allowing you to continue coding from any device (phone, tablet, another computer) on your private Tailscale network.

## Features

- Automatic Tailscale installation and configuration
- One-command remote access setup
- Secure private network via WireGuard encryption
- QR code generation for easy mobile scanning
- No cloud dependency - everything runs locally
- Works on macOS and Linux

## Installation

Copy the `skills/remote-control` folder to your OpenCode skills directory:

```bash
cp -r skills/remote-control ~/.config/opencode/skills/
```

Or for project-level installation:

```bash
cp -r skills/remote-control .opencode/skills/
```

## Usage

In OpenCode, use the `/remote-control` skill.

The skill will automatically:

1. Check/install Tailscale CLI
2. Connect to your Tailscale network
3. Start the OpenCode web server
4. Display access URL with QR code for easy scanning

## Manual Setup

Alternatively, run the setup script directly:

```bash
./skills/remote-control/scripts/remote-control-setup.sh
```

## Requirements

- OpenCode CLI installed
- Tailscale account (free tier available at [tailscale.com](https://tailscale.com))

## How It Works

1. **Tailscale** creates a secure mesh VPN between your devices
2. **OpenCode Web** exposes the full TUI experience in your browser
3. Combined, you get remote access to your local development environment from anywhere

## Project Structure

```
opencode-remote-control-skill/
├── README.md
├── AGENTS.md
└── skills/
    └── remote-control/
        ├── SKILL.md                    # Skill definition for OpenCode
        └── scripts/
            ├── remote-control-setup.sh # Automated setup script
            └── generate-qr.sh          # QR code generator
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| App Store Tailscale CLI crashes | Install Homebrew CLI: `brew install tailscale` |
| Port 4096 in use | Set `OPENCODE_PORT=4097` environment variable |
| QR code not displaying | Install qrencode: `brew install qrencode` (macOS) or `sudo apt install qrencode` (Linux) |
| sudo required for symlink | Run: `sudo ln -s /Applications/Tailscale.app/Contents/MacOS/Tailscale /usr/local/bin/tailscale` |

## License

MIT
