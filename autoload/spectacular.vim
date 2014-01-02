let s:spectacular_test_runners = {}

function! spectacular#add_test_runner(filetype, command, file_pattern, ...)
  if !has_key(s:spectacular_test_runners, a:filetype)
    let s:spectacular_test_runners[a:filetype] = []
  endif

  let list = get(s:spectacular_test_runners, a:filetype)

  call add(list, {
        \ 'pattern': a:file_pattern,
        \ 'conditions': a:000,
        \ 'cmd': a:command })
endfunction

"""""""""""""""""

function! s:path_to_current_file()
  return expand("%")
endfunction

function! s:configs_for_current_filetype()
  return get(s:spectacular_test_runners, &filetype)
endfunction

function! s:current_file_is_test_file()
  for config in s:configs_for_current_filetype()
    if match(s:path_to_current_file(), config.pattern) != -1
      return 1
    endif
  endfor
endfunction

function! s:configs_for_test_file(test_file)
  let acc = []

  for config in s:configs_for_current_filetype()
    if match(a:test_file, config.pattern) != -1
      let all_conditions_pass = 1
      for Condition in config.conditions
        if !Condition(a:test_file)
          let all_conditions_pass = 0
          break
        endif
      endfor

      if all_conditions_pass
        call add(acc, config)
      endif
    endif
  endfor

  return acc
endfunction

function! s:config_for_test_file(test_file)
  return get(s:configs_for_test_file(a:test_file), 0)
endfunction

function! s:run_tests_command()
  return substitute(s:config_for_test_file(s:test_file).cmd, "{spec}", s:test_file, "")
endfunction

function! s:prepare_term_command()
  return "clear & "
endfunction

"""""""""""""""""

function! spectacular#run_tests()
  if s:current_file_is_test_file()
    let s:test_file = s:path_to_current_file()
  endif

  execute "!" . s:prepare_term_command() . s:run_tests_command()
endfunction
