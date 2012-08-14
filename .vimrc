" 保存時に行末の空白を除去する
autocmd BufWritePre * :%s/\s\+$//ge

colorscheme railscasts
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

set ignorecase
set showmatch
set backspace=2
set title
set ruler

nnoremap <Esc><Esc> :set nohlsearch<CR>

"ステータスラインに文字コード/改行文字種別を表示
set statusline=%<%f\ %m%r%h%w%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}%=%l,%c%V%8P

"補完関連
"source ~/dotfiles/.vimrc.completion

" unite.vim
source ~/dotfiles/.vimrc.unite

set fileformats=unix,dos,mac
" □とか○の文字があってもカーソル位置がずれないようにする
if exists('&ambiwidth')
  set ambiwidth=double
endif

"
" indent guides
"
hi IndentGuidesOdd  ctermbg=white
hi IndentGuidesEven ctermbg=lightgrey
let g:indent_guides_guide_size = 1
let g:indent_guides_enable_on_vim_startup = 1

"------------------------------------
" NERD Tree
"------------------------------------
" 表示
nmap <silent> <F1> :NERDTreeToggle<CR>
let NERDTreeShowHidden = 1
let g:NERDTreeWinSize = 40


"------------------------------------
" NeoBundle
"------------------------------------
set nocompatible               " Be iMproved
filetype off                   " Required!
filetype plugin indent off     " Required!

if has('vim_starting')
  set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

call neobundle#rc(expand('~/.vim/bundle/'))
" My Bundles here:
"
" original repos on github
NeoBundle 'vim-ruby/vim-ruby'
NeoBundle 'tpope/vim-rails.git'
" ...
filetype plugin indent on     " required!
NeoBundle 'Shougo/neocomplcache'
NeoBundle 'Shougo/unite.vim'
NeoBundle 'gtags.vim'
NeoBundle 'scrooloose/syntastic'
NeoBundle 'nathanaelkane/vim-indent-guides'

" Completion {{{
  " neocomplcacheのsinpet補完
  NeoBundle 'Shougo/neocomplcache-snippets-complete'
" }}}

" Searching/Moving{{{
  " smooth_scroll.vim : スクロールを賢く
  NeoBundle 'Smooth-Scroll'
  " vim-smartword : 単語移動がスマートな感じで
  NeoBundle 'smartword'
  " matchit.vim : 「%」による対応括弧へのカーソル移動機能を拡張
  NeoBundle 'matchit.zip'
  " ruby用のmatchit拡張
  NeoBundle 'ruby-matchit'
  " eregex.vim : vimの正規表現をrubyやperlの正規表現な入力でできる :%S/perlregex/
  NeoBundle 'eregex.vim'
  " open-browser.vim : カーソルの下のURLを開くor単語を検索エンジンで検索
  NeoBundle 'tyru/open-browser.vim'

" Syntax {{{
  " haml
  NeoBundle 'haml.zip'
  " JavaScript
  NeoBundle 'JavaScript-syntax'
  " jQuery
  NeoBundle 'jQuery'
  " nginx conf
  NeoBundle 'nginx.vim'
  " markdown
  NeoBundle 'tpope/vim-markdown'
  " coffee script
  NeoBundle 'kchmck/vim-coffee-script'
  " python
  NeoBundle 'yuroyoro/vim-python'
  " syntax checking plugins exist for eruby, haml, html, javascript, php, python, ruby and sass.
  NeoBundle 'scrooloose/syntastic'
" }}}
NeoBundle 'mattn/benchvimrc-vim'
