" 保存時に行末の空白を除去する
autocmd BufWritePre * :%s/\s\+$//ge
" 保存時にtabをスペースに変換する
autocmd BufWritePre * :%s/\t/ /ge

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

"ステータスラインに文字コード/改行文字種別を表示
set statusline=%<%f\ %m%r%h%w%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}%=%l,%c%V%8P

"補完関連
"source ~/dotfiles/.vimrc.completion

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
Bundle 'tpope/vim-rails.git'
" ...
filetype plugin indent on     " required!
Bundle 'Shougo/neocomplcache'
Bundle 'Shougo/unite.vim'
Bundle 'gtags.vim'
"Bundle 'Lokaltog/vim-powerline'
Bundle 'scrooloose/syntastic'


" Completion {{{
  " 補完 neocomplcache.vim : 究極のVim的補完環境
  Bundle 'Shougo/neocomplcache'
  " neocomplcacheのsinpet補完
  Bundle 'Shougo/neocomplcache-snippets-complete'
" }}}

" Searching/Moving{{{
  " smooth_scroll.vim : スクロールを賢く
  "Bundle 'Smooth-Scroll'
  " vim-smartword : 単語移動がスマートな感じで
"  Bundle 'smartword'
  " camelcasemotion : CamelCaseやsnake_case単位でのワード移動
"  Bundle 'camelcasemotion'
  " <Leader><Leader>w/fなどで、motion先をhilightする
  Bundle 'EasyMotion'
  " matchit.vim : 「%」による対応括弧へのカーソル移動機能を拡張
  Bundle 'matchit.zip'
  " ruby用のmatchit拡張
  Bundle 'ruby-matchit'
  " grep.vim : 外部のgrep利用。:Grepで対話形式でgrep :Rgrepは再帰
  Bundle 'grep.vim'
  " eregex.vim : vimの正規表現をrubyやperlの正規表現な入力でできる :%S/perlregex/
  Bundle 'eregex.vim'
  " open-browser.vim : カーソルの下のURLを開くor単語を検索エンジンで検索
  Bundle 'tyru/open-browser.vim'

" Syntax {{{
  " haml
  Bundle 'haml.zip'
  " JavaScript
  Bundle 'JavaScript-syntax'
  " jQuery
  Bundle 'jQuery'
  " nginx conf
  Bundle 'nginx.vim'
  " markdown
  Bundle 'tpope/vim-markdown'
  " coffee script
  Bundle 'kchmck/vim-coffee-script'
  " python
  Bundle 'yuroyoro/vim-python'
  " syntax checking plugins exist for eruby, haml, html, javascript, php, python, ruby and sass.
  Bundle 'scrooloose/syntastic'
" }}}
Bundle 'mattn/benchvimrc-vim'

"
" Brief help
" :BundleList          - list configured bundles
" :BundleInstall(!)    - install(update) bundles
" :BundleSearch(!) foo - search(or refresh cache first) for foo
" :BundleClean(!)      - confirm(or auto-approve) removal of unused bundles
"
" see :h vundle for more details or wiki for FAQ
" NOTE: comments after Bundle command are not allowed..
