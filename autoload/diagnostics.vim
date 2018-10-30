let s:Job = {}

let s:types = [
      \ 'typescript'
      \ ]

function! diagnostics#get(path)
  try
    let type = ''
    for candidate in s:types
      let path = diagnostics#{candidate}#detect(a:path)
      if path != ''
        let type = candidate
        break
      endif
    endfor
    return diagnostics#{type}#get(a:path)
  endtry
  return []
endfunction

function! diagnostics#job(cmd, cwd, option)
  return s:Job.new(a:cmd, a:cwd, a:option)
endfunction

function! diagnostics#item(path, level, message)
  return {
        \ 'path': a:path,
        \ 'level': a:level,
        \ 'message': a:message
        \ }
endfunction

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
    let self.diagnostics = call(self.option.on_stdout, [self, s:trim(join(a:data))])
  endif
endfunction

function! s:Job.on_stderr(job_id, data, event)
  call add(self.debug, a:data)
  if exists('self.option.on_stderr')
    let self.diagnostics = call(self.option.on_stderr, [self, s:trim(join(a:data))])
  endif
endfunction

function! s:Job.on_exit(job_id, data, event)
  unlet self.job_id
endfunction

function! s:trim(var)
  return substitute(a:var, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

