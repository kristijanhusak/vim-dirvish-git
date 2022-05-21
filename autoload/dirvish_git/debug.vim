let s:plugin_dir  = expand('<sfile>:p:h:h:h').'/'
let s:log_file    = s:plugin_dir.'dirvish_git.log'
let s:channel_log = s:plugin_dir.'channel.log'
let s:new_log_session = 1"

" From vim-gitgutter
function dirvish_git#debug#log(message, ...) abort
  if g:dirvish_git_debug
    if s:new_log_session && dirvish_git#async#available()
      if exists('*ch_logfile')
        call ch_logfile(s:channel_log, 'w')
      endif
    endif

    execute 'redir >> '.s:log_file
      if s:new_log_session
        let s:start = reltime()
        silent echo "\n==== start log session ===="
      endif

      let elapsed = reltimestr(reltime(s:start)).' '
      silent echo ''
      " callers excluding this function
      silent echo elapsed.expand('<sfile>')[:-22].':'
      silent echo elapsed.s:format_for_log(a:message)
      if a:0 && !empty(a:1)
        for msg in a:000
          silent echo elapsed.s:format_for_log(msg)
        endfor
      endif
    redir END

    let s:new_log_session = 0
  endif
endfunction

function! s:format_for_log(data) abort
  if type(a:data) == 1
    return join(split(a:data,'\n'),"\n")
  elseif type(a:data) == 3
    return '['.join(a:data,"\n").']'
  else
    return a:data
  endif
endfunction
