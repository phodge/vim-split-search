if exists('g:loaded_splitsearch') && g:loaded_splitsearch
  finish
endif

if version < 700
  finish
endif

command! -nargs=+ Grep call SplitSearch#grep([<f-args>])
command! -nargs=+ Ack  call SplitSearch#ack([<f-args>])
command! -nargs=+ Ag  call SplitSearch#ag([<f-args>])

let g:loaded_splitsearch = 1
