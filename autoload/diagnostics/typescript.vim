let g:diagnostics#typescript#marker = 'tsconfig.json'
let g:diagnostics#typescript#command = ['npx', 'tsc', '--watch', '--noEmit', '--pretty', 'false']
let g:diagnostics#typescript#clear_pattern = 'File change detected.'
let g:diagnostics#typescript#updated_pattern = 'Found \d\+ errors.'
let g:diagnostics#typescript#diagnostic_pattern = '^\(.\{-}\): \(.\{-}\): \(.\{-}\)$'
let g:diagnostics#typescript#location_pattern = '^\(.\{-}\)(\(\d\+\),\(\d\+\))$'
let g:diagnostics#typescript#job = {}

function! diagnostics#typescript#detect(path)
  let marker = findfile(g:diagnostics#typescript#marker, fnamemodify(a:path, ':p:h') . ';')
  return fnamemodify(marker, ':p:h')
endfunction

function! diagnostics#typescript#get(cwd)
  if exists('g:diagnostics#typescript#job.cwd')
    " Return diagnostics from current job.
    if g:diagnostics#typescript#job.cwd == a:cwd
      return g:diagnostics#typescript#job.diagnostics
    endif

    " Stop current job if other job requested.
    call g:diagnostics#typescript#job.stop()
  endif

  " Create and start job.
  let job = diagnostics#job(g:diagnostics#typescript#command, a:cwd, {
        \   'on_stdout': function('diagnostics#typescript#parse')
        \ })
  call job.start()
  let g:diagnostics#typescript#job = job

  " Return empty diagnostics at first.
  return []
endfunction

function! diagnostics#typescript#parse(job, outputs)
  let diagnostics = a:job.diagnostics
  for output in a:outputs
    " Line is diagnostics.
    let matches = matchlist(output, g:diagnostics#typescript#diagnostic_pattern)
    if len(matches) != 0
      let location = matchlist(matches[1], g:diagnostics#typescript#location_pattern)
      call add(diagnostics, diagnostics#item({
            \ 'path': a:job.cwd . '/' . location[1],
            \ 'line': location[2],
            \ 'col': location[3],
            \ 'level': matches[2],
            \ 'message': matches[3]
            \ }))
      continue
    endif

    " Line is clear marker.
    let matches = matchlist(output, g:diagnostics#typescript#clear_pattern)
    if len(matches) != 0
      let diagnostics = []
      continue
    endif

    " Line is updated marker.
    let matches = matchlist(output, g:diagnostics#typescript#updated_pattern)
    if len(matches) != 0
      echomsg printf('TypeScript diagnostics updated: %s', a:job.cwd)
      continue
    endif

  endfor

  return diagnostics
endfunction

