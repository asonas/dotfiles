" 保存時に行末の空白を除去する
autocmd BufWritePre * :%s/\s\+$//ge
" 保存時にtabをスペースに変換する
autocmd BufWritePre * :%s/\t/ /ge

colorscheme zenburn
set number

imap <C-g> <esc>

" -------------------
" 色の設定
" -------------------
syntax on

" 全角スペースを視覚化
highlight ZenkakuSpace cterm=underline ctermfg=lightblue guibg=white
match ZenkakuSpace /　/

" タブ幅
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set autoindent

"常にステータス行を表示
set laststatus=2
"if(){}などのインデント
set cindent
"検索時にヒット部位の色を変更
set hlsearch
"検索時にインクリメンタルサーチを行う
set incsearch
set showmode
set cursorline
set whichwrap=b,s,h,l,<,>,[,]
"Escの2回押しでハイライト消去
nmap <ESC><ESC> ;nohlsearch<CR><ESC>

set ignorecase
set showmatch
set backspace=2
set title
set ruler

"ステータスラインに文字コード/改行文字種別を表示
set statusline=%<%f\ %m%r%h%w%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}%=%l,%c%V%8P

"補完関連
source ~/dotfiles/.vimrc.completion

set fileformats=unix,dos,mac
" □とか○の文字があってもカーソル位置がずれないようにする
if exists('&ambiwidth')
  set ambiwidth=double
endif

"------------------------------------
" NERD Tree
"------------------------------------
" 表示
nmap <silent> <F1> :NERDTreeToggle<CR>
let NERDTreeShowHidden = 1
let g:NERDTreeWinSize = 40

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" My Bundles here:
"
" original repos on github
Bundle 'vim-ruby/vim-ruby'
Bundle 'tpope/vim-fugitive'
Bundle 'Lokaltog/vim-easymotion'
Bundle 'rstacruz/sparkup', {'rtp': 'vim/'}
Bundle 'tpope/vim-rails.git'
" non github repos
Bundle 'git://git.wincent.com/command-t.git'
" ...
filetype plugin indent on     " required!
Bundle 'tpope/vim-rails'
Bundle 'Shougo/neocomplcache'
Bundle 'Shougo/unite.vim'
Bundle 'gtags.vim'

"
" Brief help
" :BundleList          - list configured bundles
" :BundleInstall(!)    - install(update) bundles
" :BundleSearch(!) foo - search(or refresh cache first) for foo
" :BundleClean(!)      - confirm(or auto-approve) removal of unused bundles
"
" see :h vundle for more details or wiki for FAQ
" NOTE: comments after Bundle command are not allowed..
