echo "Upgrading Neovim to nightly process..."

if [ -d ~/neovim ]; then
    cd ~/neovim || { echo "Failed to change directory to ~/neovim"; exit 1; }
    git pull origin master
else
    git clone https://github.com/neovim/neovim ~/neovim
    cd ~/neovim || { echo "Failed to change directory to ~/neovim
"; exit 1; }

git checkout master
make CMAKE_BUILD_TYPE=RelWithDebInfo

sudo make install

echo "Upgrading Neovim to nightly completed."
nvim --version
