require 'colorize'
require "readline"
require 'open3'
module BumperPusher

  POD_SPEC_TYPE = 'podspec'
  GEM_SPEC_TYPE = 'gemspec'

  class Bumper

    @spec_mode

    def initialize(options)
      @options = options
      @spec_file = find_spec_file
    end

    def check_repo_is_clean_or_dry_run
      value =%x[#{'git status --porcelain'}]

      if value.empty?
        puts 'Repo is clean -> continue'
      else
        if @options[:dry_run]
          puts 'Repo not clean, "Dry run" enabled -> continue'
        else
          if @options[:beta]
            puts 'Repo not clean, "Beta build" enabled -> continue'
          else
            puts 'Repository not clean -> exit'
            exit
          end
        end
      end

      current_branch = get_current_branch

      unless @options[:beta]

        if is_git_flow_installed
          # supposed, that with git flow you should release from develop branch
          if current_branch != 'develop' && !is_branch_hotfix?
            puts "Warning: You're in branch (#{current_branch})!".yellow
            ask_sure_Y
          end
        else
          # supposed, that w/o git flow you should release from master or release branch
          if current_branch != 'master' || !/release/.match(current_branch)[0].nil?
            puts "Warning: You're in branch (#{current_branch})!".yellow
            ask_sure_Y
          end
        end

      end
    end

    def get_current_branch
      `git rev-parse --abbrev-ref HEAD`.strip!
    end


    def find_spec_file

      pod_arr = execute_line("find . -name '*.#{POD_SPEC_TYPE}'").split("\n")
      gem_arr = execute_line("find . -name '*.#{GEM_SPEC_TYPE}'").split("\n")
      if gem_arr.any? && pod_arr.any?
        puts 'Warning: both podspec and gemspec found!'.yellow
      end
      all_specs = gem_arr | pod_arr

      spec_file = ''

      case all_specs.count
        when 0
          puts 'No spec files found. -> Exit.'
          if is_debug?
            puts 'Debug -> set @spec_mode to gem -> continue'
            @spec_mode = GEM_SPEC_TYPE
          else
            exit
          end
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

    def is_debug?
      (ENV['RUBYLIB'] =~ /ruby-debug-ide/) ? true : false
    end

    def find_current_gem_file
      list_of_specs = execute_line("find . -name '*.gem'")
      arr = list_of_specs.split("\n")

      spec_file = ''

      case arr.count
        when 0
          if @options[:dry_run]
            return "test.#{POD_SPEC_TYPE}"
          end
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

      if @options[:beta]
        bumped_version = versions_array.join('.') + '.1'
      else
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
      end

      puts "Bump version: #{versions_array.join('.')} -> #{bumped_version}"

      unless @options[:dry_run] || @options[:beta]
        ask_sure_Y
      end

      bumped_version
    end

    def ask_sure_Y
      unless @options[:dry_run]
        puts 'Are you sure? Press Y to continue:'
        str = gets.chomp
        if str != 'Y'
          puts '-> exit'
          exit
        end
      end
    end

    def execute_line(line)
      output = `#{line}`
      check_exit_status(output)

      output
    end

    def execute_line_if_not_dry_run(line, check_exit = true)
      if @options[:dry_run]
        puts "Dry run: #{line}"
        check_exit ? nil : 0
      else
        puts line
        value = %x[#{line}]
        if check_exit
          puts value
          check_exit_status(value)
          value
        else
          $?.exitstatus
        end
      end
    end

    def execute_interactive_if_not_dry_run(cmd)
      if @options[:dry_run]
        puts "Dry run: #{cmd}"
        nil
      else
        Open3.popen3(cmd) do |i, o, e, th|
          Thread.new {
            until i.closed? do
              input =Readline.readline("", true).strip
              i.puts input
            end
          }

          t_err = Thread.new {
            until e.eof? do
              putc e.readchar
            end
          }

          t_out = Thread.new {
            until o.eof? do
              putc o.readchar
            end
          }

          Process::waitpid(th.pid) rescue nil
          # "rescue nil" is there in case process already ended.

          t_err.join
          t_out.join
        end
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

      unless @options[:beta]
        unless is_branch_hotfix?
          execute_line_if_not_dry_run('git pull')
        end
        current_branch = get_current_branch
        execute_line_if_not_dry_run("git checkout master && git pull && git checkout #{current_branch}")
      end

      version_file = find_version_file
      result, versions_array = find_version_in_file(version_file)
      bumped_version = bump_version(versions_array)


      unless @options[:beta]
        execute_line_if_not_dry_run('git push --all')
        if is_git_flow_installed && !is_branch_hotfix?
          execute_line_if_not_dry_run("git flow release start #{bumped_version}")
        end
      end

      if @options[:bump]
        execute_line_if_not_dry_run("sed -i \"\" \"s/#{result}/#{bumped_version}/\" README.md")
        execute_line_if_not_dry_run("sed -i \"\" \"s/#{result}/#{bumped_version}/\" #{version_file}")
      end

      if @options[:commit]
        execute_line_if_not_dry_run("git commit --all -m \"Update #{@spec_mode} to version #{bumped_version}\"")

        if is_git_flow_installed
          if is_branch_hotfix?
            branch_split = get_current_branch.split('/').last
            unless execute_line_if_not_dry_run("git flow hotfix finish -n #{branch_split}", check_exit = false) == 0
              ask_to_merge
              execute_line_if_not_dry_run("git flow hotfix finish -n #{branch_split}")
            end
          else
            unless execute_line_if_not_dry_run("git flow release finish -n #{bumped_version}", check_exit = false) == 0
              ask_to_merge
              execute_line_if_not_dry_run("git flow release finish -n #{bumped_version}")
            end
          end
          execute_line_if_not_dry_run('git checkout master')
        end
        execute_line_if_not_dry_run("git tag #{bumped_version}")
      end

      if @options[:push]
        execute_line_if_not_dry_run('git push --all')
        execute_line_if_not_dry_run('git push --tags')

        if @spec_mode == POD_SPEC_TYPE
          execute_line_if_not_dry_run("pod trunk push #{@spec_file}")
        else
          if @spec_mode == GEM_SPEC_TYPE
            execute_line_if_not_dry_run("gem build #{@spec_file}")
            gem = find_current_gem_file
            execute_line_if_not_dry_run("gem push #{gem}")

            if @options[:install]
              execute_line_if_not_dry_run("gem install #{gem}")
            end

            execute_line_if_not_dry_run("rm #{gem}")
          else
            raise 'Unknown spec type'
          end
        end
      end

      if @options[:beta]
        if @spec_mode == GEM_SPEC_TYPE
          execute_line_if_not_dry_run("gem build #{@spec_file}")
          gem = find_current_gem_file
          execute_interactive_if_not_dry_run("gem install #{gem}")

          execute_line_if_not_dry_run("sed -i \"\" \"s/#{bumped_version}/#{result}/\" README.md")
          execute_line_if_not_dry_run("sed -i \"\" \"s/#{bumped_version}/#{result}/\" #{version_file}")
          execute_line_if_not_dry_run("rm #{gem}")
        else
          raise 'Unknown spec type'
        end
      end


      if @options[:changelog] && !@options[:beta]
        if `which github_changelog_generator`.empty?
          puts 'Cancelled bumping: no github_changelog_generator gem found'
        else

          if is_git_flow_installed
            execute_line_if_not_dry_run('git flow hotfix start update-changelog')
          end
          execute_line_if_not_dry_run('github_changelog_generator')
          execute_line_if_not_dry_run("git commit CHANGELOG.md -m \"Update changelog for version #{bumped_version}\"")
          if is_git_flow_installed
            unless execute_line_if_not_dry_run('git flow hotfix finish -n update-changelog', check_exit = false) == 0
              ask_to_merge
              execute_line_if_not_dry_run('git flow hotfix finish -n update-changelog')
            end
            execute_line_if_not_dry_run("git push && git checkout master && git push && git checkout #{get_current_branch}")
          else
            execute_line_if_not_dry_run('git push')
          end

        end
      end

    end

    def ask_to_merge
      puts 'Automatic merge failed, please open new terminal, resolve conflicts, then press Y. Or press N to terminate'
      str = ''
      while str != 'Y' && str != 'N'
        str = gets.chomp
        puts str
      end
      if str == 'N'
        puts '-> exit'
        exit
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

      version_file ? version_file.sub('./', '') : @spec_file
    end

    def revert_last_bump
      spec_file = @spec_file
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

    def is_git_flow_installed
      system("git flow version") ? true : false
    end

    def is_branch_hotfix?
      branch = get_current_branch
      branch.include? 'hotfix'
    end

  end

end

if $0 == __FILE__
  puts 'bumper.rb self run'

  BumperPusher::Bumper.new({}).execute_interactive_if_not_dry_run("pwd")
end
