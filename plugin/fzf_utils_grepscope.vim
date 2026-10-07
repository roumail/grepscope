" fzf-utils-grepscope: pick a project scope, then live grep in it with :Grep.
" Requires junegunn/fzf and fzf-utils-rg (:Grep). Project names come from
" project-detect when it is installed.
if exists('g:loaded_fzf_utils_grepscope')
  finish
endif
let g:loaded_fzf_utils_grepscope = 1

" GrepScope: Interactive scope picker for grep
"
" Presents a menu of search scopes: 'all', plus the scopes registered with
" fzf_utils#rg_scope#register() for the project type project-detect found.
" No scopes ship here.
"
" Falls back to :Grep if no project is detected.
"
" Examples:
"   :GrepScope pattern
"   :GrepScope
command! -nargs=* GrepScope call fzf_utils#rg_scope#run(<f-args>)

" <Plug> mappings; no keys are bound here (see README)
nnoremap <silent> <Plug>(fzf-utils-grepscope) <Cmd>GrepScope<CR>
" The word under the cursor / the selection, with word boundaries
nnoremap <silent> <Plug>(fzf-utils-grepscope-word) <Cmd>execute 'GrepScope' '\b' . expand('<cword>') . '\b'<CR>
xnoremap <silent> <Plug>(fzf-utils-grepscope-word) y:<C-u>execute 'GrepScope' '\b' . getreg('"') . '\b'<CR>
