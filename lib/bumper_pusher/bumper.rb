require 'colorize'

module BumperPusher

  POD_SPEC_TYPE = 'podspec'
  GEM_SPEC_TYPE = 'gemspec'

  class Bumper

    @spec_mode

    def initialize(options)
      @options = options
    end

    def check_repo_is_clean_or_dry_run
      value =%x[#{'git status --porcelain'}]

      if value.empty?
        puts 'Repo is clean -> continue'
      else
        if @options[:dry_run]
          puts 'Repo not clean, "Dry run" enabled -> continue'
        else
          puts 'Repository not clean -> exit'
          exit
        end
      end
    end


    def find_spec_file

      gem_arr = execute_line("find . -name '*.#{POD_SPEC_TYPE}'").split("\n")
      pod_arr = execute_line("find . -name '*.#{GEM_SPEC_TYPE}'").split("\n")
      if gem_arr.any? && pod_arr.any?
        puts 'Warning: both podspec and gemspec found!'.yellow
      end
      all_specs = gem_arr.concat(pod_arr)

      spec_file = ''

      case all_specs.count
        when 0
          puts 'No spec files found. -> Exit.'
          exit
        when 1
          spec_file = all_specs[0]
        else
          puts 'Which spec should be used?'
          all_specs.each_with_index { |file, index| puts "#{index+1}. #{file}" }
          input_index = Integer(gets.chomp)
          spec_file = all_specs[input_index-1]
      end

      if spec_file == nil
        puts "Can't find specified spec file -> exit"
        exit
      end

      if gem_arr.include?(spec_file)
        @spec_mode = GEM_SPEC_TYPE
      else
        if pod_arr.include?(spec_file)
          @spec_mode = POD_SPEC_TYPE
        else

        end

      end

      spec_file.sub('./', '')

    end

    def find_current_gem_file
      list_of_specs = execute_line("find . -name '*.gem'")
      arr = list_of_specs.split("\n")

      spec_file = ''

      case arr.count
        when 0
          puts "No #{POD_SPEC_TYPE} files found. -> Exit."
          exit
        when 1
          spec_file = arr[0]
        else
          puts 'Which spec should be used?'
          arr.each_with_index { |file, index| puts "#{index+1}. #{file}" }
          input_index = Integer(gets.chomp)
          spec_file = arr[input_index-1]
      end

      if spec_file == nil
        puts "Can't find specified spec file -> exit"
        exit
      end

      spec_file.sub('./', '')

    end

    def find_version_in_file(podspec)
      readme = File.read(podspec)

      #try to find version in format 1.22.333
      re = /(\d+)\.(\d+)\.(\d+)/m

      match_result = re.match(readme)

      unless match_result
        puts 'Not found any versions'
        exit
      end

      puts "Found version #{match_result[0]}"
      return match_result[0], match_result.captures
    end

    def bump_version(versions_array)
      bumped_result = versions_array.dup
      bumped_result.map! { |x| x.to_i }

      case @options[:bump_number]
        when :major
          bumped_result[0] += 1
          bumped_result[1] = 0
          bumped_result[2] = 0
        when :minor
          bumped_result[1] += 1
          bumped_result[2] = 0
        when :patch
          bumped_result[2] += 1
        else
          raise('unknown bump_number')
      end


      bumped_version = bumped_result.join('.')
      puts "Bump version: #{versions_array.join('.')} -> #{bumped_version}"
      bumped_version
    end

    def execute_line(line)
      output = `#{line}`
      check_exit_status(output)

      output
    end

    def execute_line_if_not_dry_run(line)
      if @options[:dry_run]
        puts "Dry run: #{line}"
        nil
      else
        puts line
        value = %x[#{line}]
        puts value
        check_exit_status(value)
        value
      end
    end

    def check_exit_status(output)
      if $?.exitstatus != 0
        puts "Output:\n#{output}\nExit status = #{$?.exitstatus} ->Terminate script."
        exit
      end
    end

    def run_bumping_script

      check_repo_is_clean_or_dry_run

      spec_file = find_spec_file
      version_file = find_version_file
      result, versions_array = find_version_in_file(version_file)
      bumped_version = bump_version(versions_array)

      unless @options[:dry_run]
        puts 'Are you sure? Press Y to continue:'
        str = gets.chomp
        if str != 'Y'
          puts '-> exit'
          exit
        end
      end

      if @options[:bump]
        if @options[:beta]
          bumped_version += 'b'
        end
        execute_line_if_not_dry_run("sed -i \"\" \"s/#{result}/#{bumped_version}/\" README.md")
        execute_line_if_not_dry_run("sed -i \"\" \"s/#{result}/#{bumped_version}/\" #{version_file}")
      end

      if @options[:commit]
        execute_line_if_not_dry_run("git commit --all -m \"Update #{@spec_mode} to version #{bumped_version}\"")
        execute_line_if_not_dry_run("git tag #{bumped_version}")
      end

      if @options[:push]
        execute_line_if_not_dry_run('git push')
        execute_line_if_not_dry_run('git push --tags')
      end

      if @options[:push]
        if @spec_mode == POD_SPEC_TYPE
          execute_line_if_not_dry_run("pod trunk push #{spec_file}")
        else
          if @spec_mode == GEM_SPEC_TYPE
            execute_line_if_not_dry_run("gem build #{spec_file}")
            gem = find_current_gem_file
            execute_line_if_not_dry_run("gem push #{gem}")
          else
            raise 'Unknown spec type'
          end
        end
      end


      if @options[:changelog]
        execute_line_if_not_dry_run("github_changelog_generator")
        execute_line_if_not_dry_run("git commit CHANGELOG.md -m \"Update changelog for version #{bumped_version}\"")
        execute_line_if_not_dry_run('git push')
      end

    end

    def find_version_file
      version_file = nil
      arr = `find . -name 'version.rb'`.split("\n")
      case arr.count
        when 0
          puts "version.rb file found (#{arr[0]}) -> bump this file"
        when 1
          version_file = arr[0]
        else
          puts 'More than 1 version.rb file found. -> skip'
      end

      version_file ? version_file.sub('./', '') : find_spec_file
    end

    def revert_last_bump
      spec_file = find_spec_file
      result, _ = find_version_in_file(spec_file)

      puts "DELETE tag #{result} and HARD reset HEAD~1?\nPress Y to continue:"
      str = gets.chomp
      if str != 'Y'
        puts '-> exit'
        exit
      end
      execute_line_if_not_dry_run("git tag -d #{result}")
      execute_line_if_not_dry_run('git reset --hard HEAD~1')
      execute_line_if_not_dry_run("git push --delete origin #{result}")
    end
  end
end
