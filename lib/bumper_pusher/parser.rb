#!/usr/bin/env ruby
require "optparse"

module BumperPusher
  class Parser
    def initialize
    end

    def parse_options
      options = { dry_run: false, bump_number: :patch, changelog: false, bump: true, commit: true, build: true, push: true, install: true }

      OptionParser.new do |opts|
        opts.banner = "Usage: bumper_pusher [options]"

        opts.on("-d", "--dry-run", "Dry run") do |v|
          options[:dry_run] = v
        end
        opts.on("-r", "--release", "Bump release version") do |_v|
          options[:bump_number] = :major
        end
        opts.on("-m", "--minor", "Bump minor version") do |_v|
          options[:bump_number] = :minor
        end
        opts.on("-p", "--patch", "Bump patch version") do |_v|
          options[:bump_number] = :patch
        end
        opts.on("-r", "--revert", "Revert last bump") do |v|
          options[:revert] = v
        end
        opts.on("-i", "--[no-]install", "Install this gem after push it. Default is true.") do |v|
          options[:install] = v
        end
        opts.on("-b", "--beta", "Build beta gem without commit and push") do |v|
          options[:beta] = v
          options[:bump] = v
          options[:build] = v
          options[:commit] = !v
          options[:push] = !v
        end
        opts.on("-v", "--version", "Print version number") do |_v|
          puts "Version: #{BumperPusher::VERSION}"
          exit
        end
        opts.on("-gc", "--gen-changelog", "Auto generation of changelog and pushing it origin. Default is false") do |v|
          options[:changelog] = v
        end        
      end.parse!
      options
    end
  end
end
