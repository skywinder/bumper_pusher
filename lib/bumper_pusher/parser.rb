#!/usr/bin/env ruby
require 'optparse'

module BumperPusher

  class Parser

    def initialize

    end

    def parse_options
      options = {:dry_run => false, :bump_number => :patch, :changelog => true, :bump => true, :commit => true, :build => true, :push => true}

      OptionParser.new { |opts|
        opts.banner = 'Usage: bump.rb [options]'

        opts.on('-d', '--dry-run', 'Dry run') do |v|
          options[:dry_run] = v
        end
        opts.on('-r', '--release', 'Bump release version') do |v|
          options[:bump_number] = :major
        end
        opts.on('-m', '--minor', 'Bump minor version') do |v|
          options[:bump_number] = :minor
        end
        opts.on('-p', '--patch', 'Bump patch version') do |v|
          options[:bump_number] = :patch
        end
        opts.on('-r', '--revert', 'Revert last bump') do |v|
          options[:revert] = v
        end
        opts.on('-b', '--beta', 'Build beta gem without commit and push') do |v|
          options[:beta] = v
          options[:bump] = v
          options[:build] = v
          options[:commit] = !v
          options[:push] = !v

        end
        opts.on('-v', '--version', 'Print version number') do |v|
          puts "Version: #{BumperPusher::VERSION}"
          exit
        end
        opts.on('-c', '--[no]-changelog', 'Auto generation of changelog and pushing it origin. Default is true') do |v|
          options[:changelog] = v
        end
      }.parse!
      options
    end
  end
end