" Template vimrc file from MIT Missing Semester course {{{
" Comments in Vimscript start with a `"`.

" If you open this file in Vim, it'll be syntax highlighted for you.

" Vim is based on Vi. Setting `nocompatible` switches from the default
" Vi-compatibility mode and enables useful Vim functionality. This
" configuration option turns out not to be necessary for the file named
" '~/.vimrc', because Vim automatically enters nocompatible mode if that file
" is present. But we're including it here just in case this config file is
" loaded some other way (e.g. saved as `foo`, and then Vim started with
" `vim -u foo`).
set nocompatible

" Turn on syntax highlighting.
syntax on

" Disable the default Vim startup message.
set shortmess+=I

" Show line numbers.
set number

" This enables relative line numbering mode. With both number and
" relativenumber enabled, the current line shows the true line number, while
" all other lines (above and below) are numbered relative to the current line.
" This is useful because you can tell, at a glance, what count is needed to
" jump up or down to a particular line, by {count}k to go up or {count}j to go
" down.
set relativenumber

" Always show the status line at the bottom, even if you only have one window open.
set laststatus=2

" The backspace key has slightly unintuitive behavior by default. For example,
" by default, you can't backspace before the insertion point set with 'i'.
" This configuration makes backspace behave more reasonably, in that you can
" backspace over anything.
set backspace=indent,eol,start

" By default, Vim doesn't let you hide a buffer (i.e. have a buffer that isn't
" shown in any window) that has unsaved changes. This is to prevent you from "
" forgetting about unsaved changes and then quitting e.g. via `:qa!`. We find
" hidden buffers helpful enough to disable this protection. See `:help hidden`
" for more information on this.
set hidden

" This setting makes search case-insensitive when all characters in the string
" being searched are lowercase. However, the search becomes case-sensitive if
" it contains any capital letters. This makes searching more convenient.
set ignorecase
set smartcase
set wildignore=*.jpg,*.png,*.tif,*.mp4,*.pth,*.zip,*.tar,*.gz,*.rar,*.exe,*.dll,*.so,*.dylib,*.pt,*.pyc,*.pyo,*.class,*.o,*.obj,*.a,*.lib,*.out,*.log,*.tmp,*.bak,*.swp,*.swo,*.swn,*.DS_Store,*.git,*.svn,*.hg,*.vscode,*.idea

" Enable searching as you type, rather than waiting till you press enter.
set incsearch

" Unbind some useless/annoying default key bindings.
nmap Q <Nop> " 'Q' in normal mode enters Ex mode. You almost never want this.

" Disable audible bell because it's annoying.
set noerrorbells visualbell t_vb=

" Enable mouse support. You should avoid relying on this too much, but it can
" sometimes be convenient.
set mouse+=a

" Try to prevent bad habits like using the arrow keys for movement. This is
" not the only possible bad habit. For example, holding down the h/j/k/l keys
" for movement, rather than using more efficient movement commands, is also a
" bad habit. The former is enforceable through a .vimrc, while we don't know
" how to prevent the latter.
" Do this in normal mode...
nnoremap <Left>  :echoe "Use h"<CR>
nnoremap <Right> :echoe "Use l"<CR>
nnoremap <Up>    :echoe "Use k"<CR>
nnoremap <Down>  :echoe "Use j"<CR>
" ...and in insert mode
inoremap <Left>  <ESC>:echoe "Use h"<CR>
inoremap <Right> <ESC>:echoe "Use l"<CR>
inoremap <Up>    <ESC>:echoe "Use k"<CR>
inoremap <Down>  <ESC>:echoe "Use j"<CR>

" So far, based on vimrc suggested from missing semester course
" }}}
" Add cursor shape/configure tabwidth/vim folding {{{
" Ps = 0  -> blinking block.
" Ps = 1  -> blinking block (default).
" Ps = 2  -> steady block.
" Ps = 3  -> blinking underline.
" Ps = 4  -> steady underline.
" Ps = 5  -> blinking bar (xterm).
" Ps = 6  -> steady bar (xterm).
let &t_SI = "\e[6 q" "Insert mode
let &t_SR = "\e[3 q" "Replace mode
let &t_EI = "\e[2 q" "Normal mode

" Set tab width and indentation.
" Set tab to spaces
" Use 2 spaces for tabs
set tabstop=2       " Number of spaces a tab character shows as
set shiftwidth=2    " Number of spaces to use for autoindent
set expandtab       " Use spaces instead of tab characters
set softtabstop=2   " Number of spaces a <Tab> feels like in insert mode

" Setup for vim-default folding (FOLDING)
set foldmethod=indent
set foldlevel=0
" }}}
" Vim Plug start! {{{
call plug#begin()
" The default plugin directory will be as follows:
"   - Vim (Linux/macOS): '~/.vim/plugged'
"   - Vim (Windows): '~/vimfiles/plugged'
"   - Neovim (Linux/macOS/Windows): stdpath('data') . '/plugged'
" You can specify a custom plugin directory by passing it as the argument
"   - e.g. `call plug#begin('~/.vim/plugged')`
"   - Avoid using standard Vim directory names like 'plugin'

" Make sure you use single quotes

" Powerful Airline
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
" Language Server management/autocompletion/linting/fixing {{{
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'sheerun/vim-polyglot'
"
" Linting and fixing
Plug 'dense-analysis/ale'
" }}}
" Sidebar panel / Git integration / File finding {{{
Plug 'preservim/nerdtree' |
  \ Plug 'Xuyuanp/nerdtree-git-plugin' |
" Git integration
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/gv.vim'

" Finding files and fuzzy search
" Plug 'ctrlpvim/ctrlp.vim'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
" }}}
" Enhancing coding experience {{{
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'junegunn/vim-easy-align'
Plug 'christoomey/vim-tmux-navigator'
Plug 'jiangmiao/auto-pairs'
Plug 'github/copilot.vim'
Plug 'terryma/vim-multiple-cursors'
" }}}
" Themes {{{
Plug 'tomasiser/vim-code-dark'
Plug 'morhetz/gruvbox'
Plug 'dikiaap/minimalist'
Plug 'whatyouhide/vim-gotham'
Plug 'tomasr/molokai'
Plug 'junegunn/seoul256.vim'
Plug 'dracula/vim'
Plug 'folke/tokyonight.nvim'
Plug 'arcticicestudio/nord-vim'
Plug 'joshdick/onedark.vim'
Plug 'cocopon/iceberg.vim'
Plug 'sainnhe/everforest'
Plug 'ayu-theme/ayu-vim'
Plug 'sjl/badwolf'
Plug 'chrisbra/colorizer'
" }}}
call plug#end()
" }}}
" Colorsceme defined {{{
syntax enable
set background=dark
set colorcolumn=100,200
colorscheme gruvbox

" Set terminal colors
if has('termguicolors')
  set termguicolors
endif
" }}}
" Call config file for vim plugins {{{
for f in split(glob('~/.vim/config/*.vim'), '\n')
    execute 'source' f
endfor
" }}}
" Folding setup for dotfiles. {{{
" Setting up folding rules by length of line
" autocmd! BufReadPost * :if line('$') > 100 | setlocal foldmethod=indent foldlevel=0 | endif
" Add automatic folding for selected file. {{{ and }}} are the fold markers.
autocmd BufRead,BufNewFile *zshrc setlocal foldmethod=marker foldmarker={{{,}}}
autocmd BufRead,BufNewFile *aliases setlocal foldmethod=marker foldmarker={{{,}}}
autocmd BufRead,BufNewFile *vimrc setlocal foldmethod=marker foldmarker={{{,}}}
" }}}
" PYTHONPATH {{{
" Set PYTHONPATH for Python 3
autocmd FileType python let $PYTHONPATH = getcwd()
" }}}
