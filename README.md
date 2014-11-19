# BumperPusher

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bumper_pusher'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bumper_pusher

## Usage
- To bump path version and push your gemspec or podscpec file: `bumper_pusher`
	-  `-r` for bump release
	- `-m` for bump minor 
	- `-p` for bump patch (default option)
	
- To install locally your gemspec `bumper_pusher -b`

..Look at **Params** section for details.

### Params:
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
## Contributing

1. Fork it ( https://github.com/skywinder/bumper_pusher/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
