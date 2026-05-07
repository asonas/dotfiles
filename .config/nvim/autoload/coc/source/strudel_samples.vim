" coc.nvim custom source: strudel-rb sample names
" Triggers only inside sound("...") / s("...") / sound('...') / s('...')
" in Ruby buffers. Caches the sample list per session.
" Clear the cache with :StrudelReloadSamples

let s:cache = v:null

function! s:find_script() abort
  let dir = expand('%:p:h')
  if empty(dir)
    let dir = getcwd()
  endif
  let path = findfile('bin/strudel-samples', dir . ';')
  if empty(path)
    return get(g:, 'strudel_samples_command', '')
  endif
  return fnamemodify(path, ':p')
endfunction

function! s:load_samples() abort
  if type(s:cache) == v:t_list
    return s:cache
  endif
  let script = s:find_script()
  if empty(script) || !executable(script)
    let s:cache = []
    return s:cache
  endif
  let s:cache = systemlist(script)
  if v:shell_error != 0
    let s:cache = []
  endif
  return s:cache
endfunction

function! coc#source#strudel_samples#init() abort
  return {
    \ 'priority': 99,
    \ 'shortcut': 'strudel',
    \ 'filetypes': ['ruby'],
    \ 'triggerCharacters': ['"', "'", ' '],
    \ }
endfunction

function! coc#source#strudel_samples#should_complete(opt) abort
  let line = getline('.')
  let col = col('.') - 1
  let before = strpart(line, 0, col)
  " Inside sound("...") / s("...") / double or single quotes, unclosed.
  return before =~# '\v(^|\W)(sound|s)\(\s*["''][^"'']*$'
endfunction

function! coc#source#strudel_samples#complete(opt, cb) abort
  let items = map(copy(s:load_samples()), '{"word": v:val, "menu": "[strudel]"}')
  call a:cb(items)
endfunction

command! StrudelReloadSamples let s:cache = v:null | echo '[strudel] sample cache cleared'
