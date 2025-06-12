#!/bin/bash
set -euo pipefail

# === Python Environment Sanitizer for macOS (zsh focused) ===
# Goal: Configure sane, portable, venv-friendly Python setup via pyenv

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

say_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
say_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
say_err() { echo -e "${RED}[ERR]${NC} $1" >&2; }

require() {
  command -v "$1" >/dev/null 2>&1 || { say_err "$1 is required but not found."; exit 1; }
}

confirm() {
  read -r -p "$1 [y/N] " response
  case "$response" in
    [yY][eE][sS]|[yY]) true;;
    *) false;;
  esac
}

# --- PATH helpers -----------------------------------------------------------
prepend_path() {
  case ":$PATH:" in
    *":$1:"*) ;; # already present
    *) PATH="$1:$PATH" ;;
  esac
}

ensure_path_precedence() {
  PYENV_SHIMS="$HOME/.pyenv/shims"
  [[ -d "$PYENV_SHIMS" ]] || return 0
  if [[ ":$PATH:" != *":$PYENV_SHIMS:"* ]]; then
    prepend_path "$PYENV_SHIMS"
  fi
}

ensure_pyenv_in_zshrc_top() {
  ZSHRC="$HOME/.zshrc"
  PYENV_SHIMS="$HOME/.pyenv/shims"
  if ! grep -q "export PATH=\"$PYENV_SHIMS:\$PATH\"" "$ZSHRC" 2>/dev/null; then
    # Insert at top for precedence (keep backup)
    cp "$ZSHRC" "$ZSHRC.bak.$(date +%s)" 2>/dev/null || true
    { echo "export PATH=\"$PYENV_SHIMS:\$PATH\""; cat "$ZSHRC"; } > "$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"
    say_ok "Prepended pyenv shims path to ~/.zshrc for precedence"
  fi
}

# --- Profile & env ----------------------------------------------------------
check_zsh_profile() {
  ZSHRC="$HOME/.zshrc"
  if ! grep -q "pyenv init" "$ZSHRC" 2>/dev/null; then
    say_warn "pyenv not initialized in ~/.zshrc"
    confirm "Add pyenv init block to your ~/.zshrc?" && {
      cat <<'EOF' >> "$ZSHRC"
# PYENV CONFIG BEGIN
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
# PYENV CONFIG END
EOF
      say_ok "pyenv config added to ~/.zshrc"
    }
  else
    say_ok "pyenv already configured in ~/.zshrc"
  fi

  # Ensure alias but also symlink for scripts
  if ! grep -q "alias python3=\"python\"" "$ZSHRC" 2>/dev/null; then
    echo "alias python3=\"python\"" >> "$ZSHRC"
    say_ok "Alias python3=python added to ~/.zshrc"
  else
    say_ok "Alias python3=python already present in ~/.zshrc"
  fi

  ensure_pyenv_in_zshrc_top
}

check_env_vars() {
  for var in PIP_REQUIRE_VIRTUALENV PIP_USER PYTHONNOUSERSITE; do
    if [ -n "${!var-}" ]; then
      say_err "Environment variable $var is set — this breaks compliant venvs."
      echo "Current value: ${!var}"
      say_err "Please unset it manually before continuing."
      exit 1
    fi
  done
  say_ok "No conflicting environment variables detected"
}

check_pip_config() {
  if python -m pip config get global.user &>/dev/null; then
    say_err "pip configuration sets global.user=true, causing --user installs."
    confirm "Unset it automatically?" && {
      python -m pip config unset global.user || true
      say_ok "Removed global.user from pip config"
    } || {
      say_err "Aborting until you remove this pip config."; exit 1;
    }
  else
    say_ok "No pip config enforcing --user detected"
  fi
}

install_pyenv() {
  if ! command -v pyenv >/dev/null; then
    say_warn "pyenv not found. Installing via Homebrew..."
    brew install pyenv
    say_ok "pyenv installed"
  else
    say_ok "pyenv already installed"
  fi
}

install_python_version() {
  version="$1"
  if ! pyenv versions --bare | grep -q "^${version}$"; then
    say_warn "Installing Python $version via pyenv..."
    pyenv install "$version"
    say_ok "Python $version installed"
  else
    say_ok "Python $version already installed"
  fi

  pyenv global "$version"
  say_ok "Python $version set as global default"
}

verify_pyenv_shim_active() {
  ensure_path_precedence
  hash -r
  shim_path="$(command -v python)"
  if [[ "$shim_path" != *".pyenv/shims/python"* ]]; then
    say_err "python does not resolve to pyenv shim even after PATH fix: $shim_path"
    exit 1
  fi
  # Verify python3 as well
  shim_py3="$(command -v python3 || true)"
  if [[ "$shim_py3" != *".pyenv/shims/python3"* ]]; then
    say_warn "python3 is not the pyenv shim (currently $shim_py3) — creating symlink."
    ln -sf "$HOME/.pyenv/shims/python" "$HOME/.pyenv/shims/python3"
    hash -r
    shim_py3="$(command -v python3)"
    if [[ "$shim_py3" != *".pyenv/shims/python3"* ]]; then
      say_err "Failed to make python3 point to pyenv shim: $shim_py3"
      exit 1
    fi
  fi
  say_ok "pyenv shims active for python and python3"
}

verify_setup() {
  expected_version="$1"
  actual=$(python -V 2>&1)
  which_python=$(command -v python)
  which_py3=$(command -v python3)

  if [[ "$actual" != *"$expected_version"* ]]; then
    say_err "Expected Python $expected_version, but got $actual"
    exit 1
  fi

  for p in "$which_python" "$which_py3"; do
    [[ "$p" == *".pyenv/shims"* ]] || { say_err "Interpreter not from pyenv shim: $p"; exit 1; }
  done

  say_ok "Verified Python $expected_version via pyenv shims (python & python3)"
}

main() {
  echo -e "${YELLOW}--- Python Environment Setup for macOS (zsh) ---${NC}"

  require brew
  require curl
  require git

  check_env_vars
  install_pyenv
  check_zsh_profile
  ensure_path_precedence

  PYTHON_VERSION="3.12.3"
  install_python_version "$PYTHON_VERSION"

  verify_pyenv_shim_active
  check_pip_config
  verify_setup "$PYTHON_VERSION"

  echo -e "${GREEN}\n✅ Your Python environment is now sane, venv-friendly, and fool-proof.${NC}"
  echo -e "Reload your terminal or run 'exec $SHELL' to start using it."
}

main "$@"
