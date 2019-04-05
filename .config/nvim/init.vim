set number
filetype on

highlight ZenkakuSpace cterm=underline ctermfg=lightblue guibg=white
match ZenkakuSpace /　/

set autoread
set hidden
set noswapfile
set nobackup

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

let NERDTreeShowHidden = 1
let g:NERDTreeWinSize = 40
let g:python_host_prog = expand('/usr/bin/python')
let g:python3_host_prog = expand('/opt/brew/bin/python3')

if &compatible
  set nocompatible
endif

set runtimepath+=~/.vim/dein/repos/github.com/Shougo/dein.vim

call dein#begin(expand('~/dotfiles/.vim/dein'))

call dein#add('Shougo/dein.vim')
call dein#add('Shougo/vimproc.vim', {'build': 'make'})

call dein#add('Shougo/neocomplete.vim')
call dein#add('Shougo/neomru.vim')
call dein#add('scrooloose/nerdtree')
call dein#add('Shougo/neosnippet')
call dein#add('tpope/vim-fugitive')
call dein#add('ctrlpvim/ctrlp.vim')
call dein#add('flazz/vim-colorschemes')
call dein#add('tpope/vim-endwise.git')
call dein#add('vim-scripts/ruby-matchit')
call dein#add('vim-scripts/dbext.vim')
call dein#add('git@github.com:nathanaelkane/vim-indent-guides.git')
call dein#add('git@github.com:mattn/benchvimrc-vim.git')
call dein#add('Shougo/neocomplcache.git')
call dein#add('tomtom/tcomment_vim')
call dein#add('tpope/vim-surround')
call dein#add('vim-ruby/vim-ruby')
call dein#add('romanvbabenko/rails.vim')
call dein#add('Shougo/denite.nvim')
call dein#add('Shougo/unite.vim')
call dein#add('ujihisa/unite-rake')
call dein#add('sorah/unite-ghq')
call dein#add('basyura/unite-rails')
call dein#add('ujihisa/unite-gem')
call dein#add('taka84u9/unite-git')
call dein#add('sgur/unite-git_grep')
call dein#add('todesking/ruby_hl_lvar.vim')
call dein#add('git@github.com:todesking/ruby_hl_lvar.vim.git')
call dein#add('tomasr/molokai')

call dein#add('vim-scripts/haml.zip')
call dein#add('vim-scripts/JavaScript-syntax')
call dein#add('scrooloose/syntastic')
call dein#add('git@github.com:kchmck/vim-coffee-script.git')
call dein#add('git@github.com:groenewege/vim-less.git')
call dein#add('beyondwords/vim-twig')
call dein#add('git@github.com:slim-template/vim-slim.git')
call dein#add('git@github.com:rodjek/vim-puppet.git')

call dein#end()
