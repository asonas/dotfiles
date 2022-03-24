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

let g:ruby_host_prog = '/Users/asonas/.rbenv/versions/2.6/bin/neovim-ruby-host'

if &compatible
  set nocompatible
endif

set runtimepath+=~/.vim/dein/repos/github.com/Shougo/dein.vim

let s:dein_dir = expand('~/.vim/dein')

if dein#load_state(s:dein_dir)
  call dein#begin(s:dein_dir)

  call dein#load_toml(s:dein_dir . '/plugins.toml', {'lazy': 0})
  call dein#load_toml(s:dein_dir . '/lazy_load_plugins.toml', {'lazy': 1})

  call dein#end()
  call dein#save_state()
endif

filetype plugin indent on
colorscheme atom-dark
syntax enable

if dein#check_install()
  call dein#install()
endif

autocmd FileType js setlocal sw=2 sts=2 et
autocmd FileType yml  setlocal sw=2 sts=2 et
autocmd FileType yaml setlocal sw=2 sts=2 ts=2 et
autocmd BufNewFile,BufRead *.schema set filetype=ruby
autocmd BufNewFile,BufRead Schemafile set filetype=ruby
autocmd BufNewFile,BufRead *.iam set filetype=ruby

" Define mappings
autocmd FileType denite call s:denite_my_settings()
function! s:denite_my_settings() abort
  nnoremap <silent><buffer><expr> <CR>
  \ denite#do_map('do_action')
  nnoremap <silent><buffer><expr> d
  \ denite#do_map('do_action', 'delete')
  nnoremap <silent><buffer><expr> p
  \ denite#do_map('do_action', 'preview')
  nnoremap <silent><buffer><expr> q
  \ denite#do_map('quit')
  nnoremap <silent><buffer><expr> <Esc><Esc>
  \ denite#do_map('quit')
  nnoremap <silent><buffer><expr> i
  \ denite#do_map('open_filter_buffer')
  nnoremap <silent><buffer><expr> <Space>
  \ denite#do_map('toggle_select').'j'
endfunction

call denite#custom#option('default', 'prompt', '>')
call denite#custom#kind('file', 'default_action', 'split')
"call denite#custom#var('file/rec', 'command', ['ag', '--follow', '--nocolor', '--nogroup', '-g', ''])

call denite#custom#alias('source', 'file/rec/git', 'file/rec')
call denite#custom#var('file/rec/git', 'command', ['git', 'ls-files', '-co', '--exclude-standard'])

if executable("rg")
    call denite#custom#var('file/rec', 'command',
   \ ['rg', '--files', '--glob', '!.git', '--color', 'never'])
    call denite#custom#var('grep', {
   \ 'command': ['rg'],
   \ 'default_opts': ['-i', '--vimgrep', '--no-heading'],
   \ 'recursive_opts': [],
   \ 'pattern_opt': ['--regexp'],
   \ 'separator': ['--'],
   \ 'final_opts': [],
   \ })
endif

let s:denite_default_options = {}
call extend(s:denite_default_options, {
\   'highlight_matched_char': 'None',
\   'highlight_matched_range': 'Search',
\   'match_highlight': v:true,
\})
call denite#custom#option('default', s:denite_default_options)

nnoremap <silent> <Space>t :<C-u>DeniteProjectDir file/rec/git<CR>

let g:neocomplete#enable_at_startup = 1
let g:neocomplete#enable_smart_case = 1
let g:neocomplete#min_keyword_length = 3
let g:neocomplete#enable_auto_delimiter = 1
let g:neocomplete#auto_completion_start_length = 1
inoremap <expr><BS> neocomplete#smart_close_popup()."<C-h>"

source ~/.config/nvim/private.vim
