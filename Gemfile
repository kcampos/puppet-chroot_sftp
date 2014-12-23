source "http://rubygems.org"
source "http://gems.github.com"

group :development do
  gem 'rspec', ['>= 2.9 ', '< 3.0.0']
  gem "rspec-puppet", :git => "git://github.com/rodjek/rspec-puppet.git"
  gem "rake"
  gem 'hiera-puppet-helper'
  gem 'puppetlabs_spec_helper'
end

group :ci do
  puppetversion = ENV.key?('PUPPET_VERSION') ? "#{ENV['PUPPET_VERSION']}" : '>= 3.3'
  gem "puppet", puppetversion
end
