if !exists('g:dirvish_git_indicators')
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
endif

let s:dirvish_git_highlight_groups = {
\ 'Modified'  : 'DirvishGitModified',
\ 'Staged'    : 'DirvishGitStaged',
\ 'Untracked' : 'DirvishGitUntracked',
\ 'Renamed'   : 'DirvishGitRenamed',
\ 'Unmerged'  : 'DirvishGitUnmerged',
\ 'Deleted'   : 'DirvishGitDeleted',
\ 'Ignored'   : 'DirvishGitIgnored',
\ 'Unknown'   : 'DirvishGitModified'
\ }

function! dirvish_git#init() abort
  let l:status = systemlist('git status --porcelain '.expand('%'))

  if len(l:status) ==? 0 || (len(l:status) ==? 1 && l:status[0] =~? '^fatal')
    return 0
  endif

  call s:setup_highlighting()
  setlocal conceallevel=2
  let l:current_dir = expand('%')

  for l:item in l:status
    let l:data = matchlist(l:item, '\(.\)\(.\)\s\(.*\)')
    if len(l:data) <=? 0
      continue
    endif
    let l:us = l:data[1]
    let l:them = l:data[2]
    let l:file = l:data[3]

    if index(argv(), l:file) > -1
      continue
    endif

    if isdirectory(l:file)
      let l:file = fnamemodify(l:file, ':p')
      let l:file_name = substitute(l:file, l:current_dir, '', 'g')
      call s:highlight_file(l:current_dir[:-2], l:file_name, l:us, l:them, v:true)
    else
      let l:file = fnamemodify(l:file, ':p')
      let l:dir = fnamemodify(l:file, ':h')
      let l:file_name = fnamemodify(l:file, ':t')
      call s:highlight_file(l:dir, l:file_name, l:us, l:them, v:false)

      let l:file_dir = matchstr(l:file, escape(l:current_dir.'\zs[^/]*/\ze', './'))

      if l:file_dir !=? ''
        call s:highlight_file(l:current_dir[:-2], l:file_dir, l:us, l:them, v:true)
      endif
    endif
  endfor
endfunction

function s:get_indicator_name(us, them) abort
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
  elseif a:them ==# 'D'
    return 'Deleted'
  elseif a:us ==# '!'
    return 'Ignored'
  else
    return 'Unknown'
  endif
endfunction

function! s:get_indicator(us, them) abort
  return get(g:dirvish_git_indicators, s:get_indicator_name(a:us, a:them), '')
endfunction

function! s:get_highlight_group(us, them, is_directory) abort
  let l:group = get(s:dirvish_git_highlight_groups, s:get_indicator_name(a:us, a:them), 'DirvishGitModified')
  if !a:is_directory || l:group !=? 'DirvishGitUntracked'
    return l:group
  endif

  return 'DirvishGitUntrackedDir'
endfunction

function! s:highlight_file(dir, file_name, us, them, is_directory) abort
  let l:file_rgx = escape(printf('\(%s\)\@<=/%s', a:dir, a:file_name), './')
  let l:dir_rgx = escape(printf('%s\(/%s\)\@=', a:dir, a:file_name), './')
  let l:slash_rgx = escape(printf('\(%s\)\@<=/\(%s\)\@=', a:dir, a:file_name), './')

  silent exe 'syn match DirvishGitDir "'.l:dir_rgx.'" conceal cchar='.s:get_indicator(a:us, a:them)
  silent exe 'syn match '.s:get_highlight_group(a:us, a:them, a:is_directory).' "'.l:file_rgx.'" contains=DirvishGitSlash'
  silent exe 'syn match DirvishGitSlash "'.l:slash_rgx.'" conceal cchar= contained'
endfunction

function! s:setup_highlighting() abort
  let s:diff_modified_color = synIDattr(synIDtrans(hlID('DiffText')), 'reverse') ? 'fg' : 'bg'
  let s:diff_modified = synIDattr(synIDtrans(hlID('DiffText')), s:diff_modified_color)

  let s:diff_changed_color = synIDattr(synIDtrans(hlID('DiffChange')), 'reverse') ? 'fg' : 'bg'
  let s:diff_changed = synIDattr(synIDtrans(hlID('DiffChange')), s:diff_changed_color)

  let s:diff_add_color = synIDattr(synIDtrans(hlID('DiffAdd')), 'reverse') ? 'fg' : 'bg'
  let s:diff_add = synIDattr(synIDtrans(hlID('DiffAdd')), s:diff_add_color)

  let s:diff_deleted_color = synIDattr(synIDtrans(hlID('DiffDelete')), 'reverse') ? 'fg' : 'bg'
  let s:diff_deleted = synIDattr(synIDtrans(hlID('DiffDelete')), s:diff_deleted_color)

  silent exe 'hi default DirvishGitModified guifg='.s:diff_modified
  silent exe 'hi default DirvishGitStaged guifg='.s:diff_add
  silent exe 'hi default DirvishGitUntracked guifg=NONE guibg=NONE'
  silent exe 'hi default link DirvishGitUntrackedDir DirvishPathTail'
  silent exe 'hi default DirvishGitRenamed guifg='.s:diff_changed
  silent exe 'hi default DirvishGitUnmerged guifg='.s:diff_deleted
  silent exe 'hi default DirvishGitDeleted guifg='.s:diff_deleted
  silent exe 'hi default DirvishGitIgnored guifg=NONE guibg=NONE'
endfunction

augroup dirvish_git
  autocmd!
  autocmd FileType dirvish call dirvish_git#init()
augroup END

