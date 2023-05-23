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
nnoremap <silent> <Space>r :Denite file/rec<CR>

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

let g:ruby_host_prog = '~/.rbenv/versions/3.1/bin/neovim-ruby-host'

" Ward off unexpected things that your distro might have made, as
" well as sanely reset options when re-sourcing .vimrc
set nocompatible

" Set Dein base path (required)
let s:dein_base = '~/.local/share/dein'

" Set Dein source path (required)
let s:dein_src = '~/.local/share/dein/repos/github.com/Shougo/dein.vim'

" Set Dein runtime path (required)
execute 'set runtimepath+=' . s:dein_src

" Call Dein initialization (required)
call dein#begin(s:dein_base)

call dein#add(s:dein_src)

call dein#load_toml('~/.config/nvim/plugins.toml', {'lazy': 0})
call dein#load_toml('~/.config/nvim/lazy_load_plugins.toml', {'lazy': 1})
call dein#add('Shougo/ddu.vim')
call dein#add('Shougo/ddu-ui-ff')
call dein#add('Shougo/ddu-kind-file')
call dein#add('Shougo/ddu-filter-matcher_substring')
call dein#add('Shougo/ddc-source-around')
call dein#add('Shougo/ddc-ui-native')
call dein#add('Shougo/ddc-matcher_head')
call dein#add('Shougo/ddc-sorter_rank')

call dein#end()
call dein#save_state()

" Attempt to determine the type of a file based on its name and possibly its
" contents. Use this to allow intelligent auto-indenting for each filetype,
" and for plugins that are filetype specific.
if has('filetype')
  filetype indent plugin on
endif

" Enable syntax highlighting
if has('syntax')
  syntax on
endif

" Uncomment if you want to install not-installed plugins on startup.
if dein#check_install()
 call dein#install()
endif

filetype plugin indent on
colorscheme atom-dark
syntax enable

autocmd FileType js setlocal sw=2 sts=2 et
autocmd FileType yml  setlocal sw=2 sts=2 et
autocmd FileType yaml setlocal sw=2 sts=2 ts=2 et
autocmd FileType lua setlocal sw=2 sts=2 et
autocmd BufNewFile,BufRead *.schema set filetype=ruby
autocmd BufNewFile,BufRead Schemafile set filetype=ruby
autocmd BufNewFile,BufRead *.iam set filetype=ruby
autocmd BufNewFile,BufRead *.html setlocal tabstop=2 shiftwidth=2

" let g:neocomplcache_enable_auto_select = 0
" let g:neocomplete#enable_at_startup = 1
" let g:neocomplete#enable_smart_case = 1
" let g:neocomplete#min_keyword_length = 3
" let g:neocomplete#enable_auto_delimiter = 1
" let g:neocomplete#auto_completion_start_length = 1
" inoremap <expr><BS> neocomplete#smart_close_popup()."<C-h>"

let g:rustfmt_autosave = 1

function! s:AfterSaveRspec()
  let filename = expand('%')
  let line = line('.')
  let filename_with_line = filename . ':' . line
  call system('echo "' . filename_with_line . '" | nc -v 0.0.0.0 3002')
endfunction

exe 'autocmd BufWritePost *_spec.rb call s:AfterSaveRspec()'

source ~/.config/nvim/coc.vim
" source ~/.config/nvim/ddu.vim
source ~/.config/nvim/ddc.vim
source ~/.config/nvim/private.vim
