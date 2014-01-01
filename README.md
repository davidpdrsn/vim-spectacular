# spectacular.vim

spectacular.vim is a vim plugin for running tests.

The important features of spectacular.vim is:

- Works with any language.
- You can configure multiple ways to run tests for the same language.
- You can configure things like "if I'm in a rails app and this test file requires rails to be loaded run tests this way otherwise run them this way".
- It remembers the last test file you ran and re-runs that if you switch to a non-test file.

## Example configuration

From within you vimrc you just call `spectacular#add_test_runner` to add another way to run test. It looks something like this:

```vim
call spectacular#add_test_runner('javascript', 'karma run', 'Spec')

call spectacular#add_test_runner('cucumber', 'cucumber {spec}', '')

call spectacular#add_test_runner('ruby', 'bin/cucumber', '_steps', function("InRailsApp"))
call spectacular#add_test_runner('ruby', 'rspec {spec}', '_spec')
```

The `spectacular#add_test_runner` function takes three or more arguments.

The first argument is the filetype that the test runner applies to.

The second is the command to use for running the tests. `{spec}` will be replaced with the path to current test file.

The third argument is string that the filename most contain in order to be considered a test file. You can leave this blank if all files with the given filetype contain test. This would be true for cucumber files.

Optionally you can pass in more than three arguments in which case the extra arguments most be references to vimscript functions. These functions most return a boolean value (0 or 1) when given the current test file. If any of the functions return false then the current test file will be no run in the specified way. This allows you check for things like "are we in a rails app?", "does the current spec require rails to be loaded?", "does it have a focus tag?", and so on.

If there are multiple runners that all match then the first match will be used. This means that you should probably order your runners by specificity, with the most specific ones at the top.

## Running tests
To actually run the tests you most call the function `spectacular#run_tests()`. You should probably map this to key. Here is the mapping I use.

```vim
map <leader>t :write\|:call spectacular#run_tests()<cr>
```

