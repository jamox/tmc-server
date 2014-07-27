require 'yaml'
require 'open3'
require 'diffy'
require 'json'

def format_command(testcase)
  testcase['command'].join(" ")
end

def putsb(str = "")
  $stdout.puts str
  $stderr.puts str
end

def run_commamd_printing_command(command, hash)
  putsb command % hash
  Open3.capture3({"PATH" => ".:#{ENV["PATH"]}"}, (command % hash))
end

# Lets ignore paths for solution and for submission source
def process_diff(str)
  str.gsub!('checking/', 'xxxxx/')
  str.gsub!('src/', 'xxxxx/')
  str.strip!
  str
end


def diff(solution, student)
  solution = process_diff(solution)
  student = process_diff(student)
  solution==student
end

def wrap(str, out)
  out.puts "↓"*80
  out.puts str
  out.puts "↑"*80
  out.puts
end



options = YAML.load_file 'metadata.yml'
#puts options.inspect

results = []
options['testing']['tests'].each do |testcase|
  testcase_results = {}
  putsb "Testcase #{testcase['description']}"
  putsb "Points related: #{testcase['points'].uniq.sort.join(", ")}"
  putsb
  putsb
  stdout_solution, stderr_solution, status_solution = run_commamd_printing_command(format_command(testcase),  {xsd_folder: 'checking/', xmlfolder: 'checking/'})
  stdout_student, stderr_student, status_student = run_commamd_printing_command(format_command(testcase),  {xsd_folder: 'checking/', xmlfolder: 'src/'})

  $stdout.puts "solution"
  wrap(process_diff(stdout_solution), $stdout)
  $stdout.puts "student"
  wrap(process_diff(stdout_student), $stdout)
  $stdout.puts "result: "
  stdout_res = diff(stdout_solution, stdout_student)
  wrap(stdout_res,  $stdout)

  $stderr.puts "solution"
  wrap(process_diff(stderr_solution), $stderr)
  $stderr.puts "student"
  wrap(process_diff(stderr_student), $stderr)
  $stderr.puts "result: "
  stderr_res = diff(stderr_solution, stderr_student)
  wrap(stderr_res, $stderr)

  testcase_results['methodName'] = testcase['description']
  testcase_results['pointNames'] = testcase['points'].uniq.sort
  testcase_results['status'] = (stdout_res &&stderr_res) ? 'PASSED' : 'FAILED'
  testcase_results['message'] = "STDOUT: #{Diffy::Diff.new(stdout_solution, stdout_student)}\n"
  testcase_results['message'] << "STDERR: #{Diffy::Diff.new(stderr_solution, stderr_student)}"
  results << testcase_results
end

File.write('test_output.txt', results.to_json)


#"%{greeting} %{entity}!" % {greeting: "Hello", entity: "World"}

