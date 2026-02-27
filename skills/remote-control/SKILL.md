---
name: remote-control
description: Enable remote access to your local OpenCode session using Tailscale VPN. Automatically installs Tailscale, connects to tailnet, starts the web server, and provides a private URL. Use when you want to access OpenCode from another device (phone, tablet, another computer), continue coding remotely, or set up secure remote development. Triggers: "remote control", "access opencode remotely", "remote access", "continue from phone", "tailscale opencode", "start remote access".
---

# Remote Control

Set up remote access to OpenCode. Execute all steps automatically without asking user confirmation (except for sudo commands).

**Note:** No password needed - Tailscale provides secure private network access.

## Workflow

Execute these steps in order. Handle everything automatically.

### Step 1: Check Tailscale CLI

```bash
which tailscale && tailscale version
```

If CLI not found, install via Homebrew:
```bash
brew install tailscale
```

### Step 2: Check Tailscale Connection

```bash
tailscale status
```

If not connected or returns error, run:
```bash
tailscale up
```

If this opens a browser for authentication, inform user to complete login, then continue after they confirm.

### Step 3: Get Tailscale IP

```bash
tailscale ip -4
```

### Step 4: Start OpenCode Web Server

Check if server already running:
```bash
lsof -i :4096 -sTCP:LISTEN
```

If not running, start without password:
```bash
unset OPENCODE_SERVER_USERNAME OPENCODE_SERVER_PASSWORD
opencode web --hostname 0.0.0.0 --port 4096 &
```

Wait for server to start:
```bash
sleep 3 && lsof -i :4096 -sTCP:LISTEN
```

### Step 5: Output Connection Info

Display to user:
- Tailscale IP
- Access URL: `http://<tailscale-ip>:4096`

## Summary

After completing all steps, provide:

```
Remote Access Ready!

Tailscale IP: 100.x.y.z
Access URL: http://100.x.y.z:4096

[QR Code displayed]

To connect from another device:
1. Install Tailscale on that device
2. Sign in to the same Tailscale account
3. Scan the QR code or open the Access URL in browser
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| App Store Tailscale CLI crashes | Install Homebrew CLI: `brew install tailscale` |
| Port 4096 in use | Use different port: `--port 4097` |
| sudo required for symlink | Inform user to run: `sudo ln -s /Applications/Tailscale.app/Contents/MacOS/Tailscale /usr/local/bin/tailscale` |
