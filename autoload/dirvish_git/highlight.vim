if !exists('g:dirvish_git_indicators')
  let g:dirvish_git_indicators = {
  \ 'Modified'  : '✹',
  \ 'Staged'    : '✚',
  \ 'Untracked' : '✭',
  \ 'Renamed'   : '➜',
  \ 'Unmerged'  : '═',
  \ 'Ignored'   : '☒',
  \ 'Unknown'   : '?'
  \ }
endif

let s:dirvish_git_highlight_groups = {
\ 'Modified'  : 'DirvishGitModified',
\ 'Staged'    : 'DirvishGitStaged',
\ 'Untracked' : 'DirvishGitUntracked',
\ 'Renamed'   : 'DirvishGitRenamed',
\ 'Unmerged'  : 'DirvishGitUnmerged',
\ 'Ignored'   : 'DirvishGitIgnored',
\ 'Unknown'   : 'DirvishGitModified'
\ }

let s:sep = dirvish_git#sep
let s:escape_chars = dirvish_git#escape_chars

function dirvish_git#highlight#get_highlight_groups() abort
  return s:dirvish_git_highlight_groups
endfunction

function! s:get_indicator_name(us, them) abort
  if a:us ==# '?' && a:them ==# '?'
    return 'Untracked'
  elseif a:us ==# ' ' && a:them ==# 'M'
    return 'Modified'
  elseif a:us =~# '[MAC]'
    return 'Staged'
  elseif a:us ==# 'R'
    return 'Renamed'
  elseif a:us ==# 'U' || a:them ==# 'U' || a:us ==# 'A' && a:them ==# 'A' || a:us ==# 'D' && a:them ==# 'D'
    return 'Unmerged'
  elseif a:us ==# '!'
    return 'Ignored'
  else
    return 'Unknown'
  endif
endfunction

function! dirvish_git#highlight#get_indicator(us, them) abort
  return get(g:dirvish_git_indicators, s:get_indicator_name(a:us, a:them), '')
endfunction

function! dirvish_git#highlight#get_highlight_group(us, them, is_directory) abort
  let l:group = get(s:dirvish_git_highlight_groups, s:get_indicator_name(a:us, a:them), 'DirvishGitModified')
  if !a:is_directory || l:group !=? 'DirvishGitUntracked'
    return l:group
  endif

  return 'DirvishGitUntrackedDir'
endfunction

function! dirvish_git#highlight#highlight_file(dir, file_name, us, them, is_directory) abort
  let l:file_rgx = escape(printf('\(%s\)\@<=%s%s', a:dir, s:sep, a:file_name), s:escape_chars)
  let l:dir_rgx = escape(printf('%s\(%s%s\)\@=', a:dir, s:sep, a:file_name), s:escape_chars)
  let l:slash_rgx = escape(printf('\(%s\)\@<=%s\(%s\)\@=', a:dir, s:sep, a:file_name), s:escape_chars)

  call dirvish_git#debug#log('[l:file_rgx] '. l:file_rgx)
  call dirvish_git#debug#log('[l:dir_rgx] '. l:dir_rgx)
  " Check if icons should be shown
  let l:conceal_char = g:dirvish_git_show_icons ? (' cchar=' . dirvish_git#highlight#get_indicator(a:us, a:them)) : ''
  let l:conceal_last_folder_char = g:dirvish_git_show_icons ? ' cchar= ' : ''

  silent exe 'syn match DirvishGitDir "'.l:dir_rgx.'" conceal ' . l:conceal_char
  silent exe 'syn match '. dirvish_git#highlight#get_highlight_group(a:us, a:them, a:is_directory).' "'.l:file_rgx.'" contains=DirvishGitSlash'
  silent exe 'syn match DirvishGitSlash "'.l:slash_rgx.'" conceal contained' . l:conceal_last_folder_char
endfunction

function! dirvish_git#highlight#setup_highlighting() abort
  for l:highlight_group in values(s:dirvish_git_highlight_groups)
    silent! exe 'syntax clear '.l:highlight_group
  endfor

  let l:modified = 'guifg=#fabd2f ctermfg=214'
  let l:added = 'guifg=#b8bb26 ctermfg=142'
  let l:unmerged = 'guifg=#fb4934 ctermfg=167'

  silent exe 'hi default DirvishGitModified '.l:modified
  silent exe 'hi default DirvishGitStaged '.l:added
  silent exe 'hi default DirvishGitRenamed '.l:modified
  silent exe 'hi default DirvishGitUnmerged '.l:unmerged
  silent exe 'hi default link DirvishGitUntrackedDir DirvishPathTail'
  silent exe 'hi default DirvishGitIgnored guifg=NONE guibg=NONE gui=NONE cterm=NONE ctermfg=NONE ctermbg=NONE'
  silent exe 'hi default DirvishGitUntracked guifg=NONE guibg=NONE gui=NONE cterm=NONE ctermfg=NONE ctermbg=NONE'
endfunction
