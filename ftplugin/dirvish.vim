let s:diffModifiedColor = synIDattr(synIDtrans(hlID('DiffText')), 'reverse') ? 'fg' : 'bg'
let s:diffModified = synIDattr(synIDtrans(hlID('DiffText')), s:diffModifiedColor)

let s:diffAddColor = synIDattr(synIDtrans(hlID('DiffAdd')), 'reverse') ? 'fg' : 'bg'
let s:diffAdd = synIDattr(synIDtrans(hlID('DiffAdd')), s:diffAddColor)

let s:diffDeleteColor = synIDattr(synIDtrans(hlID('DiffDelete')), 'reverse') ? 'fg' : 'bg'
let s:diffDelete = synIDattr(synIDtrans(hlID('DiffDelete')), s:diffDeleteColor)

silent exe 'hi DirvishGitModifiedFiles guifg='.s:diffModified
silent exe 'hi DirvishGitModifiedDir guifg='.s:diffModified
silent exe 'hi DirvishGitAddedFiles guifg='.s:diffAdd
silent exe 'hi DirvishGitAddedDir guifg='.s:diffAdd
hi Conceal gui=bold

function! SetupDirvishGit() abort
  let s:status = systemlist('git status --porcelain')

  if len(s:status) ==? 0 || (len(s:status) ==? 1 && s:status[0] =~? '^fatal')
    return 0
  endif

  setlocal conceallevel=2

  for s:item in s:status
    let [s:flag, s:file] = split(s:item, '\s')
    let s:file = printf('%s/%s', getcwd(), s:file)
    let s:dir = fnamemodify(s:file, ':h').'/'
    let s:fileName = fnamemodify(s:file, ':t')
    let s:fileRgx = escape(printf('\(%s\)\@<=%s', s:dir, s:fileName), './')
    let s:dirRgx = escape(printf('%s\(%s\)\@=', s:dir, s:fileName), './')

    " TODO: Check us-them in flag
    if s:flag =~? 'M'
      silent exe 'syn match DirvishGitModifiedFiles "'.s:fileRgx.'"'
      silent exe 'syn match DirvishGitModifiedDir "'.s:dirRgx.'" conceal cchar=~'
      continue
    endif

    if s:flag =~? '??'
      silent exe 'syn match DirvishGitAddedFiles "'.s:fileRgx.'"'
      silent exe 'syn match DirvishGitAddedDir "'.s:dirRgx.'" conceal cchar=+'
      continue
    endif
  endfor
endfunction
