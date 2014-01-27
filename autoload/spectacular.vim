if !exists('g:spectacular_integrate_with_tmux')
  let g:spectacular_integrate_with_tmux = 0
endif

if !exists('g:spectacular_integrate_with_dispatch')
  let g:spectacular_integrate_with_dispatch = 0
endif

if !exists('g:spectacular_debugging_mode')
  let g:spectacular_debugging_mode = 0
endif

let s:spectacular_test_runners = {}

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

function! s:in_tmux()
  return $TMUX != ""
endfunction

function s:number_of_tmux_panes()
  return system("tmux list-panes \| wc -l \| cut -d \" \" -f 8")
endfunction

function! s:command_prefix()
  if g:spectacular_integrate_with_tmux &&
    \s:in_tmux() &&
    \s:number_of_tmux_panes() > 1 &&
    \exists(":Tmux")
    return "Tmux clear; "
  elseif g:spectacular_integrate_with_dispatch &&
    \exists(":Dispatch")
    return "Dispatch "
  else
    return "!clear; "
  endif
endfunction

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

function! spectacular#run_tests()
  if s:current_file_is_test_file()
    let s:test_file = s:path_to_current_file()
  endif

  let command = s:command_prefix() . s:run_tests_command()

  if g:spectacular_debugging_mode
    echom command
  endif

  execute command
endfunction
