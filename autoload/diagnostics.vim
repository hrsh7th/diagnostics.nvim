let s:sfile = expand('<sfile>:p')

function! diagnostics#detect(path)
  try
    try
      for candidate in diagnostics#types()
        let cwd = diagnostics#{candidate}#detect(a:path)
        if cwd != ''
          return { 'type': candidate, 'cwd': cwd }
        endif
      endfor
    catch
    endtry
  catch
  endtry
  return { 'type': '', 'cwd': '' }
endfunction

function! diagnostics#start(path)
  let detect = diagnostics#detect(a:path)
  if detect['type'] == ''
    return
  endif

  call diagnostics#{detect['type']}#start(detect['cwd'])
endfunction

function! diagnostics#get(path)
  let detect = diagnostics#detect(a:path)
  if detect['type'] == ''
    return []
  endif

  return diagnostics#{detect['type']}#get(detect['cwd'])
endfunction

function! diagnostics#item(params)
  return {
        \ 'path': a:params['path'],
        \ 'line': get(a:params, 'line', 0),
        \ 'col': get(a:params, 'col', 0),
        \ 'level': get(a:params, 'level', 'error'),
        \ 'message': get(a:params, 'message', 'no message.')
        \ }
endfunction

function! diagnostics#types()
  let types = glob(printf('%s/diagnostics/*.vim', fnamemodify(s:sfile, ':h')), v:true, v:true)
  let types = map(types, 'fnamemodify(v:val, ":t:r")')
  return types
endfunction

function! diagnostics#job(cmd, cwd, option)
  return s:Job.new(a:cmd, a:cwd, a:option)
endfunction

let s:Job = {}

function! s:Job.new(cmd, cwd, option)
  let object = copy(s:Job)
  let object.cmd = a:cmd
  let object.cwd = a:cwd
  let object.option = a:option
  let object.stdout_buffered = exists('a:option.stdout_buffered')
  let object.stderr_buffered = exists('a:option.stderr_buffered')
  let object.diagnostics = []
  let object.debug = []
  return object
endfunction

function! s:Job.start()
  if !self.is_running()
    let self.job_id = jobstart(self.cmd, self)
  endif
endfunction

function! s:Job.stop()
  if self.is_running()
    call jobstop(self.job_id)
  endif
endfunction

function! s:Job.is_running()
  return exists('self.job_id') && self.job_id != -1
endfunction

function! s:Job.on_stdout(job_id, data, event)
  call add(self.debug, a:data)
  if exists('self.option.on_stdout')
    let self.diagnostics = call(self.option.on_stdout, [self, filter(map(a:data, 'diagnostics#trim(v:val)'), 'strlen(v:val)')])
  endif
endfunction

function! s:Job.on_stderr(job_id, data, event)
  call add(self.debug, a:data)
  if exists('self.option.on_stderr')
    let self.diagnostics = call(self.option.on_stderr, [self, filter(map(a:data, 'diagnostics#trim(v:val)'), 'strlen(v:val)')])
  endif
endfunction

function! s:Job.on_exit(job_id, data, event)
  unlet self.job_id
endfunction

function! diagnostics#trim(var)
  return substitute(a:var, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

