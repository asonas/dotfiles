"" 共通設定
syntax enable
let g:hybrid_use_Xresources = 1
colorscheme hybrid
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

autocmd FileType coffee set tabstop=2 shiftwidth=2

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
  colorscheme hybrid
endif

"------------------------------------
" Dash
" http://qiita.com/items/292e99a521a9653e75fb
"------------------------------------
function! s:dash(...)
  let ft = &filetype
  if &filetype == 'python'
    let ft = ft.'2'
  endif
  let ft = ft.':'
  let word = len(a:000) == 0 ? input('Dash search: ', ft.expand('<cword>')) : ft.join(a:000, ' ')
  call system(printf("open dash://'%s'", word))
endfunction
command! -nargs=* Dash call <SID>dash(<f-args>)

"------------------------------------
" 外部ファイル
"------------------------------------
" 補完関連
source ~/dotfiles/.vimrc.completion

" unite.vim
source ~/dotfiles/.vimrc.unite

" neobundle
source ~/dotfiles/.vimrc.neobundle

syntax on
