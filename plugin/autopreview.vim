" ============================================================================
" File:        autopreview.vim
" Description: live preview structured text documents in the browser
" Maintainer:  Maxime Petazzoni <maxime.petazzoni@bulix.org>
" License:     GPLv2
" ============================================================================

if !exists('g:autopreview_slow_refresh')
  let g:autopreview_slow_refresh = 0
endif

if !exists('g:autopreview_server_url')
  let g:autopreview_server_url = 'http://localhost:5555/'
endif

if !exists('g:autopreview_server_path')
  let g:autopreview_server_path =
    \ escape(expand('<sfile>:p:h'), '\') .
    \ '/../server/bin/server'
endif

function! s:start()
  call system(g:autopreview_server_path . ' &')
  redraw | echo 'Started Autopreview at ' . g:autopreview_server_url
endfunction

function! s:stop()
  call system('curl -XDELETE ' . g:autopreview_server_url . ' &>/dev/null &')
  redraw | echo 'Stopped Autopreview server.'
endfunction

function! s:refresh()
  if !exists('b:changedticklast')
    let b:changedticklast = b:changedtick
  elseif b:changedtick == b:changedticklast
    return
  endif

  let b:changedticklast = b:changedtick

  let bufnr = expand('<bufnr>')
  let data = {
        \ 'title': expand('%:t'),
        \ 'contents': join(getbufline(bufnr, 1, "$"), "\n"),
        \ 'type': &filetype
        \ }
  call system(
        \ 'curl -XPUT -HContent-Type:application/json -T - ' .
        \ g:autopreview_server_url . ' &>/dev/null &',
        \ json#encode(data))
endfunction

function! s:autopreview()
  augroup autopreview
    if g:autopreview_slow_refresh
      au BufEnter,BufWinEnter,BufWrite,CursorHoldI <buffer> call s:refresh()
    else
      au BufEnter,BufWinEnter,BufWrite,InsertLeave,CursorHold,CursorHoldI,CursorMoved,CursorMovedI <buffer> call s:refresh()
    endif
    au VimLeave <buffer> call s:cleanup()
  augroup END
  call s:start()
  call s:refresh()
endfunction

function! s:cleanup()
  call s:stop()
  au! autopreview * <buffer>
endfunction

function! autopreview#autopreview()
  call s:autopreview()
endfunction

function! autopreview#stop()
  call s:stop()
endfunction

command! -nargs=0 AutoPreview call autopreview#autopreview()
command! -nargs=0 StopAutoPreview call autopreview#stop()
