[![Gem Version](https://badge.fury.io/rb/bumper_pusher.svg)](http://badge.fury.io/rb/bumper_pusher)
[![Build Status](https://travis-ci.org/skywinder/bumper_pusher.svg?branch=master)](https://travis-ci.org/skywinder/bumper_pusher)


# BumperPusher

This gem make bumping and pushing your ruby gems easy and fast!

- Works with `gemspec` and `podspec` files
- Automatically detect your current version (from `spec` or `version.rb` file)
- Auto-bump spec
- Auto-push spec

## Installation
	[sudo] gem install bumper_pusher

## Usage
- Just print: `bumper_pusher` and that's it!
- If you want to test, that all works as expected: try **dry_run** mode: `bumper_pusher --dry-run` 
- To bump version print: `bumper_pusher [option]`
	-  `-r` for bump release (`1.2.3` -> `2.0.0`)
	- `-m` for bump minor (`1.2.3` -> `1.3.0`)
	- `-p` for bump patch (`1.2.3` -> `1.2.4`) **default option**
	
- To install locally your gemspec `bumper_pusher -b`

### Params
	Usage: bumper_pusher [options]
	    -d, --dry-run                    Dry run
	        --release                    Bump release version
	    -m, --minor                      Bump minor version
	    -p, --patch                      Bump patch version
	    -r, --revert                     Revert last bump
	    -i, --[no-]install               Install this gem after push it. Default is true.
	    -b, --beta                       Build beta gem without commit and push
	    -v, --version                    Print version number
	    -c, --[no]-changelog             Auto generation of changelog and pushing it origin. Default is true

## Alternatives
- https://github.com/peritus/bumpversion
- https://github.com/vojtajina/grunt-bump
- https://github.com/gregorym/bump
- https://github.com/svenfuchs/gem-release

## Features & Benefits of this project

- **Very easy to use**: just print `bumper_pusher` in your repo folder.
- Support version storage directly in `gemspec` file and in `version.rb`
- Check that you're bumping from `master`. (otherwise print warning with confirmation)
- Check that your `git status` in clean
- Ability to build test gem easily  `bumper_pusher -b`
- Ability to generate changelog for new version by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)
- Support both `gemspec` and `podspec` files

## Contributing

1. Fork it ( https://github.com/skywinder/bumper_pusher/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
