let g:spectacular_test_runners = {}

function! True(...)
  return 1
endfunction

function! spectacular#add_test_runner(filetype, command, file_pattern, ...)
  if !has_key(g:spectacular_test_runners, a:filetype)
    let g:spectacular_test_runners[a:filetype] = []
  endif

  let conditions = copy(a:000)

  if empty(conditions)
    call add(conditions, function("True"))
  endif

  let list = get(g:spectacular_test_runners, a:filetype)

  call add(list, { 'pattern': a:file_pattern, 'conditions': conditions, 'cmd': a:command })
endfunction

function! spectacular#run_tests()
  " filter configs by current file type
  let configs_for_current_filetype = get(g:spectacular_test_runners, &filetype)

  " find out if the current file is a test file
  " (matches any of the patterns in the config)
  let current_file_is_test_file = 0
  for config in configs_for_current_filetype
    if match(expand("%"), config.pattern) != -1
      let current_file_is_test_file = 1
    endif
  endfor

  " if it does then mark it as the current test file
  if current_file_is_test_file
    let s:spectacular_test_file = expand("%")
  endif

  " filter the configs by running the conditions on the current file
  let configs_for_current_test_file = []
  for config in configs_for_current_filetype
    if match(s:spectacular_test_file, config.pattern) != -1
      let all_conditions_pass = 1
      for Condition in config.conditions
        if !Condition(s:spectacular_test_file)
          let all_conditions_pass = 0
        endif
      endfor

      if all_conditions_pass
        call add(configs_for_current_test_file, config)
      endif
    endif
  endfor

  " find out which of them to actually run (the first one)
  let config_for_current_test_file = get(configs_for_current_test_file, 0)

  " run the command!
  let cmd = substitute(config_for_current_test_file.cmd, "{spec}", s:spectacular_test_file, "")
  execute "!clear & " . cmd
endfunction
