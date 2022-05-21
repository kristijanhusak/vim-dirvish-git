" check async
if !dirvish_git#async#available()
  echoe 'Need vim 7.4.1826 or nvim!'
  finish
endif

if exists('g:loaded_dirvish_git')
  finish
endif

let g:loaded_dirvish_git = 1

let g:dirvish_git_show_ignored = get(g:, 'dirvish_git_show_ignored', 0)
let g:dirvish_git_show_icons = get(g:, 'dirvish_git_show_icons', 1)
let g:dirvish_git_debug = get(g:, 'dirvish_git_debug', 0)


function! dirvish_git#init() abort
  if get(g:, 'dirvish_relative_paths', 0)
    echohl Error
    echo 'Dirvish Git plugin does not support relative paths (g:dirvish_relative_paths = 1).'
    echohl None
    return 0
  endif

  let b:git_files = get(b:, 'git_files', {})
  let b:git_repo_path = ''

  call dirvish_git#highlight#setup_highlighting()

  call s:set_mappings()

  call dirvish_git#utils#update_status(expand('%:p:h'))

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
  autocmd BufEnter,FocusGained dirvish call dirvish_git#reload()
augroup END

