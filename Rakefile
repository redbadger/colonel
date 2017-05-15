require "bundler/gem_tasks"

Rake::Task[:release].clear

desc "Build and release v#{Colonel::VERSION} to Gemfury"
task :release => :build do
  sh "curl -F package=@pkg/colonel-#{Colonel::VERSION}.gem https://#{ENV.fetch('GEMFURY_TOKEN')}@push.fury.io/#{ENV.fetch('GEMFURY_USERNAME')}/"
  sh "git tag v#{Colonel::VERSION} -m 'Release #{Colonel::VERSION}'"
  sh "git push origin v#{Colonel::VERSION}"
end
