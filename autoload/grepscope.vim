" Registered scopes per project type, replacing the ones built from the
" project layout. A scopes function takes the project name and returns ordered
" [label, rg-args] pairs.
let s:scopes = {}

function! grepscope#register(type, scopes) abort
  let s:scopes[a:type] = a:scopes
endfunction

" Project types with registered scopes
function! grepscope#types() abort
  return sort(keys(s:scopes))
endfunction

" [label, rg-args] pairs of the detected project; empty when there is none
function! s:project_scopes() abort
  let l:type = project_detect#active()
  let l:name = project_detect#name()
  if empty(l:type) || empty(l:name)
    return []
  endif
  if has_key(s:scopes, l:type)
    return s:scopes[l:type](l:name)
  endif
  return s:layout_scopes(l:type)
endfunction

" rg arguments searching a:places (project-detect's directories and file
" globs, relative to the project root). Directories become search paths, globs
" -g filters; with no directory the whole root is searched.
function! s:rg_args(root, places) abort
  let l:dirs = filter(copy(a:places), 'v:val =~# "/$"')
  let l:globs = filter(copy(a:places), 'v:val !~# "/$"')
  if empty(l:dirs) && a:root !=# getcwd()
    let l:dirs = ['']
  endif
  " Relative to the working directory where possible; absolute paths otherwise
  let l:paths = map(l:dirs, 'fnamemodify(a:root . "/" . v:val, ":.")')
  let l:paths = map(l:paths, 'v:val =~# "/$" ? v:val : v:val . "/"')
  " live grep passes flags to the shell as they are: quote the glob
  return l:paths + map(l:globs, '"-g" . shellescape(v:val)')
endfunction

" Whether rg has a file type a:type (-t), from rg --type-list
function! s:rg_has_type(type) abort
  if !exists('s:rg_types')
    let s:rg_types = map(systemlist('rg --type-list'), 'matchstr(v:val, ''^[^:]\+'')')
  endif
  return index(s:rg_types, a:type) >= 0
endfunction

" Scopes from the project layout: its code and its tests, each also limited to
" the project's language when the project type is an rg file type ('python',
" 'go'). A scope that adds nothing to an earlier one is left out.
function! s:layout_scopes(type) abort
  let l:root = project_detect#root()
  let l:typed = s:rg_has_type(a:type)
  let l:places = [['project', project_detect#sources()]]
  if !empty(project_detect#tests())
    call add(l:places, ['tests', project_detect#tests()])
  endif
  let l:candidates = []
  for [l:label, l:where] in l:places
    let l:args = s:rg_args(l:root, l:where)
    call add(l:candidates, [l:label, l:args])
    if l:typed
      call add(l:candidates, [l:label . ' ' . a:type, l:args + ['-t' . a:type]])
    endif
  endfor
  let l:scopes = []
  let l:seen = [[]]
  for [l:label, l:args] in l:candidates
    if index(l:seen, l:args) < 0
      call add(l:scopes, [l:label, l:args])
      call add(l:seen, l:args)
    endif
  endfor
  return l:scopes
endfunction

" 'all' plus the detected project's scopes, in menu order
function! s:scope_list() abort
  return [['all', []]] + s:project_scopes()
endfunction

" Scope label -> rg arguments
function! grepscope#scopes() abort
  let l:scopes = {}
  for [l:label, l:args] in s:scope_list()
    let l:scopes[l:label] = l:args
  endfor
  return l:scopes
endfunction

function! s:rg_scope_sink(choice) abort
  call grepscope#invoke(a:choice, s:current_search_pattern)
endfunction

function! grepscope#invoke(scope_name, ...) abort
  let pattern = a:0 > 0 ? a:1 : ''
  let scopes = grepscope#scopes()
  if !has_key(scopes, a:scope_name)
    echo 'GrepScope: no scope "' . a:scope_name . '" for this project'
    return
  endif
  let scope = scopes[a:scope_name]

  " Build arguments array matching the DSL: pattern -- scope
  " If pattern is '--' or empty, treat it as an empty list, otherwise wrap it
  let pattern_part = (pattern ==# '--' || empty(pattern)) ? [] : [pattern]

  " Concatenate: [pattern?] + ['--'] + [scopes?]
  let args = pattern_part + ['--'] + scope
  call call('fzf_utils#rg#live_grep#window', args)
endfunction

function! grepscope#run(...) abort
  " Validate arguments - only accept 0 or 1 argument
  if a:0 > 1
    echoerr 'Too many arguments. Usage: :GrepScope [pattern]'
    echoerr 'Did you mean to use :Grep instead? (supports -- separator and options)'
    return
  endif
  " No project: a plain :Grep over everything
  if empty(s:project_scopes())
    if a:0 > 0
      call fzf_utils#rg#live_grep#window(a:1)
    else
      call fzf_utils#rg#live_grep#window()
    endif
    return
  endif


  let s:current_search_pattern = a:0 > 0 ? a:1 : '--'
  let s:rg_scope_order = map(s:scope_list(), 'v:val[0]')

  let choice = fzf#run(fzf#wrap({
        \ 'source': s:rg_scope_order,
        \ 'sink': function('s:rg_scope_sink')
        \ }))
endfunction

" The selection in visual mode, else the word under the cursor, as a ripgrep
" regex with word boundaries. Regex characters in it are escaped, so it matches
" literally (live grep starts in regex mode).
function! grepscope#word_pattern() abort
  let l:mode = mode()
  if l:mode =~# "^[vV\<C-v>]"
    if exists('*getregion')
      let l:text = join(getregion(getpos('v'), getpos('.'), {'type': l:mode}), "\n")
    else
      let l:save = [getreg('"'), getregtype('"')]
      normal! y
      let l:text = getreg('"')
      call setreg('"', l:save[0], l:save[1])
    endif
    execute "normal! \<Esc>"
  else
    let l:text = expand('<cword>')
  endif
  return '\b' . escape(l:text, '\.^$*+?()[]{}|') . '\b'
endfunction

" Grep a scope for the word under the cursor / the selection, without the menu
function! grepscope#invoke_word(scope_name) abort
  call grepscope#invoke(a:scope_name, grepscope#word_pattern())
endfunction
