# Brew / App Install–Uninstall Operational Card

## Install an app or package

1. Install
```
brew install <formula>
brew install --cask <app>
mas install <app_id>
```

2. Refresh Brewfile
```
brewfile-refresh
```

3. Commit & push Brewfile


## Remove an app or package

1. Uninstall
```
brew uninstall <formula>
brew uninstall --cask <app>
mas uninstall <app_id>
```

2. Refresh Brewfile
```
brewfile-refresh
```

3. Commit & push Brewfile


## Sync another Mac

```
sync-brew.sh
```

Installs/removes apps to match the Brewfile.

