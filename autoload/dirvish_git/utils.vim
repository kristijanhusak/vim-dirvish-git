let s:sep = dirvish_git#sep
let s:escape_chars = dirvish_git#escape_chars

" handler for execute async job
let s:update_status_handler = {}

function s:update_status_handler.out(bufnr, output) abort
  let l:status = split(a:output, '\n')
  if len(l:status) ==? 0 || (len(l:status) ==? 1 && l:status[0] =~? '^fatal')
    return
  endif

  let l:status = sort(l:status, "s:unmerged_status_comparator")

  let l:current_dir = expand('%:p:h')

  setlocal conceallevel=2

  for l:item in l:status
    let l:data = matchlist(l:item, '\(.\)\(.\)\s\(.*\)')
    if len(l:data) <=? 0
      continue
    endif

    let l:us = l:data[1]
    let l:them = l:data[2]
    let l:file = l:data[3]

    if stridx(l:file, ' ') > -1 && l:file[0] ==? '"'
      let l:file = trim(l:file, '"')
    endif

    " Rename status returns both old and new filename "old_name.ext -> new_name.ext
    " but only new name is needed here
    if l:us ==# 'R'
      let l:file = get(split(l:file, ' -> '), 1, l:file)
    endif

    let l:file = fnamemodify(b:git_repo_path . s:sep . l:file, ':p')
    " let l:file = fnamemodify(l:current_dir . s:sep . l:file, ':p')

    if s:is_in_arglist(l:file)
      continue
    endif

    " let l:file = matchstr(l:file, escape(l:current_dir.'[^'.s:sep.']*'.s:sep.'\?', s:escape_chars))
    " call dirvish_git#debug#log('[l:file] '. l:file)

    " if index(values(b:git_files), l:file) > -1
    "   continue
    " endif

    let l:line_number = search(escape(l:file, s:escape_chars), 'n')
    let b:git_files[l:line_number] = l:file


    if isdirectory(l:file)
      let l:file_name = substitute(l:file, l:current_dir, '', 'g')
      call dirvish_git#highlight#highlight_file(l:current_dir[:-2], l:file_name, l:us, l:them, 1)
    else
      let l:dir = fnamemodify(l:file, ':h')
      let l:file_name = fnamemodify(l:file, ':t')
      call dirvish_git#debug#log('[l:file_name] '. l:file_name)
      call dirvish_git#highlight#highlight_file(l:dir, l:file_name, l:us, l:them, 0)
    endif
  endfor

  "Set argument list highlight again to override git highlights
  let l:pat = join(map(argv(), 'escape(fnamemodify(v:val[-1:]==#s:sep?v:val[:-2]:v:val, ":t"), "*.^$~\\")'), '\|')
  exe 'syntax match DirvishArg /\'.s:sep.'\@<=\%\('.l:pat.'\)\'.s:sep.'\?$/'
endfunction

function s:update_status_handler.err(bufnr) abort
  " TODO: handle error
endfunction

function dirvish_git#utils#update_status(current_dir) abort
  let repo_path = dirvish_git#utils#get_repo_path(a:current_dir, function('dirvish_git#utils#update_status', [ a:current_dir ]))
  if repo_path == '[async]'
    return
  endif
  let l:ignored = g:dirvish_git_show_ignored ? '--ignored' : ''
  let cmd = printf('git status --porcelain %s %s', l:ignored, a:current_dir)
  let handler = copy(s:update_status_handler)
  call dirvish_git#async#execute(cmd, bufnr(), handler)
endfunction
"
function dirvish_git#utils#get_repo_path(current_dir, callback) abort
  if empty(b:git_repo_path)
    let cmd = printf('git -C %s rev-parse --show-toplevel', a:current_dir)
    let handler = copy(s:get_repo_path_handler)
    if !empty(a:callback)
      let handler.callback = a:callback
    endif
    call dirvish_git#async#execute(cmd, bufnr(), handler)
    return '[async]'
  endif
  return b:git_repo_path
endfunction

let s:get_repo_path_handler = {}
function s:get_repo_path_handler.out(bufnr, output) abort
  let b:git_repo_path = trim(a:output)
  if !empty(self.callback)
    call self.callback()
  endif
endfunction

function s:get_repo_path_handler.err(bufnr) abort
  " TODO: handle error
endfunction


" Get rid of any trailing new line or SOH character.
"
" git ls-files -z produces output with null line termination.
" Vim's system() replaces any null characters in the output
" with SOH (start of header), i.e. ^A.
function! s:strip_trailing_new_line(line) abort
  return substitute(a:line, '[[:cntrl:]]$', '', '')
endfunction

" move all strings beginning with U or .U to the beginning of the list
function! s:unmerged_status_comparator(a, b) abort
  if (a:a =~? '^U') || (a:a =~? '^.U')
    return -1
  endif
  return 1
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
