require "spec_helper"

describe "vim-spectacular" do
  before { with_a_clean_working_dir }

  describe "spectacular#run_tests()" do
    it "it runs the tests for the current file" do
      register_spec_runner(vim, "'text', 'echo \"{spec}\" > run.txt', 'Spec'")

      execute_run_specs_for_file_command(vim, "fakeSpec.txt")

      expect(executed_command).to eq "fakeSpec.txt\n"
    end

    it "it only runs the test with matching runners" do
      register_spec_runner(vim, "'text', 'echo \"{spec}\" > run.txt', 'Spec'")
      register_spec_runner(vim, "'php', 'echo \"{spec} php\" >> run.txt', 'Spec'")

      execute_run_specs_for_file_command(vim, "fakeSpec.txt")

      expect(executed_command).to eq "fakeSpec.txt\n"
    end

    it "it runs the tests for the current file with the first matching runner" do
      register_spec_runner(vim, "'text', 'echo \"{spec} first\" > run.txt', 'Spec'")
      register_spec_runner(vim, "'text', 'echo \"{spec} second\" > run.txt', 'Spec'")

      execute_run_specs_for_file_command(vim, "fakeSpec.txt")

      expect(executed_command).to eq "fakeSpec.txt first\n"
    end

    it "can use vimscript functions to determine the matching runner" do
      write_to_functions_file <<-EOS
        function! False(...)
          return 0
        endfunction

        function! True(...)
          return 1
        endfunction
      EOS
      vim.source("functions.vim")

      register_spec_runner(vim, "'text', 'echo \"{spec} first\" > run.txt', 'Spec', function('False')")
      register_spec_runner(vim, "'text', 'echo \"{spec} second\" > run.txt', 'Spec', function('False'), function('True')")
      register_spec_runner(vim, "'text', 'echo \"{spec} third\" > run.txt', 'Spec', function('True')")
      register_spec_runner(vim, "'text', 'echo \"{spec} forth\" > run.txt', 'Spec'")

      execute_run_specs_for_file_command(vim, "fakeSpec.txt")

      expect(executed_command).to eq "fakeSpec.txt third\n"
    end

    it "calls the predicate functions with the name of the current file" do
      write_to_functions_file <<-EOS
        function! Predicate(test_file)
          let g:prope = a:test_file
          return 0
        endfunction
      EOS
      vim.source("functions.vim")
      register_spec_runner(vim, "'text', 'echo \"{spec} first\" > run.txt', 'Spec', function('Predicate')")

      execute_run_specs_for_file_command(vim, "fakeSpec.txt")
      result = vim.command("echo g:prope")

      expect(result).to eq "fakeSpec.txt"
    end
  end

  describe "spectacular#run_tests_with_current_line()" do
    it "runs the tests for the current file at the current line" do
      register_spec_runner(vim, "'text', 'echo \"{spec} {line-number}\" > run.txt', 'Spec'")

      execute_run_specs_for_file_at_current_line_command(vim, "fakeSpec.txt")

      expect(executed_command).to eq "fakeSpec.txt 1\n"
    end

    it "only runs configs with {line-numbers}" do
      register_spec_runner(vim, "'text', 'echo \"{spec}\" > run.txt', 'Spec'")
      register_spec_runner(vim, "'text', 'echo \"{spec} {line-number}\" > run.txt', 'Spec'")

      execute_run_specs_for_file_at_current_line_command(vim, "fakeSpec.txt")

      expect(executed_command).to eq "fakeSpec.txt 1\n"
    end
  end

  def edit_file(vim, filename)
    vim.edit filename
    vim.write
  end

  def register_spec_runner(vim, runner_args)
    vim.normal ":call spectacular#add_test_runner(#{runner_args})<cr>"
  end

  def executed_command
    File.read("run.txt")
  end

  def write_to_functions_file(text)
    File.write("functions.vim", text)
  end

  def execute_run_specs_for_file_command(vim, filename)
    edit_file(vim, filename)
    vim.normal ":call spectacular#run_tests()<cr>"
    sleep 0.5
  end

  def execute_run_specs_for_file_at_current_line_command(vim, filename)
    edit_file(vim, filename)
    vim.normal ":call spectacular#run_tests_with_current_line()<cr>"
    sleep 0.5
  end

  def with_a_clean_working_dir
    File.delete("fakeSpec.txt") if File.exists?("fakeSpec.txt")
    File.delete("run.txt") if File.exists?("run.txt")
    File.delete("functions.vim") if File.exists?("functions.vim")
  end
end
