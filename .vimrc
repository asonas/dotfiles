" 保存時に行末の空白を除去する
autocmd BufWritePre * :%s/\s\+$//ge

colorscheme railscasts

set number

imap <C-g> <esc>

" Don't screw up folds when inserting text that might affect them, until
" leaving insert mode. Foldmethod is local to the window. Protect against
" screwing up folding when switching between windows.
" http://d.hatena.ne.jp/gnarl/20120308/1331180615
autocmd InsertEnter * if !exists('w:last_fdm') | let w:last_fdm=&foldmethod | setlocal foldmethod=manual | endif
autocmd InsertLeave,WinLeave * if exists('w:last_fdm') | let &l:foldmethod=w:last_fdm | unlet w:last_fdm | endif

" 色の設定
syntax on

" 全角スペースを視覚化
highlight ZenkakuSpace cterm=underline ctermfg=lightblue guibg=white
match ZenkakuSpace /　/

"ステータスラインに文字コード/改行文字種別を表示
set statusline=%<%f\ %m%r%h%w%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}%=%l,%c%V%8P


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
let NERDTreeShowHidden = 1
let g:NERDTreeWinSize = 40

set fileformats=unix,dos,mac
" □とか○の文字があってもカーソル位置がずれないようにする
if exists('&ambiwidth')
  set ambiwidth=double
endif

" 補完関連
"source ~/dotfiles/.vimrc.completion

" unite.vim
source ~/dotfiles/.vimrc.unite

" neobundle
source ~/dotfiles/.vimrc.neobundle
