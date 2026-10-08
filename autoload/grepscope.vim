" Scopes per project type. A scopes function takes the project name and
" returns ordered [label, rg-args] pairs.
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
  if empty(l:type) || empty(l:name) || !has_key(s:scopes, l:type)
    return []
  endif
  return s:scopes[l:type](l:name)
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
