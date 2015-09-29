# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "bumper_pusher/version"

Gem::Specification.new do |spec|
  spec.name          = "bumper_pusher"
  spec.version       = BumperPusher::VERSION
  spec.authors       = ["Petr Korolev"]
  spec.email         = ["sky4winder@gmail.com"]
  spec.summary       = "Easiest way to bump your specs"
  spec.description   = "Bumping and pushing your ruby gems easy and fast!"
  spec.homepage      = "https://github.com/skywinder/bumper_pusher"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_runtime_dependency("colorize", ["~> 0.7"])
  spec.add_runtime_dependency("github_changelog_generator", ">= 1.2", "< 5.0")
end
