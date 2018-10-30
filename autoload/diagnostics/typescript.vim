let g:diagnostics#typescript#marker = 'tsconfig.json'
let g:diagnostics#typescript#command = ['npx', 'tsc', '--watch', '--noEmit']
let g:diagnostics#typescript#clear_pattern = 'Starting.\{-} compilation'
let g:diagnostics#typescript#diagnostic_pattern = '^\(.\+\)(\d\+,\d\+): error TS\d\+'
let g:diagnostics#typescript#job = {}

function! diagnostics#typescript#detect(path)
  let marker = findfile(g:diagnostics#typescript#marker, fnamemodify(a:path, ':p:h') . ';')
  return fnamemodify(marker, ':p:h')
endfunction

function! diagnostics#typescript#get(path)
  let cwd = diagnostics#typescript#detect(a:path)
  echomsg cwd
  if cwd == ''
    return []
  endif

  if exists('g:diagnostics#typescript#job.cwd')
    " Skip for already process started.
    if g:diagnostics#typescript#job.cwd == cwd
      return g:diagnostics#typescript#job.diagnostics
    endif

    " Stop current process if other process needed.
    call g:diagnostics#typescript#job.stop()
  endif

  " Create and start job.
  let job = diagnostics#job(g:diagnostics#typescript#command, cwd, {
        \   'on_stdout': function('diagnostics#typescript#parse')
        \ })
  call job.start()
  let g:diagnostics#typescript#job = job

  " Return empty diagnostics at first.
  return []
endfunction

function! diagnostics#typescript#parse(job, output)
  let diagnostics = a:job.diagnostics

  " diagnostics"
  let matches = matchlist(a:output, '^\(.\+\)(\d\+,\d\+)')
  if exists('matches[1]')
    call add(diagnostics, diagnostics#item(
          \ a:job.cwd . '/' . matches[1],
          \ 'error',
          \ ''
          \ ))
  endif

  " clear diagnostics.
  if matchstr(a:output, '.*' . g:diagnostics#typescript#clear_pattern . '.*')
    echomsg 'clear diagnostics' . a:output
    let diagnostics = []
  endif

  return diagnostics
endfunction

