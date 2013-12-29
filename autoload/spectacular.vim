let g:spectacular_test_runners = {}

function! spectacular#always_true(x)
  return 1
endfunction

function! spectacular#add_test_runner(filetype, command, file_pattern, ...)
  if exists('a:000[0]')
    let ConditionFn = a:000[0]
  else
    let ConditionFn = function('spectacular#always_true')
  endif

  if !has_key(g:spectacular_test_runners, a:filetype)
    let g:spectacular_test_runners[a:filetype] = []
  endif

  let list = get(g:spectacular_test_runners, a:filetype)

  call add(list, { 'pattern': a:file_pattern, 'condition': ConditionFn, 'cmd': a:command })
endfunction

function! spectacular#run_tests()
  let configs = get(g:spectacular_test_runners, &filetype)

  let clear_cmd = "!clear & "
  let cmd = clear_cmd

  for config in configs
    if FilenameIncludes(config.pattern)
      let g:spectacular_test_file = expand("%")
    endif

    if config.condition(g:spectacular_test_file)
      let cmd = clear_cmd . config.cmd . " " . g:spectacular_test_file
      break
    endif

    let cmd = clear_cmd . config.cmd . " " . g:spectacular_test_file
  endfor

  execute cmd
endfunction
