"" 共通設定
colorscheme pyte

"------------------------------------
" MacVim
"------------------------------------
if has('gui_macvim')
  colorscheme pyte
endif

set nocompatible
imap <C-g> <esc>

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
"set background=dark

"" 見た目
set number
set showmatch
set showcmd
set showmode
set nowrap
set list
set listchars=tab:>\
set scrolloff=5
set guifont=SourceCodePro-Regular:h12

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
nnoremap <silent> <Space>l :tabp<CR>
nnoremap <silent> <Space>t :tabe<CR>
nnoremap <silent> <Space>n :sp<CR>
nnoremap <silent> <Space>m :vs<CR>
set clipboard=unnamed

imap <C-p> <Up>
imap <C-n> <Down>
imap <C-b> <Left>
imap <C-f> <Right>
imap <C-a> <C-o>:call <SID>home()<CR>
imap <C-e> <End>
imap <C-d> <Del>
imap <C-h> <BS>
imap <C-k> <C-r>=<SID>kill()<CR>

function! s:home()
  let start_column = col('.')
  normal! ^
  if col('.') == start_column
  ¦ normal! 0
  endif
  return ''
endfunction

function! s:kill()
  let [text_before, text_after] = s:split_line()
  if len(text_after) == 0
  ¦ normal! J
  else
  ¦ call setline(line('.'), text_before)
  endif
  return ''
endfunction

function! s:split_line()
  let line_text = getline(line('.'))
  let text_after  = line_text[col('.')-1 :]
  let text_before = (col('.') > 1) ? line_text[: col('.')-2] : ''
  return [text_before, text_after]
endfunction

"nnoremap ] :<C-u>set transparency=
"noremap <Up> :<C-u>set transparency+=5<Cr>
"noremap <Down> :<C-u>set transparency-=5<Cr>

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

let g:vim_json_syntax_conceal = 0

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
nmap <silent> <Space>p :NERDTreeToggle<CR>
let NERDTreeShowHidden = 1
let g:NERDTreeWinSize = 40

set fileformats=unix,dos,mac
" □とか○の文字があってもカーソル位置がずれないようにする
if exists('&ambiwidth')
  set ambiwidth=double
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
source ~/.vimrc.completion

" denite.vim
source ~/.vimrc.denite

source ~/.vimrc.dein

syntax on
