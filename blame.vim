" AUTOCOMMANDS: git blame

" @DONE use async job
" @DONE don't rerun on same line
" @DONE don't run on empty line
" @DONE new/modified line
" @TODO don't run if not in git
" @TODO find root if the git root is not CWD
" @DONE relative date
" @DONE InsertEnter hide
" @TODO tests
" @TODO plugin structure, docs

let s:gitBlameNsId = nvim_create_namespace('git-blame-messages')

let s:prevBuffer = ''
let s:prevLine = ''
let s:jobId = 0

function! GitBlameUpdateVirtualTextIfDifferentLine (buffer, line)
  if (a:line != s:prevLine || a:buffer != s:prevBuffer)
    let s:prevLine = a:line
    let s:prevBuffer = a:buffer
    call GitBlameUpdateVirtualText(a:buffer, a:line)
  endif
endfunction

function! GitBlameUpdateVirtualText (buffer, line)
  call GitBlameClearVirtualText(a:buffer)
  if (strlen(getline(a:line)) > 0)
   call GitBlameData(a:buffer, a:line)
 endif
endfunction

function! GitBlameData (buffer, line)
  if (s:jobId)
    call jobstop(s:jobId)
  endif
  let s:buffer = a:buffer
  let s:line = a:line
  let blameCommand = "git blame -p -L" . a:line . "," . a:line . " " . bufname(a:buffer) 
  let s:jobId = jobstart(blameCommand, {
    \ 'stdout_buffered': 1,
    \ 'on_stdout': function('s:GitBlameSetVirtualText')
    \ })
endfunction

function! s:GitBlameSetVirtualText(id, data, event)
  let s:jobId = 0
  if (line('.') == s:line)
    call nvim_buf_set_virtual_text(s:buffer, s:gitBlameNsId, s:line - 1, [[GitBlameComposeText(a:data), 'Noise']], [])
  endif
endfunction

function! GitBlameComposeText(lines)
  if (len('a:lines') < 2)
    return
  endif
  let data = { 'hash': a:lines[0][0:6] }
  for line in filter(a:lines, 'v:val != ""')
    let [key; val] = split(line)
    if (index(['author', 'author-time', 'summary'], key) > -1)
      let data[key] = join(val)
    endif
  endfor
  if data.hash == '0000000'
    let text = printf("   %s", data.author)
  else
    try
      let time = s:GitBlameRelativeTime(data['author-time'], localtime())
      let text = printf("   %s | %s | %s | %s", data.author, time, data.summary, data.hash)
    catch /.*/
      let text = ''
    endtry
  endif
  return text
endfunction

function! GitBlameClearVirtualText (buffer)
  call nvim_buf_clear_namespace(a:buffer, s:gitBlameNsId, 0, -1)
endfunction

function! s:GitBlameRelativeTime (then, now)
  let seconds = str2nr(a:now) - str2nr(a:then)
  let minutes = float2nr(floor(seconds / 60))
  let hours = float2nr(floor(minutes / 60))
  let days = float2nr(floor(hours / 24))
  let weeks = float2nr(floor(days / 7))
  let months = float2nr(floor(weeks / 4.5))
  let years = float2nr(floor(weeks / 52))
  if (years > 0)
    let [time, unit] = [years, 'year']
  elseif (months > 0)
    let [time, unit] = [months, 'month']
  elseif (weeks > 0)
    let [time, unit] = [weeks, 'week']
  elseif (days > 0)
    let [time, unit] = [days, 'day']
  elseif (hours > 0)
    let [time, unit] = [hours, 'hour']
  elseif (minutes > 0)
    let [time, unit] = [minutes, 'minute']
  elseif (seconds > 0)
    let [time, unit] = [seconds, 'second']
  else
    return 'just now'
  endif
  return printf("%s %s%s ago", time, unit, time == 1 ? '' : 's')
endfunction

augroup blame
  autocmd!
  autocmd CursorHold * call GitBlameUpdateVirtualTextIfDifferentLine(bufnr("%"), line("."))
  autocmd InsertLeave,TextChanged,FocusGained,BufRead * call GitBlameUpdateVirtualText(bufnr("%"), line("."))
  autocmd InsertEnter,FocusLost * call GitBlameClearVirtualText(bufnr("%"))
augroup end
