require "vimrunner"
require "vimrunner/rspec"

ROOT = File.expand_path("../..", __FILE__)

Vimrunner::RSpec.configure do |config|
  config.start_vim do
    vim = Vimrunner.start

    vim.add_plugin(File.join(ROOT, "autoload"), "spectacular.vim")

    vim
  end
end

