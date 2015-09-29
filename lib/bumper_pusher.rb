#!/usr/bin/env ruby

require_relative "bumper_pusher/version"
require_relative "bumper_pusher/parser"
require_relative "bumper_pusher/bumper"

module BumperPusher
  class Pusher
    attr_reader :options
    def initialize
      @options = BumperPusher::Parser.new.parse_options
      @options.freeze

      @parser = BumperPusher::Bumper.new(@options)

      if @options[:revert]
        @parser.revert_last_bump
      else
        @parser.run_bumping_script
      end
    end
  end
end

bumper = BumperPusher::Pusher.new if $PROGRAM_NAME == __FILE__
