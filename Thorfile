$LOAD_PATH.unshift File.expand_path('lib/i_delete_my_tweets', __dir__)

require "bundler"
require "thor/rake_compat"

class Default < Thor
  include Thor::RakeCompat
  Bundler::GemHelper.install_tasks

  desc "spec", "Run RSpec code examples"
  def spec
    exec "bundle exec rspec spec"
  end
end
