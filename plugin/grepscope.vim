" grepscope: pick a project scope, then live grep in it with :Grep.
" Requires fzf-utils-rg (:Grep) and project-detect (the project name and type).
if exists('g:loaded_grepscope')
  finish
endif
" Required plugins: without them nothing here is defined
let s:missing = filter({
      \ 'roumail/fzf-utils-rg': 'autoload/fzf_utils/live_grep.vim',
      \ 'roumail/project-detect': 'autoload/project_detect.vim',
      \ }, 'empty(globpath(&rtp, v:val))')
if !empty(s:missing)
  echohl WarningMsg
  echomsg 'grepscope: not loaded, requires ' . join(sort(keys(s:missing)), ', ')
  echohl None
  finish
endif
unlet s:missing
let g:loaded_grepscope = 1

" GrepScope: Interactive scope picker for grep
"
" Presents a menu of search scopes: 'all', plus the scopes registered with
" grepscope#register() for the project type project-detect found.
" No scopes ship here.
"
" Falls back to :Grep if no project is detected.
"
" Examples:
"   :GrepScope pattern
"   :GrepScope
command! -nargs=* GrepScope call grepscope#run(<f-args>)

" <Plug> mappings; no keys are bound here (see README)
nnoremap <silent> <Plug>(grepscope) <Cmd>GrepScope<CR>
" The word under the cursor / the selection, with word boundaries
nnoremap <silent> <Plug>(grepscope-word) <Cmd>call grepscope#run(grepscope#word_pattern())<CR>
xnoremap <silent> <Plug>(grepscope-word) <Cmd>call grepscope#run(grepscope#word_pattern())<CR>
