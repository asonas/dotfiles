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

nnoremap <silent> <Space>t :<C-u>DeniteProjectDir file/rec/git -start-filter<CR>
