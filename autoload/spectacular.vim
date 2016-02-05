if !exists('g:spectacular_name_of_tmux_test_session')
  let g:spectacular_name_of_tmux_test_session = 'test'
endif

if !exists('g:spectacular_integrate_with_tmux')
  let g:spectacular_integrate_with_tmux = 0
endif

if !exists('g:spectacular_integrate_with_dispatch')
  let g:spectacular_integrate_with_dispatch = 0
endif

if !exists('g:spectacular_debugging_mode')
  let g:spectacular_debugging_mode = 0
endif

if !exists('g:spectacular_clear_screen')
  let g:spectacular_clear_screen = 1
endif

if !exists('g:spectacular_use_neovim')
  let g:spectacular_use_neovim = 0
endif

let s:spectacular_test_runners = {}
let s:spectacular_run_with_current_line = 0
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

function! s:config_matches_file(test_file, config)
  if s:pattern_matches_test_file(a:test_file, a:config.pattern)
    if s:spectacular_run_with_current_line
      return s:command_requires_line_number(a:config.cmd)
    else
      return !s:command_requires_line_number(a:config.cmd)
    endif
  else
    return 0
  endif
endfunction

function! s:configs_for_test_file(test_file)
  let acc = []

  for config in s:configs_for_current_filetype()
    if s:config_matches_file(a:test_file, config)
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
  let configs = s:configs_for_test_file(a:test_file)
  if len(configs) > 0
    return get(configs, 0)
  else
    throw "You have no tests configured for this file type with a line number option"
  endif
endfunction

function! s:run_tests_command()
  let cmd = substitute(s:config_for_test_file(s:test_file).cmd, "{spec}", s:test_file, "")

  if s:spectacular_run_with_current_line
    let cmd = substitute(cmd, "{line-number}", s:current_line_number(), "")
  endif

  if g:spectacular_use_neovim
    let cmd = substitute(cmd, ' ', '\\ ', "")
  endif

  return cmd
endfunction

function! s:in_tmux()
  return $TMUX != ""
endfunction

function! s:number_of_tmux_panes()
  return system("tmux list-panes \| wc -l \| cut -d \" \" -f 8")
endfunction

function! s:tmux_test_session_open()
  return system("tmux list-sessions \| grep " . g:spectacular_name_of_tmux_test_session) != ""
endfunction

function! s:should_run_with_tmux()
  return g:spectacular_integrate_with_tmux &&
       \ s:in_tmux() &&
       \ (s:tmux_test_session_open() || s:number_of_tmux_panes() > 1) &&
       \ exists(":Tmux")
endfunction

function! s:command_prefix()
  if s:should_run_with_tmux()
    return "Tmux clear; "
  elseif g:spectacular_use_neovim
    return "split term://"
  elseif g:spectacular_integrate_with_dispatch && exists(":Dispatch")
    return "Dispatch "
  elseif g:spectacular_clear_screen
    return "!clear; "
  else
    return "!echo \"\\n\\n\\n\\n\\n\\n\\n\\n\\n\\n\\n\"; "
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

function! s:run_tests()
  let test_command = s:run_tests_command()

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

function! spectacular#run_tests()
  if !s:current_file_type_is_testable()
    throw "You have no tests configured for this file type"
  endif

  if s:current_file_is_test_file()
    let s:test_file = s:path_to_current_file()
  endif

  if exists("s:test_file")
    call s:run_tests()
  else
    throw "No initial test file has been run"
  endif
endfunction

function! spectacular#run_tests_with_current_line()
  " TODO: Refactor this to be less ugly
  " I don't like this sorta global config flag that makes
  " some methods be split into two branches
  let s:spectacular_run_with_current_line = 1
  call spectacular#run_tests()
  let s:spectacular_run_with_current_line = 0
endfunction
