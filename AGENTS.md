# AGENTS.md

Guidelines for AI coding agents working in this repository.

## Project Overview

This is an OpenCode skill package that enables remote access to OpenCode sessions via Tailscale VPN. The project contains:

- Shell scripts for automated setup
- Markdown-based skill definitions
- Documentation

## Project Structure

```
opencode-remote-control-skill/
├── README.md                           # Project documentation
├── AGENTS.md                           # This file
└── skills/
    └── remote-control/
        ├── SKILL.md                    # Skill definition for OpenCode
        └── scripts/
            └── remote-control-setup.sh # Automated setup script
```

## Build/Lint/Test Commands

### Shell Script Linting

```bash
# Lint shell scripts with shellcheck
shellcheck skills/remote-control/scripts/remote-control-setup.sh

# Lint all shell scripts
shellcheck skills/**/scripts/*.sh
```

### Testing

```bash
# Run the setup script manually (requires Tailscale)
./skills/remote-control/scripts/remote-control-setup.sh

# Dry run - check script syntax without executing
bash -n skills/remote-control/scripts/remote-control-setup.sh
```

### Format Shell Scripts

```bash
# Format with shfmt (if installed)
shfmt -w skills/remote-control/scripts/remote-control-setup.sh
```

## Code Style Guidelines

### Shell Scripts (Bash)

#### Error Handling

```bash
# Always use strict mode at the top of scripts
set -e

# Redirect stderr to suppress expected errors
command 2>/dev/null || echo "fallback"

# Check command success explicitly
if command -v tailscale &> /dev/null; then
    # command exists
fi
```

#### Functions

```bash
# Use snake_case for function names
print_connection_info() {
    # ...
}

# Use local variables
get_tailscale_ip() {
    local ts_ip
    ts_ip=$(tailscale ip -4 2>/dev/null || echo "")
    echo "$ts_ip"
}

# Return codes: 0 for success, non-zero for failure
check_tailscale_cli() {
    if command -v tailscale &> /dev/null; then
        return 0
    fi
    return 1
}
```

#### Variables and Constants

```bash
# Constants at the top (uppercase)
RED='\033[0;31m'
GREEN='\033[0;32m'
PORT="${OPENCODE_PORT:-4096}"  # With default value

# Local variables (lowercase, snake_case)
local ts_ip
local has_cli=false
```

#### Conditional Logic

```bash
# Use [[ ]] for conditionals (more robust than [ ])
if [[ -n "$ts_ip" ]]; then
    echo "IP: $ts_ip"
fi

# Use $OSTYPE for OS detection
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
fi
```

#### Output and Logging

```bash
# Use print_* functions for consistent output
print_step "Starting process..."
print_ok "Operation completed"
print_warn "Potential issue"
print_error "Failed to complete"
print_info "Additional context"

# Use echo -e with color variables
echo -e "${GREEN}Success${NC}"
```

### Markdown Files

#### SKILL.md Structure

```markdown
---
name: skill-name
description: Brief description of what the skill does. Include trigger phrases.
---

# Skill Name

Brief introduction.

## Workflow

### Step 1: Title

```bash
command
```

Description of expected output and next steps.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| ... | ... |
```

#### README.md Conventions

- Use proper heading hierarchy (H1 for title only)
- Include installation, usage, and troubleshooting sections
- Use code blocks with language specifiers
- Keep lines under 80 characters when possible

## Adding New Skills

1. Create a new directory under `skills/`
2. Add a `SKILL.md` file with the skill definition
3. Add any supporting scripts in `scripts/` subdirectory
4. Update README.md with installation instructions

## Best Practices

### Security

- Never hardcode credentials or API keys
- Use environment variables for configuration
- Quote all variable expansions: `"$variable"`

### Portability

- Support both macOS and Linux where possible
- Check for dependencies before using them
- Provide fallback instructions when automation fails

### User Experience

- Provide clear, colored output
- Handle errors gracefully with helpful messages
- Don't ask for confirmation unless sudo is required

### Documentation

- Document what each script does at the top
- Include usage examples
- List prerequisites clearly

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Tailscale installation failed |
| 2 | Tailscale connection failed |
| 3 | OpenCode server failed to start |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENCODE_PORT` | 4096 | Port for OpenCode web server |
