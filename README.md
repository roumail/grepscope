# fzf-utils-grepscope

`:GrepScope [pattern]` shows a menu of search scopes for the current project,
then runs a live `:Grep` (from
[fzf-utils-rg](https://github.com/roumail/fzf-utils-rg)) in the one you pick.
`all` is always offered. With no project, or no scopes for it, `:GrepScope` is a
plain `:Grep`.

| Keys | Mode | Action |
| --- | --- | --- |
| `<leader>rs` | n | `:GrepScope` |
| `<leader>rw` | n, x | `:GrepScope` for the word under the cursor / selection |

`let g:fzf_utils_no_mappings = 1` skips them.

## Scopes

The plugin ships no scopes. You register them per project type; the type and the
project name come from [project-detect](https://github.com/roumail/project-detect):

```vim
function! s:python_scopes(name) abort
  return [
        \ ['project', [a:name . '/']],
        \ ['project python', [a:name . '/', '-tpy']],
        \ ['tests', ['tests/']],
        \ ]
endfunction

call fzf_utils#rg_scope#register('python', function('s:python_scopes'))
```

- `scopes(name)` gets `g:project_name` and returns the menu entries in order, as
  `[label, rg-args]` pairs. Arguments ending in `/` are search paths, anything
  else is passed to ripgrep.
- The type (`'python'`) matches the project-detect strategy name.
- `fzf_utils#rg_scope#invoke(label [, pattern])` greps a scope without the menu,
  for mappings.

For a complete setup (pyproject.toml detection plus these scopes), see
[`custom/plugins/fzf/grepscope.vim`](https://github.com/roumail/dotfiles/blob/main/vim-rc/custom/plugins/fzf/grepscope.vim)
in roumail/dotfiles.

## Install

Requires [fzf](https://github.com/junegunn/fzf), fzf.vim, fzf-utils-rg and `rg`.
project-detect is optional: without it there are no project scopes.

```vim
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'roumail/fzf-utils-rg'
Plug 'roumail/project-detect'
Plug 'roumail/fzf-utils-grepscope'
```
