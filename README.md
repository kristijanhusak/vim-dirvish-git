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

## Mappings
Following mappings are available by default:

`]f` - jump to next "git" file
`[f` - jump to previous "git" file

To change mappings to use for example `<C-n>` for next and `<C-p>` for previous file add this to your vimrc:

```vimL
autocmd vimrc FileType dirvish nmap <silent><buffer><C-n> <Plug>(dirvish_git_next_file)
autocmd vimrc FileType dirvish nmap <silent><buffer><C-p> <Plug>(dirvish_git_prev_file)
```

## Customization
Ignored files are not marked by default. If you want them to be marked, add this to your vimrc:

```vimL
let g:dirvish_git_show_ignored = 1
```

These are default indicators used that can be overridden in vimrc:

```vimL
  let g:dirvish_git_indicators = {
  \ 'Modified'  : '✹',
  \ 'Staged'    : '✚',
  \ 'Untracked' : '✭',
  \ 'Renamed'   : '➜',
  \ 'Unmerged'  : '═',
  \ 'Ignored'   : '☒',
  \ 'Unknown'   : '?'
  \ }
```

To change font color you can update any of these highlighting groups.

Here's short example how it's set up by default:
```vimL
  let l:modified = 'guifg=#EBCB8B ctermfg=3'
  let l:added = 'guifg=#A3BE8C ctermfg=2'
  let l:unmerged = 'guifg=#BF616A ctermfg=1'

  silent exe 'hi default DirvishGitModified '.l:modified
  silent exe 'hi default DirvishGitStaged '.l:added
  silent exe 'hi default DirvishGitRenamed '.l:modified
  silent exe 'hi default DirvishGitUnmerged '.l:unmerged
  silent exe 'hi default DirvishGitIgnored guifg=NONE guibg=NONE gui=NONE cterm=NONE ctermfg=NONE ctermbg=NONE'
  silent exe 'hi default DirvishGitUntracked guifg=NONE guibg=NONE gui=NONE cterm=NONE ctermfg=NONE ctermbg=NONE'
  " Untracked dir linked to Dirvish default dir color
  silent exe 'hi default link DirvishGitUntrackedDir DirvishPathTail'
```

To override any of these, just add a highlight group to your vimrc.
Just make sure it's **after** your colorscheme setup

```vimL
colorscheme gruvbox
" Highlight dirvish modified files with blue color
hi DirvishGitModified guifg=#0000FF
```

Icons are shown by default, to hide the icons and only show the Git status with 
colors, add this to your vimrc:

```vimL
let g:dirvish_git_show_icons = 0
```

## Thanks to:
* [nerdtree-git-plugin](https://github.com/Xuyuanp/nerdtree-git-plugin)
