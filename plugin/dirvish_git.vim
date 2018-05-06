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

let s:sep = exists('+shellslash') && !&shellslash ? '\' : '/'
let s:git_files = {}

function! dirvish_git#init() abort
  let l:current_dir = expand('%')
  let s:git_files = {}
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

    if s:is_in_arglist(l:file)
      continue
    endif

    let l:file = fnamemodify(l:file, ':p')
    let l:file = matchstr(l:file, escape(l:current_dir.'[^'.s:sep.']*'.s:sep.'\?', '.'.s:sep))

    if index(values(s:git_files), l:file) > -1
      continue
    endif

    let l:line_number = search(escape(l:file, '.'.s:sep), 'n')
    let s:git_files[l:line_number] = l:file

    if isdirectory(l:file)
      let l:file_name = substitute(l:file, l:current_dir, '', 'g')
      call s:highlight_file(l:current_dir[:-2], l:file_name, l:us, l:them, v:true)
    else
      let l:dir = fnamemodify(l:file, ':h')
      let l:file_name = fnamemodify(l:file, ':t')
      call s:highlight_file(l:dir, l:file_name, l:us, l:them, v:false)
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
  let l:file_rgx = escape(printf('\(%s\)\@<=%s%s', a:dir, s:sep, a:file_name), './')
  let l:dir_rgx = escape(printf('%s\(%s%s\)\@=', a:dir, s:sep, a:file_name), './')
  let l:slash_rgx = escape(printf('\(%s\)\@<=%s\(%s\)\@=', a:dir, s:sep, a:file_name), './')

  silent exe 'syn match DirvishGitDir "'.l:dir_rgx.'" conceal cchar='.s:get_indicator(a:us, a:them)
  silent exe 'syn match '.s:get_highlight_group(a:us, a:them, a:is_directory).' "'.l:file_rgx.'" contains=DirvishGitSlash'
  silent exe 'syn match DirvishGitSlash "'.l:slash_rgx.'" conceal cchar= contained'
endfunction

function! s:setup_highlighting() abort
  let l:modified = 'guifg=#EBCB8B ctermfg=3'
  let l:added = 'guifg=#A3BE8C ctermfg=2'
  let l:deleted = 'guifg=#BF616A ctermfg=1'

  silent exe 'hi default DirvishGitModified '.l:modified
  silent exe 'hi default DirvishGitStaged '.l:added
  silent exe 'hi default DirvishGitRenamed '.l:modified
  silent exe 'hi default DirvishGitUnmerged '.l:deleted
  silent exe 'hi default DirvishGitDeleted '.l:deleted
  silent exe 'hi default link DirvishGitUntrackedDir DirvishPathTail'
  silent exe 'hi default DirvishGitIgnored guifg=NONE guibg=NONE gui=NONE cterm=NONE ctermfg=NONE ctermbg=NONE'
  silent exe 'hi default DirvishGitUntracked guifg=NONE guibg=NONE gui=NONE cterm=NONE ctermfg=NONE ctermbg=NONE'
endfunction

function s:is_in_arglist(file) abort
  let l:file = fnamemodify(a:file, ':p')
  let l:cwd = printf('%s%s', getcwd(), s:sep)
  for l:arg in argv()
    if l:arg ==# l:cwd
      continue
    endif
    if l:file =~? l:arg
      return 1
    endif
  endfor
  return 0
endfunction

function! dirvish_git#jump_to_next_file() abort
  if len(s:git_files) <=? 0
    return
  endif

  let l:current_line = line('.')
  let l:git_files_line_number = sort(keys(s:git_files), 'N')

  for l:line in l:git_files_line_number
    if l:line > l:current_line
      return cursor(l:line, 0)
    endif
  endfor

  return cursor(l:git_files_line_number[0], 0)
endfunction

function! dirvish_git#jump_to_prev_file() abort
  if len(s:git_files) <=? 0
    return
  endif

  let l:current_line = line('.')
  let l:git_files_line_number = reverse(sort(keys(s:git_files), 'N'))

  for l:line in l:git_files_line_number
    if l:line < l:current_line
      return cursor(l:line, 0)
    endif
  endfor

  return cursor(l:git_files_line_number[0], 0)
endfunction

function! dirvish_git#reload() abort
  if &filetype ==? 'dirvish' && len(s:git_files) > 0
    call feedkeys('R')
  endif
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
  autocmd BufEnter * call dirvish_git#reload()
augroup END

