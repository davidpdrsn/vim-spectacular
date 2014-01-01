let s:spectacular_test_runners = {}

function! s:AlwayeTrue(...)
  return 1
endfunction

function! spectacular#add_test_runner(filetype, command, file_pattern, ...)
  if exists('a:000[0]')
    let ConditionFn = a:000[0]
  else
    let ConditionFn = function('s:AlwayeTrue')
  endif

  if !has_key(s:spectacular_test_runners, a:filetype)
    let s:spectacular_test_runners[a:filetype] = []
  endif

  let list = get(s:spectacular_test_runners, a:filetype)

  call add(list, { 'pattern': a:file_pattern, 'condition': ConditionFn, 'cmd': a:command })
endfunction

function! spectacular#run_tests()
  let configs = get(s:spectacular_test_runners, &filetype)

  let clear_cmd = "!clear & "
  let cmd = clear_cmd

  for config in configs
    if FilenameIncludes(config.pattern)
      let g:spectacular_test_file = expand("%")
    endif

    if config.condition(g:spectacular_test_file)
      let cmd = substitute(clear_cmd . config.cmd, '{spec}', g:spectacular_test_file, "")
      break
    endif
  endfor

  echom cmd
  execute cmd
endfunction
