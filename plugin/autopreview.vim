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

function! s:throttled_refresh()
  if !exists('b:changedticklast')
    let b:changedticklast = b:changedtick
  elseif b:changedtick != b:changedticklast
    let b:changedticklast = b:changedtick
    call s:refresh()
  endif
endfunction

function! autopreview#autopreview()
  augroup autopreview
    if g:autopreview_slow_refresh
      au BufEnter,BufWinEnter,BufWrite,CursorHoldI <buffer> call s:throttled_refresh()
    else
      au BufEnter,BufWinEnter,BufWrite,InsertLeave,CursorHold,CursorHoldI,CursorMoved,CursorMovedI <buffer> call s:throttled_refresh()
    endif
    au VimLeave <buffer> call s:stop()
  augroup END
  call s:start()
  call s:refresh()
endfunction

function! autopreview#open_browser()
  call system('open ' . g:autopreview_server_url)
endfunction

function! autopreview#stop()
  call s:stop()
  au! autopreview * <buffer>
endfunction

command! -nargs=0 AutoPreview call autopreview#autopreview()
command! -nargs=0 AutoPreviewOpen call autopreview#open_browser()
command! -nargs=0 AutoPreviewStop call autopreview#stop()
