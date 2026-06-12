require 'rake/testtask'
require 'rdoc'
require 'rdoc/store'
require 'rdoc/parser/ruby'
require 'rdoc/options'
require 'rdoc/stats'

TASKS_DIR = File.join(__dir__, 'scripts', 'tasks')

def rake_desc(path)
  options = RDoc::Options.new
  store   = RDoc::Store.new(options)
  top     = store.add_file(path)
  stats   = RDoc::Stats.new(store, 0)
  RDoc::Parser::Ruby.new(top, File.read(path), options, stats).scan
  text = top.comment&.text.to_s.strip
  text.empty? ? nil : text.lines.first.strip
end

def define_task(task_name, script_path)
  desc rake_desc(script_path)
  task task_name do
    ARGV.each { |a| task a.to_sym do; end }
    exec 'ruby', script_path, *ARGV.drop(1)
  end
end

Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test/modules/*_test.rb']
  t.verbose    = false
end

Dir.glob(File.join(TASKS_DIR, '*.rb')).each do |script|
  define_task File.basename(script, '.rb'), script
end

Dir.glob(File.join(TASKS_DIR, '*', '*.rb')).each do |script|
  ns   = File.basename(File.dirname(script))
  name = File.basename(script, '.rb')
  namespace ns do
    define_task name, script
  end
end
