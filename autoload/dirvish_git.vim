let dirvish_git#sep = exists('+shellslash') && !&shellslash ? '\' : '/'
let dirvish_git#escape_chars = '.#~'. dirvish_git#sep


function! dirvish_git#jump_to_next_file() abort
  if len(b:git_files) <=? 0
    return
  endif

  let l:current_line = line('.')
  let l:git_files_line_number = sort(keys(b:git_files), 'N')

  for l:line in l:git_files_line_number
    if l:line > l:current_line
      return cursor(l:line, 0)
    endif
  endfor

  return cursor(l:git_files_line_number[0], 0)
endfunction


function! dirvish_git#jump_to_prev_file() abort
  if len(b:git_files) <=? 0
    return
  endif

  let l:current_line = line('.')
  let l:git_files_line_number = reverse(sort(keys(b:git_files), 'N'))

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
