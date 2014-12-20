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

  def execute_run_specs_for_file_command(vim, filename)
    edit_file(vim, filename)
    vim.normal ":call spectacular#run_tests()<cr>"
    sleep 0.01
  end

  def execute_run_specs_for_file_at_current_line_command(vim, filename)
    edit_file(vim, filename)
    vim.normal ":call spectacular#run_tests_with_current_line()<cr>"
    sleep 0.01
  end

  def with_a_clean_working_dir
    File.delete("fakeSpec.txt") if File.exists?("fakeSpec.txt")
    File.delete("run.txt") if File.exists?("run.txt")
  end
end
