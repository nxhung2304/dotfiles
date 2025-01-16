" Options
let mapleader="\\"
set number
set relativenumber
set expandtab
set tabstop=2
set softtabstop=2
set shiftwidth=2
set t_Co=256
set background=dark
set encoding=UTF-8
set clipboard=unnamed
syntax on

" Plugins
call plug#begin()
  Plug 'tpope/vim-surround'
  Plug 'morhetz/gruvbox'
call plug#end()

colorscheme gruvbox

" Keymap
inoremap jk <Esc>
