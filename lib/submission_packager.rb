require 'tmpdir'
require 'fileutils'
require 'pathname'
require 'shellwords'
require 'system_commands'
require 'tmc_junit_runner'
require 'tmc_dir_utils'
require 'submission_packager/java_simple'
require 'submission_packager/java_maven'
require 'submission_packager/makefile_c'

# Takes a submission zip and makes a tar file suitable for the sandbox
class SubmissionPackager
  def self.get(exercise)
    cls_name = exercise.exercise_type.to_s.camelize
    cls = SubmissionPackager.const_get(cls_name)
    cls.new
  end

  def package_submission(exercise, zip_path, return_file_path, extra_params = {}, config = {})
    # When :tests_from_stub no hidden tests are included in zip
    tests_from_stub = config[:tests_from_stub]
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('received')
        FileUtils.mkdir_p('dest')

        Dir.chdir('received') do
          sh! ['unzip', zip_path]
          remove_trash_files
        end

        if tests_from_stub
          FileUtils.mkdir_p('stub')
          Dir.chdir('stub') do
            sh! ['unzip', exercise.stub_zip_file_path]
            remove_trash_files
          end
          stub = Pathname(find_received_project_root(Pathname('stub')))
        end

        received = Pathname(find_received_project_root(Pathname('received')))
        dest = Pathname('dest')

        write_extra_params(dest + '.tmcparams', extra_params) unless !extra_params || extra_params.empty?

        # to get hidden tests etc, gsub stub with clone path...
        if tests_from_stub
          copy_files(exercise, received, dest, stub, no_tmc_run: config[:no_tmc_run])
        else
          copy_files(exercise, received, dest, nil, no_tmc_run: config[:no_tmc_run])
        end

        if config[:format] == :zip
          Dir.chdir(dest) do
            sh! ['zip', '-r', return_file_path, '.']
          end
        else
          sh! ['tar', '-C', dest.to_s, '-cpf', return_file_path, '.']
        end
      end
    end
  end

  def get_submission_with_tests(submission)
    exercise = submission.exercise
    Dir.mktmpdir do |tmpdir|
      zip_path = "#{tmpdir}/submission.zip"
      return_zip_path ||= "#{tmpdir}/submission_to_be_returned.zip"
      File.open(zip_path, 'wb') {|f| f.write(submission.return_file) }
      SubmissionPackager.get(exercise).package_submission(exercise, zip_path, return_zip_path, submission.params, {tests_from_stub: true, format: :zip, no_tmc_run: true})
      File.read(return_zip_path)
    end
  end

  private
  include SystemCommands

  # Stupid OS X default zipper puts useless crap into zip files :[
  # Delete them or they might be mistaken for the actual source files later
  # Let's clean up other similarly useless files while we're at it
  def remove_trash_files
    FileUtils.rm_f %w(__MACOSX .DS_Store desktop.ini Thumbs.db .directory)
  end

  def find_received_project_root(received_root)
    raise "Implemented by subclass"
  end

  # received, dest and stub are Pathname objects
  def copy_files(exercise, received, dest, stub=nil, opts = {})
    raise "Implemented by subclass"
  end

  # Some utilities
  def copy_files_in_dir_no_recursion(src, dest)
    src = Pathname(src)
    dest = Pathname(dest)
    src.children(false).each do |filename|
      filename = filename.to_s
      FileUtils.cp(src + filename, dest + filename) unless (src + filename).directory?
    end
  end

  def cp_r_if_exists(src, dest)
    if File.exist?(src)
      FileUtils.cp_r(src, dest)
    end
  end

  def copy_extra_student_files(tmc_project_file, received, dest)
    tmc_project_file.extra_student_files.each do |rel_path|
      from = "#{received}/#{rel_path}"
      to = "#{dest}/#{rel_path}"
      if File.exists?(from)
        FileUtils.rm(to) if File.exists?(to)
        FileUtils.mkdir_p(File.dirname(to))
        FileUtils.cp(from, to)
      end
    end
  end

  def write_extra_params(file, extra_params)
    File.open(file, 'wb') do |f|
      for k, v in extra_params
        f.puts Shellwords.join(['export', "#{k}=#{v}"]) # Format checked in Submission.valid_param?
      end
    end
  end
end

