" AUTOCOMMANDS: git blame

" @TODO use async job
" @TODO don't rerun on same line
" @TODO don't run if not in git
" @TODO find root if the git root is not CWD
" @TODO enable/disable/airline etc

let s:gitBlameNsId = nvim_create_namespace('git-blame-messages')

let s:prevBuffer
let s:prevLine

function! GitBlame (buffer, line)
  if (line == s:prevLine && buffer == prevBuffer)
    return
  endif
  call GitBlameClear(buffer)
  let blameMessage = split(system("git log -n1 -L" . a:line . "," . a:line . ":" .bufname(a:buffer) . " --format='   %h %an %ad [%s]' --date=relative"), '\n')[0]
  if (v:shell_error == 0)
    call nvim_buf_set_virtual_text(a:buffer, s:gitBlameNsId, a:line - 1, [[blameMessage, 'Noise']], [])
  endif
endfunction

function! GitBlameClear (buffer)
  call nvim_buf_clear_namespace(a:buffer, s:gitBlameNsId, 0, -1)
end

augroup blame
  autocmd!
  autocmd CursorHold * silent call GitBlame(bufnr("%"), line("."))
augroup end


