require 'pathname'
require 'rspec/core/rake_task'


ROOT_PTH = Pathname.new File.dirname(__FILE__)
LIB_PTH = ROOT_PTH.join('lib')
OUT_PTH = ROOT_PTH.join('out')


RSpec::Core::RakeTask.new

task :default do
  sh 'rake -T', :verbose => false
end

desc 'Check .travis.yml file format'
task :check_travis do
  sh 'travis-lint', :verbose => false
end

desc 'Install genesis'
task :install do
  success = true
  Rake::Task[:gen_exec].execute if success
  Rake::Task[:make_symlink].execute if success
end

desc 'Create a symlink to genesis in /usr/local/bin'
task :make_symlink do
  Dir.chdir('/usr/local/bin') do
    sh "sudo ln -s #{OUT_PTH.join('genesis')} genesis"
  end
end

desc 'Generate the executable'
task :gen_exec do
  Dir.chdir(OUT_PTH) do
    File.open("genesis", 'w') { |f| f.write(GENESIS_EXEC_CONTENT); f.chmod(0755) }
  end
end


GENESIS_EXEC_CONTENT = <<-CODE
#!/usr/bin/env ruby
$:.push File.expand_path("../../lib", __FILE__)
require 'genesis'

Genesis::App.new(ARGV).run
CODE
