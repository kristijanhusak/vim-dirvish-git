if exists('g:loaded_dirvish_git')
  finish
endif
let g:loaded_dirvish_git = 1

let g:dirvish_git_show_ignored = get(g:, 'dirvish_git_show_ignored', 0)
let g:dirvish_git_show_icons = get(g:, 'dirvish_git_show_icons', 1)

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

let s:sep = exists('+shellslash') && !&shellslash ? '\' : '/'
let s:escape_chars = '.#~'.s:sep
let s:git_files = {}

function! dirvish_git#init() abort
  if get(g:, 'dirvish_relative_paths', 0)
    echohl Error
    echo 'Dirvish Git plugin does not support relative paths (g:dirvish_relative_paths = 1).'
    echohl None
    return 0
  endif

  let l:current_dir = expand('%')
  let s:git_files = {}
  for l:highlight_group in values(s:dirvish_git_highlight_groups)
    silent! exe 'syntax clear '.l:highlight_group
  endfor

  let l:status = s:get_status_list(l:current_dir)

  if empty(l:status)
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

    " Rename status returns both old and new filename "old_name.ext -> new_name.ext
    " but only new name is needed here
    if l:us ==# 'R'
      let l:file = get(split(l:file, ' -> '), 1, l:file)
    endif

    if s:is_in_arglist(l:file)
      continue
    endif

    let l:file = fnamemodify(l:file, ':p')
    let l:file = matchstr(l:file, escape(l:current_dir.'[^'.s:sep.']*'.s:sep.'\?', s:escape_chars))

    if index(values(s:git_files), l:file) > -1
      continue
    endif

    let l:line_number = search(escape(l:file, s:escape_chars), 'n')
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

  "Set argument list highlight again to override git highlights
  let l:pat = join(map(argv(), 'escape(fnamemodify(v:val[-1:]==#s:sep?v:val[:-2]:v:val, ":t"), "*.^$~\\")'), '\|')
  exe 'syntax match DirvishArg /\'.s:sep.'\@<=\%\('.l:pat.'\)\'.s:sep.'\?$/'
endfunction

function! s:get_status_list(current_dir) abort
  let l:ignored = g:dirvish_git_show_ignored ? '--ignored' : ''
  let l:status = systemlist(printf('git status --porcelain %s %s', l:ignored, a:current_dir))

  if len(l:status) ==? 0 || (len(l:status) ==? 1 && l:status[0] =~? '^fatal')
    return []
  endif

  "Put unmerged first to get proper status on directories
  return sort(l:status, { first, second -> (first =~? '^U' || first =~? '^.U') ? -1 : 1 })
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
  let l:file_rgx = escape(printf('\(%s\)\@<=%s%s', a:dir, s:sep, a:file_name), s:escape_chars)
  let l:dir_rgx = escape(printf('%s\(%s%s\)\@=', a:dir, s:sep, a:file_name), s:escape_chars)
  let l:slash_rgx = escape(printf('\(%s\)\@<=%s\(%s\)\@=', a:dir, s:sep, a:file_name), s:escape_chars)

  " Check if icons should be shown
  let l:conceal_char = g:dirvish_git_show_icons
        \ ? ' cchar=' .. s:get_indicator(a:us, a:them)
        \ : ''
  let l:conceal_last_folder_char = g:dirvish_git_show_icons ? ' cchar= ' : ''

  silent exe 'syn match DirvishGitDir "'.l:dir_rgx.'" conceal' .. l:conceal_char
  silent exe 'syn match '.s:get_highlight_group(a:us, a:them, a:is_directory).' "'.l:file_rgx.'" contains=DirvishGitSlash'
  silent exe 'syn match DirvishGitSlash "'.l:slash_rgx.'" conceal contained' .. l:conceal_last_folder_char
endfunction

function! s:setup_highlighting() abort
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
  if &filetype ==? 'dirvish'
    Dirvish %
  endif
endfunction

function! s:set_mappings() abort
if !hasmapto('<Plug>(dirvish_git_prev_file)') && maparg('[f', 'n') ==? ''
  silent! nmap <buffer> <unique> <silent> [f <Plug>(dirvish_git_prev_file)
endif

if !hasmapto('<Plug>(dirvish_git_next_file)') && maparg(']f', 'n') ==? ''
  silent! nmap <buffer> <unique> <silent> ]f <Plug>(dirvish_git_next_file)
endif

" Reload dirvish after adding file to arglist in order to update syntax
if maparg('X', 'n') ==? '<Plug>(dirvish_arg)'
  nmap <buffer><silent><expr> X "\<Plug>(dirvish_arg):<C-u>call dirvish_git#reload()<CR>"
  xmap <buffer><silent><expr> X "\<Plug>(dirvish_arg):<C-u>call dirvish_git#reload()<CR>"
endif

endfunction

nnoremap <Plug>(dirvish_git_next_file) :<C-u>call dirvish_git#jump_to_next_file()<CR>
nnoremap <Plug>(dirvish_git_prev_file) :<C-u>call dirvish_git#jump_to_prev_file()<CR>

augroup dirvish_git
  autocmd!
  autocmd FileType dirvish call dirvish_git#init()
  autocmd BufEnter,FocusGained * call dirvish_git#reload()
augroup END

