set nocompatible                            " required
filetype off                                " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" set encoding
set encoding=utf-8

" split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" enable code folding
set foldmethod=indent
set foldlevel=99

" file ext configurations
au BufNewFile,BufRead *.py
    \ set tabstop=4 |
    \ set softtabstop=4 |
    \ set shiftwidth=4 |
    \ set textwidth=79 |
    \ set expandtab |
    \ set autoindent |
    \ set fileformat=unix

au BufNewFile,BufRead *.js, *.html, *.css
    \ set tabstop=2 |
    \ set softtabstop=2 |
    \ set shiftwidth=2

" set line numbering
set nu

" Syntax Highlighting
let python_highlight_all=1
syntax on
colorscheme monokai
set t_Co=256 " vim-monokai now only support 256 colours in terminal.
set term=screen-256-color

" Nerdtree Ignore .pyc files
let NERDTreeIgnore=['\.pyc$', '\~$']

" let Vundle manage Vundle
Plugin 'VundleVim/Vundle.vim'                  " required

" Add all your plugins here
Plugin 'tmhedberg/SimpylFold'
Plugin 'vim-scripts/indentpython.vim'
Plugin 'scrooloose/syntastic'
Plugin 'nvie/vim-flake8'
Plugin 'altercation/vim-colors-solarized'
Plugin 'scrooloose/nerdtree'
Plugin 'jistr/vim-nerdtree-tabs'
Plugin 'crusoexia/vim-monokai'

call vundle#end()                           " required
filetype plugin indent on                   " required
