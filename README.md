# vim-dirvish-git

Plugin for [dirvish.vim](https://github.com/justinmk/vim-dirvish) that shows git status flags.
Same as [nerdtree-git-plugin](https://github.com/Xuyuanp/nerdtree-git-plugin) for [NERDTree](https://github.com/scrooloose/nerdtree).

Currently tested only on Linux.

![screenshot](https://i.imgur.com/izrVegA.png)

## Requirements

* [dirvish.vim](https://github.com/justinmk/vim-dirvish)
* (Neo)Vim with `conceal` feature (`has('conceal')` should return `1`)
* git

## Installation
Install the plugin alongside [dirvish.vim](https://github.com/justinmk/vim-dirvish) with your favorite plugin manager.

I'm using [vim-plug](https://github.com/junegunn/vim-plug)

```vimL
Plug 'justinmk/vim-dirvish'
Plug 'kristijanhusak/vim-dirvish-git'
```

Thats it!

## Customization
These are default indicators used that can be overridden in vimrc:

```vimL
  let g:dirvish_git_indicators = {
  \ 'Modified'  : '✹',
  \ 'Staged'    : '✚',
  \ 'Untracked' : '✭',
  \ 'Renamed'   : '➜',
  \ 'Unmerged'  : '═',
  \ 'Deleted'   : '✖',
  \ 'Ignored'   : '☒',
  \ 'Unknown'   : '?'
  \ }
```

To change font color you can update any of these highlighting groups.

Defaults are taken from your current colorscheme `Diff*` highlights.

Here's short example how it's set up by default:
```vimL
  let l:diff_add = '#00FF00' " Taken from DiffAdd highlight group
  let l:diff_changed = '#0000FF' " Taken from DiffChange highlight group
  let l:diff_modified = '#F0000F' " Taken from DiffText highlight group
  let l:diff_deleted = '#FF0000' " Taken from DiffDelete highlight group

  silent exe 'hi default DirvishGitModified guifg='.l:diff_modified
  silent exe 'hi default DirvishGitStaged guifg='.l:diff_add
  silent exe 'hi default DirvishGitUntracked guifg=NONE guibg=NONE'
  silent exe 'hi default DirvishGitRenamed guifg='.l:diff_changed
  silent exe 'hi default DirvishGitUnmerged guifg='.l:diff_deleted
  silent exe 'hi default DirvishGitDeleted guifg='.l:diff_deleted
  silent exe 'hi default DirvishGitIgnored guifg=NONE guibg=NONE'
  "Untracked dir linked to Dirvish default dir color
  silent exe 'hi default link DirvishGitUntrackedDir DirvishPathTail'
```

To override any of these, just add a highlight group to your vimrc.
Just make sure it's **after** your colorscheme setup

```vimL
colorscheme gruvbox
" Highlight dirvish modified files with blue color
hi DirvishGitModified guifg=#0000FF
```

## Thanks to:
* [nerdtree-git-plugin](https://github.com/Xuyuanp/nerdtree-git-plugin)
