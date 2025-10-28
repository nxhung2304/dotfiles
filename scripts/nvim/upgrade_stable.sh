echo "Upgrading Neovim process..."

if [ -d ~/neovim ]; then
    cd ~/neovim || { echo "Failed to change directory to ~/neovim"; exit 1; }
    git pull origin stable
else
    git clone https://github.com/neovim/neovim ~/neovim
    cd ~/neovim || { echo "Failed to change directory to ~/neovim
"; exit 1; }

git checkout stable
make CMAKE_BUILD_TYPE=RelWithDebInfo

sudo make install

echo "Upgrading Neovim process completed."
nvim --version
