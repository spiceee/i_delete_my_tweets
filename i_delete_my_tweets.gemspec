lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'i_delete_my_tweets/version'

Gem::Specification.new do |spec|
  spec.add_dependency 'activesupport', '~> 6.1.5.1'
  spec.add_dependency 'csv', '~> 3.0.9'
  spec.add_dependency 'dotenv', '~> 2.7.6'
  spec.add_dependency 'oauth', '>= 0.5.5'
  spec.add_dependency 'progress', '~> 3.6.0'
  spec.add_dependency 'terminal-table', '~> 3.0.2'
  spec.add_dependency 'thor', '~> 1.2.1'
  spec.add_dependency 'twitter', '~> 7.0.0'
  spec.add_development_dependency 'bundler', '>= 1.0', '< 3'
  spec.add_development_dependency 'rubocop', '~> 1.29'
  spec.add_development_dependency 'rubocop-performance', '~> 1.13.3'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.10.0'
  spec.add_development_dependency 'semver2', '~> 3.4.2'
  spec.authors = %w('Fabio Mont Alegre')
  spec.platform = Gem::Platform::RUBY
  spec.description = IDeleteMyTweets::Description
  spec.email = %w(spiceee@gmail.com)
  spec.homepage = 'https://github.com/spiceee/i_delete_my_tweets'
  spec.licenses = %w(MIT)
  spec.executables = %w(i_delete_my_tweets)
  spec.name = 'i_delete_my_tweets'
  spec.require_paths = %w(lib)
  spec.required_ruby_version = '>= 2.6.5'
  spec.required_rubygems_version = '>= 1.3.5'
  spec.summary = 'A CLI to delete your tweets based on faves, RTs, and time.'
  spec.files = Dir["*.md", "bin/*", "lib/**/*.rb"] + %w(.env.sample .env.test tweets.csv i_delete_my_tweets.gemspec)
  spec.version = IDeleteMyTweets::Version
  spec.metadata['rubygems_mfa_required'] = 'true'
end
