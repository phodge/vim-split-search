function! SplitSearch#grep(args) " {{{
  " build a command-line to be executed
  let l:args_string = <SID>ProcessArgs(a:args, '--regexp=')
  let l:cmd = 'grep -rnH ' . l:args_string . ' *'
  let l:title = 'grep ' . l:args_string . ' ' . fnamemodify(getcwd(), ':~')
  call <SID>RunSearch(l:cmd, l:title, 1)
endfunction " }}}

function! SplitSearch#ack(args) " {{{
  let l:args_string = <SID>ProcessArgs(a:args, '. --match ')

  " use my copy of ack if the user doesn't have it
  let l:ack_prg = (! executable('ack') && executable('/home/phodge/bin/ack'))
              \ ? '/home/phodge/bin/ack'
              \ : 'ack'
  let l:cmd = l:ack_prg . ' ' . l:args_string
  let l:title = 'ack ' . l:args_string . ' ' . fnamemodify(getcwd(), ':~')
  call <SID>RunSearch(l:cmd, l:title, 0)
endfunction " }}}

function! SplitSearch#ag(args) " {{{
  let l:args_string = <SID>ProcessArgs(a:args, '. -- ')

  " use my copy of ack if the user doesn't have it
  let l:cmd = 'ag ' . l:args_string
  let l:title = 'ag ' . l:args_string . ' ' . fnamemodify(getcwd(), ':~')
  call <SID>RunSearch(l:cmd, l:title, 0)
endfunction " }}}

function! <SID>ProcessArgs(args, protector) " {{{
  let l:options = ''
  let l:pattern = []
  let l:idx = 0
  while l:idx < len(a:args)
    let l:arg = a:args[l:idx]
    let l:idx += 1
    " stop processing after single dash
    if l:arg == '-'
      break
    elseif l:arg =~ '^--\=\w\+'
      let l:options .= l:arg . ' '
    else
      " don't process any more options after this
      call add(l:pattern, l:arg)
      break
    endif
  endwhile

  " add any remaining args to the pattern
  while l:idx < len(a:args)
    call add(l:pattern, a:args[l:idx])
    let l:idx += 1
  endwhile

  let l:return = l:options

  " add protector if pattern starts with '-'
  if l:pattern[0] =~ '^-'
    let l:return .= ' ' . a:protector
  endif

  " add escaped pattern
  let l:pattern_str = join(l:pattern, ' ')
  let l:pattern_str = (v:version >= 730) ? shellescape(l:pattern_str, 1) : shellescape(l:pattern_str)
  return l:return . l:pattern_str
endfunction " }}}

function! <SID>RunSearch(exec, title, remove_rubbish) " {{{
  " first, see if the buffer exists
  let l:otherbuf = bufnr(a:title)
  if l:otherbuf > 0
    let l:old_switchbuf = &g:switchbuf
    try
      setglobal switchbuf+=useopen
      execute 'sbuf' l:otherbuf
    finally
      let &g:switchbuf = l:old_switchbuf
    endtry
    return
  endif

  " what is the full name of the current file?
  let l:currentbuf = expand('%:p')

  let l:newbuf = 0
  try
    new
    let l:newbuf = bufnr('')
    setlocal fileformat=dos
    silent execute 'read !' . a:exec
    if v:shell_error
      echohl Error
      echo "Shell error"
      echohl None
    endif

    let b:remove_rubbish = a:remove_rubbish

    call <SID>Cleanup()

    " fiddle with options so the buffer won't hang around
    setlocal nonumber buftype=nofile bufhidden=wipe noswapfile

    " abort if there are no matches
    if line('$') == 1 && ! strlen(getline(1))
      return
    endif

    " set up <CR> mapping to open files
    nnoremap <buffer> <CR> mt0<C-W>F<C-W>p`t<C-W>p

    " remember the search command and set up a mapping to re-run it again
    let b:splitsearch_cmd = a:exec
    nnoremap <buffer> <F12> :call <SID>Rerun()<CR>
  catch
    if l:newbuf
      execute 'bwipeout' l:newbuf
    endif
    echoerr v:exception
  endtry
  " don't care if this command fails
  execute 'file' escape(a:title, ' |"''?\')
endfunction " }}}

function! <SID>Rerun() " {{{
  if ! exists('b:splitsearch_cmd')
    echoerr 'Not a valid window for Rerun()'
    return
  endif

  " empty the file
  %delete

  " paste contents of search
  silent execute 'read !' . b:splitsearch_cmd

  " delete the empty first line of the file
  call <SID>Cleanup()
endfunction " }}}

function! <SID>Cleanup() " {{{
  " delete the empty first line of the file
  0delete
  
  " get rid of trailing \r
  %s/\r$//e

  " if grep was used, there may be some rubbish result lines that need to be removed
  if b:remove_rubbish
    " remove lines where a match was find in the vim's .swp files
    silent! global/^Binary file \f\+\.sw[po] matches$/delete
    silent! global/^grep: \f\+: Too many levels of symbolic links$/delete
  endif
endfunction " }}}
