" Scopes per project type. A scopes function takes the project name and
" returns ordered [label, rg-args] pairs.
let s:scopes = {}

function! fzf_utils#rg_scope#register(type, scopes) abort
  let s:scopes[a:type] = a:scopes
endfunction

" Project types with registered scopes
function! fzf_utils#rg_scope#types() abort
  return sort(keys(s:scopes))
endfunction

" The project type from project-detect, or '' when it is not installed or
" nothing matched
function! s:project_type() abort
  if empty(globpath(&rtp, 'autoload/project_detect.vim'))
    return ''
  endif
  return project_detect#active()
endfunction

" [label, rg-args] pairs of the detected project; empty when there is none
function! s:project_scopes() abort
  let l:type = s:project_type()
  if empty(l:type) || !has_key(s:scopes, l:type) || !exists('g:project_name')
    return []
  endif
  return s:scopes[l:type](g:project_name)
endfunction

" 'all' plus the detected project's scopes, in menu order
function! s:scope_list() abort
  return [['all', []]] + s:project_scopes()
endfunction

" Scope label -> rg arguments
function! fzf_utils#rg_scope#scopes() abort
  let l:scopes = {}
  for [l:label, l:args] in s:scope_list()
    let l:scopes[l:label] = l:args
  endfor
  return l:scopes
endfunction

function! s:rg_scope_sink(choice) abort
  call fzf_utils#rg_scope#invoke(a:choice, s:current_search_pattern)
endfunction

function! fzf_utils#rg_scope#invoke(scope_name, ...) abort
  let pattern = a:0 > 0 ? a:1 : ''
  let scopes = fzf_utils#rg_scope#scopes()
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
  call call('fzf_utils#live_grep#window', args)
endfunction

function! fzf_utils#rg_scope#run(...) abort
  " Validate arguments - only accept 0 or 1 argument
  if a:0 > 1
    echoerr 'Too many arguments. Usage: :GrepScope [pattern]'
    echoerr 'Did you mean to use :Grep instead? (supports -- separator and options)'
    return
  endif
  " No project: a plain :Grep over everything
  if empty(s:project_scopes())
    if a:0 > 0
      call fzf_utils#live_grep#window(a:1)
    else
      call fzf_utils#live_grep#window()
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
function! fzf_utils#rg_scope#word_pattern() abort
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
function! fzf_utils#rg_scope#invoke_word(scope_name) abort
  call fzf_utils#rg_scope#invoke(a:scope_name, fzf_utils#rg_scope#word_pattern())
endfunction
