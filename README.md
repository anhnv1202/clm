# clm

Claude Code Model Selector — TUI tool to switch models in `~/.claude/settings.json`.

Prebuilt binary. No Python needed. Works on Linux, macOS, Windows.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/anhnv1202/clm/main/install.sh | sh
```

Windows (PowerShell):
```powershell
# Coming soon - use WSL or Git Bash for now
```

## Uninstall

```bash
clm --uninstall
```

## Usage

### TUI Mode (interactive)

```bash
clm                          # Open TUI selector
```

1. Pick a slot (Main, Opus, Sonnet, Haiku)
2. Pick a model from your API provider
3. Done — `settings.json` updated instantly

### CLI Mode (direct)

```bash
clm cc/claude-opus-4-7                # Set main model
clm --opus cc/claude-opus-4-7         # Set opus default
clm --sonnet combo-cheap              # Set sonnet default
clm --haiku cc/claude-haiku-4-5       # Set haiku default
clm --help                            # Show help
```

## Key Bindings (TUI)

| Key | Action |
|-----|--------|
| `j` / `↓` | Move down |
| `k` / `↑` | Move up |
| `PgUp` / `PgDn` | Scroll page |
| `/` | Search |
| `Enter` | Select |
| `Esc` / `q` | Back / Quit |

## Requirements

- `~/.claude/settings.json` with `ANTHROPIC_BASE_URL` and `ANTHROPIC_AUTH_TOKEN`

## Release

Push a tag to trigger GitHub Actions build:

```bash
git tag v1.0.0
git push origin v1.0.0
```

This builds binaries for linux-x64, linux-arm64, macos-arm64, windows-x64 and creates a GitHub Release.
