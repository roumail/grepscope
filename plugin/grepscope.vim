" grepscope: pick a project scope, then live grep in it with :Grep.
" Requires fzf-utils (:Grep, and through it fzf, fzf.vim and rg) and
" project-detect (the project name and type).
if exists('g:loaded_grepscope')
  finish
endif
let g:loaded_grepscope = 1

" Required plugins are checked once every plugin has loaded (VimEnter, or now
" when loaded later): their g:loaded_* guards tell whether they are installed.
" Without them nothing below is defined.
function! s:init() abort
  let l:missing = filter({
        \ 'junegunn/fzf': 'g:loaded_fzf',
        \ 'junegunn/fzf.vim': 'g:loaded_fzf_vim',
        \ 'roumail/fzf-utils': 'g:loaded_fzf_utils',
        \ 'roumail/project-detect': 'g:loaded_project_detect',
        \ }, '!exists(v:val)')
  if !executable('rg')
    let l:missing.rg = 1
  endif
  if !empty(l:missing)
    echohl WarningMsg
    echomsg 'grepscope: not loaded, requires ' . join(sort(keys(l:missing)), ', ')
    echohl None
    return
  endif

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
endfunction

if v:vim_did_enter
  call s:init()
else
  augroup grepscope_init
    autocmd!
    autocmd VimEnter * ++once call s:init()
  augroup END
endif
