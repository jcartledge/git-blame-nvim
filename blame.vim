" AUTOCOMMANDS: git blame

" @DONE use async job
" @DONE don't rerun on same line
" @DONE don't run on empty line
" @DONE new/modified line
" @TODO don't run if not in git
" @TODO find root if the git root is not CWD
" @TODO relative date
" @DONE InsertEnter hide
" @TODO tests

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
    \ 'on_stdout': function('GitBlameSetVirtualText')
    \ })
endfunction

function! GitBlameSetVirtualText(id, data, event)
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
      let text = printf("   %s %s %s [%s]", data.hash, data.author, data['author-time'], data.summary)
    catch /.*/
      let text = ''
    endtry
  endif
  return text
endfunction

function! GitBlameClearVirtualText (buffer)
  call nvim_buf_clear_namespace(a:buffer, s:gitBlameNsId, 0, -1)
endfunction

augroup blame
  autocmd!
  autocmd CursorHold * call GitBlameUpdateVirtualTextIfDifferentLine(bufnr("%"), line("."))
  autocmd InsertLeave * call GitBlameUpdateVirtualText(bufnr("%"), line("."))
  autocmd InsertEnter * call GitBlameClearVirtualText(bufnr("%"))
augroup end


