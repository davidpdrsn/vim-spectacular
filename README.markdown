# vim-spectacular

[![Build Status](https://travis-ci.org/davidpdrsn/vim-spectacular.svg?branch=master)](https://travis-ci.org/davidpdrsn/vim-spectacular)

vim-spectacular is a vim plugin for running tests.

The important features of vim-spectacular is:

- Works with any language.
- You can configure multiple ways to run tests for the same language.
- You can configure things like "if I'm in a rails app and this test file requires rails to be loaded run tests this way otherwise run them this way".
- It remembers the last test file you ran and re-runs that if you switch to a non-test file.

Other nice to have features

- Configure how to run the test at the current line (if you framework supports it).
- Reuse the same config across file types.

## Example configuration

From within you vimrc you just call `spectacular#add_test_runner` to add another way to run test. It looks something like this:

```vim
call spectacular#add_test_runner('javascript', 'karma run', 'Spec')

call spectacular#add_test_runner('cucumber', 'cucumber {spec}', '')

call spectacular#add_test_runner('ruby, javascript, coffee, eruby', 'bin/rspec {spec}', '_spec.rb', function("InRailsApp"), function("TestsRequireRails"))
call spectacular#add_test_runner('ruby', 'rspec {spec}', '_spec')
```

The `spectacular#add_test_runner` function takes three or more arguments.

1. The first argument is the file type that the test runner applies to. This can be a comma separated list of file types.
2. The second is the command to use for running the tests. `{spec}` will be replaced with the path to current test file.
3. The third argument is string that the filename most contain in order to be considered a test file. You can leave this blank if all files with the given file type contain test. This would be true for cucumber files.

Optionally you can pass in more than three arguments in which case the extra arguments must be references to vimscript functions. These functions must return a boolean value (0 or 1) when given the current test file. If any of the functions return false then the current test file will not be run in the specified way, it will move on to checking the rest. This allows you check for things like "are we in a rails app?", "does the current spec require rails to be loaded?", "does it have a focus tag?", and so on.

If there are multiple runners that all match then the first match will be used. This means that you should probably order your runners by specificity, with the most specific ones at the top.

## Running tests
To actually run the tests you most call the function `spectacular#run_tests()`. You should probably map this to key. Here is the mapping I use.

```vim
map <leader>t :write\|:call spectacular#run_tests()<cr>
```

## Running test at current line

Some testing frameworks allow you to run just the test at a specific line (such as Rspec). To configure this, write a test runner configuration like this:

```vim
call spectacular#add_test_runner('ruby', 'rspec {spec}:{line-number}', '_spec')
```

When you then run

```vim
:call spectacular#run_tests_with_current_line()<cr>
```

It will then substitute `{line-number}` with your current line number, and run the test. When you rerun your tests from another file it will remember the line you were at and do the right thing.

Note that when you run `spectacular#run_tests_with_current_line()` it will only look for configurations where the command contains `{line-number}`. This is to not make the setup/precedence too confusing.

## Using Vim commands for testing

It might be the case that you wanna run some Vimscript function that you've defined to run tests, instead of a shell command. This can be done by defining a test command that looks like this:

```vim
call spectacular#add_test_runner('clojure', ':call RunClojureTests()', '')
```

Note the leading ":" in front of the test command.

## Installation

I recommend using [Vundle](https://github.com/gmarik/Vundle.vim). Just add this to your vimrc:

```vim
Plugin 'davidpdrsn/vim-spectacular'
```

## Configuration

A few configuration options are available. They are set with global variables.

```vim
" Run tests in a new split using Neovim's `:terminal` command
" Note this requires you're using Neovim
" If not using `:terminal` `:!` will be used
" Default is 0
let g:spectacular_use_terminal_emulator = 0

" Put the command run onto `:messages`. Useful for debugging
" Default is 0
let g:spectacular_debugging_mode = 0
```

## Running the tests

This plugin has a few tests that ensure basic correctness of the most important functionality. Follow these setups to run the tests:

- Clone down the repo
- `bundle install`
- Look at setup required for [vimrunner](https://github.com/AndrewRadev/vimrunner)
- `bundle exec rspec .`

The tests don't have 100% coverage but if you wanna help out, [this issue](https://github.com/davidpdrsn/vim-spectacular/issues/10) is a list things yet to be tested.

## License

vim-spectacular is released under the [MIT License](http://www.opensource.org/licenses/MIT).
