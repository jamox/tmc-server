require 'exercise_dir'

class ExerciseDir
  class Xml < ExerciseDir
    def library_jars
      # no libs
    end

    def clean!
      # it seems that we don't need to clean
    end

    def has_tests?
      File.exist?("#{@path}/checking") &&
        !(Dir.entries("#{@path}/checking") - ['.', '..', '.gitkeep', '.gitignore']).empty?
    end
  end
end
