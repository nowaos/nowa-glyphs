require 'rake/testtask'

TASKS_DIR = File.join(__dir__, 'scripts', 'tasks')

# First line of the script's header comment, used as the task description.
def rake_desc(path)
  File.foreach(path) do |line|
    next if line.start_with?('#!')
    stripped = line.strip
    next if stripped.empty?
    break unless stripped.start_with?('#')

    text = stripped.sub(/\A#+\s*/, '')
    return text unless text.empty?
  end
  nil
end

def define_task(task_name, script_path)
  desc rake_desc(script_path)
  task task_name do
    ARGV.each { |a| task a.to_sym do; end }
    exec 'ruby', script_path, *ARGV.drop(1)
  end
end

Rake::TestTask.new(:test) do |t|
  filter = ARGV.select { |a| a.end_with?('.rb') }
  t.test_files = filter.empty? ? FileList['test/{tasks,links}/*_test.rb'] : filter
  t.verbose    = false
end
ARGV.select { |a| a.end_with?('.rb') }.each { |f| task f.to_sym {} }

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
