# grepscope

`:GrepScope [pattern]` shows a menu of search scopes for the current project,
then runs a live `:Grep` (from
[fzf-utils](https://github.com/roumail/fzf-utils)) in the one you pick.
`all` is always offered. With no project, or no scopes for it, `:GrepScope` is a
plain `:Grep`.

No keys are bound. These `<Plug>` mappings are provided for your vimrc:

| Mapping | Mode | Action |
| --- | --- | --- |
| `<Plug>(grepscope)` | n | `:GrepScope` |
| `<Plug>(grepscope-word)` | n, x | `:GrepScope` for the word under the cursor / the selection, matched literally |

```vim
nmap <leader>rs <Plug>(grepscope)
nmap <leader>rw <Plug>(grepscope-word)
xmap <leader>rw <Plug>(grepscope-word)
```

## Scopes

The scopes come from the project that
[project-detect](https://github.com/roumail/project-detect) finds: its type, and
where its code and tests live. For a Python project the menu is:

| Scope | Searches |
| --- | --- |
| `all` | everything |
| `project` | the package, e.g. `src/my_pkg/` |
| `project python` | the package, Python files only |
| `tests` | `tests/` |
| `tests python` | `tests/`, Python files only |

A Go project gets `project go`, `tests` (the `*_test.go` files) and `tests go`.
A scope is left out when it would search the same files as one above it.

### Your own scopes

To choose the scopes of a project type yourself, register a function for it.
It replaces the scopes above for that type:

```vim
function! s:python_scopes(name) abort
  return [
        \ ['project', [a:name . '/']],
        \ ['docs', ['docs/', '-tmd']],
        \ ]
endfunction

call grepscope#register('python', function('s:python_scopes'))
```

- `scopes(name)` gets the project name (`project_detect#name()`) and returns the
  menu entries in order, as `[label, rg-args]` pairs. Arguments ending in `/`
  are search paths, anything else is passed to ripgrep.
- The type (`'python'`) matches the project-detect strategy name.

## Mapping a single scope

To grep one scope without the menu:

| Function | What it does |
| --- | --- |
| `grepscope#invoke(label [, pattern])` | Live grep in the scope `label`. |
| `grepscope#invoke_word(label)` | Same, for the word under the cursor or, in visual mode, the selection. |
| `grepscope#word_pattern()` | That word / selection as a pattern: regex characters escaped, wrapped in `\b`. |

Both look the scope up when they are called, not when the mapping is made. So
you can define mappings straight away, for example in an ftplugin, even though
project-detect only names the project at `VimEnter`. Where the current project
has no such scope (or there is no project), they print
`GrepScope: no scope "<label>" for this project` and do nothing else.

```vim
" ~/.vim/ftplugin/python/keymaps.vim
nnoremap <buffer> <leader>rp <Cmd>call grepscope#invoke('project python')<CR>
nnoremap <buffer> gw <Cmd>call grepscope#invoke_word('project python')<CR>
xnoremap <buffer> gw <Cmd>call grepscope#invoke_word('project python')<CR>
```

## Install

Requires [fzf](https://github.com/junegunn/fzf), fzf.vim, fzf-utils,
project-detect and `rg`.
Required plugins are checked once every plugin has loaded, so the order of your
Plug lines doesn't matter. If one is missing, Vim shows
`grepscope: not loaded, requires …` at startup and the plugin defines nothing.

```vim
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'roumail/fzf-utils'
Plug 'roumail/project-detect'
Plug 'roumail/grepscope'
```
