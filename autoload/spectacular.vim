if !exists('g:spectacular_debugging_mode')
  let g:spectacular_debugging_mode = 0
endif

if !exists('g:spectacular_use_terminal_emulator')
  let g:spectacular_use_terminal_emulator = 0
endif

let s:spectacular_test_runners = {}
let s:spectacular_cached_line_number = 0

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

function! s:current_line_number()
  if s:current_file_is_test_file()
    let s:spectacular_cached_line_number = line(".")
  endif

  return s:spectacular_cached_line_number
endfunction

function! s:pattern_matches_test_file(test_file, pattern)
  return match(a:test_file, a:pattern) != -1
endfunction

function! s:command_requires_line_number(cmd)
  return match(a:cmd, "{line-number}") != -1
endfunction

function! s:config_matches_file(test_file, config, with_current_line)
  if s:pattern_matches_test_file(a:test_file, a:config.pattern)
    if a:with_current_line
      return s:command_requires_line_number(a:config.cmd)
    else
      return !s:command_requires_line_number(a:config.cmd)
    endif
  else
    return 0
  endif
endfunction

function! s:configs_for_test_file(test_file, with_current_line)
  let acc = []

  for config in s:configs_for_current_filetype()
    if s:config_matches_file(a:test_file, config, a:with_current_line)
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

function! s:config_for_test_file(test_file, with_current_line)
  let configs = s:configs_for_test_file(a:test_file, a:with_current_line)
  if len(configs) > 0
    return get(configs, 0)
  else
    throw "You have no tests configured for this file type with a line number option"
  endif
endfunction

function! s:run_tests_command(with_current_line)
  let cmd = substitute(s:config_for_test_file(s:test_file, a:with_current_line).cmd, "{spec}", s:test_file, "g")

  if a:with_current_line
    let cmd = substitute(cmd, "{line-number}", s:current_line_number(), "g")
  endif

  if g:spectacular_use_terminal_emulator && !s:is_vim_command(cmd)
    let cmd = substitute(cmd, ' ', '\\ ', "g")
  endif

  return cmd
endfunction

function! s:command_prefix()
  if g:spectacular_use_terminal_emulator
    return "split term://"
  else
    return "!clear; "
  endif
endfunction

function! s:current_file_type_is_testable()
  return has_key(s:spectacular_test_runners, &filetype)
endfunction

function! spectacular#add_test_runner(filetypes, command, file_pattern, ...)
  for type_of_file in split(substitute(a:filetypes, " ", "", "g"), ",")
    if !has_key(s:spectacular_test_runners, type_of_file)
      let s:spectacular_test_runners[type_of_file] = []
    endif

    let list = get(s:spectacular_test_runners, type_of_file)

    call add(list, {
          \ 'pattern': a:file_pattern,
          \ 'conditions': a:000,
          \ 'cmd': a:command })
  endfor
endfunction

function! s:is_vim_command(command)
  return a:command =~? "^:"
endfunction

function! s:run_tests(with_current_line)
  let test_command = s:run_tests_command(a:with_current_line)

  if s:is_vim_command(test_command)
    if g:spectacular_debugging_mode
      echom test_command
    endif

    execute test_command
  else
    let full_command = s:command_prefix() . test_command

    if g:spectacular_debugging_mode
      echom full_command
    endif

    execute full_command
  endif
endfunction

function! s:actually_run_tests(with_current_line)
  if !s:current_file_type_is_testable()
    throw "You have no tests configured for this file type"
  endif

  if s:current_file_is_test_file()
    let s:test_file = s:path_to_current_file()
  endif

  if exists("s:test_file")
    call s:run_tests(a:with_current_line)
  else
    throw "No initial test file has been run"
  endif
endfunction

function! spectacular#run_tests()
  call s:actually_run_tests(0)
endfunction

function! spectacular#run_tests_with_current_line()
  call s:actually_run_tests(1)
endfunction

function! spectacular#reset()
  let s:spectacular_test_runners = {}
endfunction
