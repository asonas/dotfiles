set number
filetype on

highlight ZenkakuSpace cterm=underline ctermfg=lightblue guibg=white
match ZenkakuSpace /　/

set autoread
set hidden
set noswapfile
set nobackup
set laststatus=2
set cursorline
set clipboard=unnamed

nnoremap <silent> <Space>q :quit<CR>
nnoremap <silent> <Space>Q :quit!<CR>
nnoremap <silent> <Space>e :wq<CR>
nnoremap <silent> <Space><Space> :w<CR>

imap <C-p> <Up>
imap <C-n> <Down>
imap <C-b> <Left>
imap <C-f> <Right>
imap <C-a> <C-o>:call <SID>home()<CR>
imap <C-e> <End>
imap <C-d> <Del>
imap <C-h> <BS>
imap <C-k> <C-r>=<SID>kill()<CR>

nmap <silent> <Space>p :NERDTreeToggle<CR>
set guifont=SourceCodePro-Regular:h12

autocmd BufWritePre * :%s/\s\+$//ge

let NERDTreeShowHidden = 1
let g:NERDTreeWinSize = 40
let g:python_host_prog = expand('/usr/bin/python')
let g:python3_host_prog = expand('/opt/brew/bin/python3')

let g:ruby_host_prog = '/Users/asonas/.rbenv/versions/2.6.3/bin/neovim-ruby-host'

if &compatible
  set nocompatible
endif

set runtimepath+=~/.vim/dein/repos/github.com/Shougo/dein.vim

let s:dein_dir = expand('~/.vim/dein')

if dein#load_state(s:dein_dir)
  call dein#begin(s:dein_dir)

  call dein#load_toml(s:dein_dir . '/plugins.toml', {'lazy': 0})
  call dein#load_toml(s:dein_dir . '/lazy_load_plugins.toml', {'lazy': 1})

  call dein#add('gosukiwi/vim-atom-dark', { 'script_type' : 'colors'})

  call dein#end()
  call dein#save_state()
endif

filetype plugin indent on
colorscheme atom-dark
syntax enable

if dein#check_install()
  call dein#install()
endif
