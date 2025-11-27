#!/bin/zsh

mkdir -p "$HOME/.config"
ln -sf "$HOME/Documents/SharedConfigs/settings/terminal/starship.toml" "$HOME/.config/starship.toml"

if ! command -v starship >/dev/null 2>&1; then
  brew install starship
fi

if ! grep -q 'starship init zsh' "$HOME/.zshrc" 2>/dev/null; then
  echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
fi
