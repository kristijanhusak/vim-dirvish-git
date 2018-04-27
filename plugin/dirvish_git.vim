if exists('g:loaded_dirvish_git')
  finish
endif
let g:loaded_dirvish_git = 1

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

let s:git_files_line_number = []

function! dirvish_git#init() abort
  let l:current_dir = expand('%')
  let s:git_files_line_number = []
  for l:highlight_group in values(s:dirvish_git_highlight_groups)
    silent! exe 'syntax clear '.l:highlight_group
  endfor

  let l:status = systemlist('git status --porcelain '.l:current_dir)

  if len(l:status) ==? 0 || (len(l:status) ==? 1 && l:status[0] =~? '^fatal')
    return 0
  endif

  call s:setup_highlighting()
  call s:set_mappings()
  setlocal conceallevel=2

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

    let l:file = fnamemodify(l:file, ':p')

    if isdirectory(l:file)
      let l:file_name = substitute(l:file, l:current_dir, '', 'g')
      call s:highlight_file(l:current_dir[:-2], l:file_name, l:us, l:them, v:true)
    else
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

  let l:line_number = search(escape(printf('%s/%s', a:dir, a:file_name), './'), 'n')

  if l:line_number > 0
    call add(s:git_files_line_number, l:line_number)
  endif

  silent exe 'syn match DirvishGitDir "'.l:dir_rgx.'" conceal cchar='.s:get_indicator(a:us, a:them)
  silent exe 'syn match '.s:get_highlight_group(a:us, a:them, a:is_directory).' "'.l:file_rgx.'" contains=DirvishGitSlash'
  silent exe 'syn match DirvishGitSlash "'.l:slash_rgx.'" conceal cchar= contained'
endfunction

function! s:setup_highlighting() abort
  let l:diff_modified = synIDattr(synIDtrans(hlID('DiffText')), 'fg')
  let l:diff_changed = synIDattr(synIDtrans(hlID('DiffChange')), 'fg')
  let l:diff_add = synIDattr(synIDtrans(hlID('DiffAdd')), 'fg')
  let l:diff_deleted = synIDattr(synIDtrans(hlID('DiffDelete')), 'fg')
  let l:gui_or_cterm = match(l:diff_add, '^#.*$') > -1 ? 'guifg' : 'ctermfg'

  silent exe 'hi default DirvishGitModified '.l:gui_or_cterm.'='.l:diff_modified
  silent exe 'hi default DirvishGitStaged '.l:gui_or_cterm.'='.l:diff_add
  silent exe 'hi default DirvishGitRenamed '.l:gui_or_cterm.'='.l:diff_changed
  silent exe 'hi default DirvishGitUnmerged '.l:gui_or_cterm.'='.l:diff_deleted
  silent exe 'hi default DirvishGitDeleted '.l:gui_or_cterm.'='.l:diff_deleted
  silent exe 'hi default link DirvishGitUntrackedDir DirvishPathTail'
  silent exe 'hi default DirvishGitIgnored guifg=NONE guibg=NONE gui=NONE cterm=NONE ctermfg=NONE ctermbg=NONE'
  silent exe 'hi default DirvishGitUntracked guifg=NONE guibg=NONE gui=NONE cterm=NONE ctermfg=NONE ctermbg=NONE'
endfunction

function! dirvish_git#jump_to_next_file() abort
  if len(s:git_files_line_number) <=? 0
    return
  endif

  let l:current_line = line('.')
  let s:git_files_line_number = sort(s:git_files_line_number, 'n')

  for l:line in s:git_files_line_number
    if l:line > l:current_line
      return cursor(l:line, 0)
    endif
  endfor

  return cursor(s:git_files_line_number[0], 0)
endfunction

function! dirvish_git#jump_to_prev_file() abort
  if len(s:git_files_line_number) <=? 0
    return
  endif

  let l:current_line = line('.')
  let s:git_files_line_number = reverse(sort(s:git_files_line_number, 'n'))

  for l:line in s:git_files_line_number
    if l:line < l:current_line
      return cursor(l:line, 0)
    endif
  endfor

  return cursor(s:git_files_line_number[0], 0)
endfunction

function! s:set_mappings() abort
if !hasmapto('<Plug>(dirvish_git_prev_file)') && maparg('[f', 'n') ==? ''
  silent! nmap <buffer> <unique> <silent> [f <Plug>(dirvish_git_prev_file)
endif

if !hasmapto('<Plug>(dirvish_git_next_file)') && maparg(']f', 'n') ==? ''
  silent! nmap <buffer> <unique> <silent> ]f <Plug>(dirvish_git_next_file)
endif
endfunction

nnoremap <Plug>(dirvish_git_next_file) :<C-u>call dirvish_git#jump_to_next_file()<CR>
nnoremap <Plug>(dirvish_git_prev_file) :<C-u>call dirvish_git#jump_to_prev_file()<CR>

augroup dirvish_git
  autocmd!
  autocmd FileType dirvish call dirvish_git#init()
augroup END

