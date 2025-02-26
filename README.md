## Requiments
- nvim 0.11
- tmux
- wezterm

## Getting started
1. Asdf
- Manage all your runtime versions with one tool!
- Installing for macOS:
```
brew install asdf
```

- Add asdf to zsh shell
```
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
```

- Source zsh file to load new env
```
source ~/.zshrc
```

2. Ruby
- Install ruby plugin for asdf version manager
```
asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
```

- Install a specify ruby version
```
asdf install ruby x.x.x
```

- Set a local ruby version
```
asdf local ruby x.x.x
```

- Install a ruby version

- Give permissions to `script.sh`
```
chmod +x script.sh
```

- Run script for automatic setup:
```
./script.sh
```

- Setup env secret:
Copy .env.sample to ~/.env and setup env variables
```
cp .env.sample ~/.env
vi ~/.env
```

## Troubleshooting
