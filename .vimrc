"" 共通設定
syntax enable
colorscheme railscasts
set nocompatible
" Ctrl+cでエスケープ
imap <C-g> <esc>
imap <C-c> <esc>

"" file系
" 保存時に行末の空白を除去する
autocmd BufWritePre * :%s/\s\+$//ge
" 全角スペースを視覚化
highlight ZenkakuSpace cterm=underline ctermfg=lightblue guibg=white
match ZenkakuSpace /　/
set autoread
set hidden
set noswapfile
set nobackup
filetype on
filetype plugin on
filetype indent on
" 色の設定
set background=dark

"" 見た目
set number
set showmatch
set showcmd
set showmode
set nowrap
set list
set listchars=tab:>\
set scrolloff=5

"" ステータスライン
" ステータスラインに文字コード/改行文字種別を表示
set statusline=%<%f\ %m%r%h%w%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}%=%l,%c%V%8P
" 常にステータス行を表示
set laststatus=2

"" インデント
set tabstop=2 shiftwidth=2
set autoindent smarttab
" spaceがいい
set expandtab

"" 入力
set whichwrap=b,s,h,l,<,>,[,]
" バックスペースでインデントや改行を削除できるようにする
set backspace=2

"" 検索
set wrapscan
set ignorecase
set smartcase
set incsearch
set hlsearch

" 音がなる
"autocmd CursorMovedI * :call vimproc#system_bg($HOME . "/bin/vim-key-sound.rb '" . getline('.')[col('.') - 2] . "'")

" popup menu color
"hi Pmenu ctermbg=lightcyan ctermfg=black
"hi PmenuSel ctermbg=blue ctermfg=black
"hi PmenuSbar ctermbg=darkgray
"hi PmenuThumb ctermbg=lightgray

" 便利
nnoremap <silent> <Space>q :quit<CR>
nnoremap <silent> <Space>Q :quit!<CR>
nnoremap <silent> <Space>e :wq<CR>
nnoremap <silent> <Space><Space> :w<CR>
nnoremap <PageDown> <C-F>
nnoremap <PageUp> <C-B>
nnoremap <silent> <Space>j :tabn<CR>
nnoremap <silent> <Space>k :tabe<CR>
nnoremap <silent> <Space>l :tabp<CR>


" memo
set noruler
set showmatch
set wrap
set title
set backspace=2
set history=100
set noautochdir
set nobackup
set tw=0
au FileType ruby setlocal nowrap tabstop=8 tw=0 sw=2 expandtab

" Don't screw up folds when inserting text that might affect them, until
" leaving insert mode. Foldmethod is local to the window. Protect against
" screwing up folding when switching between windows.
" http://d.hatena.ne.jp/gnarl/20120308/1331180615
"autocmd InsertEnter * if !exists('w:last_fdm') | let w:last_fdm=&foldmethod | setlocal foldmethod=manual | endif
"autocmd InsertLeave,WinLeave * if exists('w:last_fdm') | let &l:foldmethod=w:last_fdm | unlet w:last_fdm | endif

" coffeescript javascript
"autocmd FileType coffee setlocal dictionary=$HOME/dotfiles/vimfiles/javascript.dict,$HOME/dotfiles/vimfiles/jQuery.dict
"autocmd FileType javascript,coffee setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType coffee set tabstop=2 shiftwidth=2

"if(){}などのインデント
"set cindent

"nnoremap <Esc><Esc> :set nohlsearch<CR>

"------------------------------------
" indent guides
"------------------------------------
hi IndentGuidesOdd  ctermbg=white
hi IndentGuidesEven ctermbg=lightgrey
let g:indent_guides_guide_size = 1
let g:indent_guides_enable_on_vim_startup = 1

"------------------------------------
" NERD Tree
"------------------------------------
nmap <silent> <F1> :NERDTreeToggle<CR>
nmap <silent> <Space>p :NERDTreeToggle<CR>
let NERDTreeShowHidden = 1
let g:NERDTreeWinSize = 40

set fileformats=unix,dos,mac
" □とか○の文字があってもカーソル位置がずれないようにする
if exists('&ambiwidth')
  set ambiwidth=double
endif

"------------------------------------
" MacVim
"------------------------------------
if has('gui_macvim')
  colorscheme zenburn
endif

" 補完関連
source ~/dotfiles/.vimrc.completion

" unite.vim
source ~/dotfiles/.vimrc.unite

" neobundle
source ~/dotfiles/.vimrc.neobundle

syntax on
