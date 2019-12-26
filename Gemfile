source "https://rubygems.org"


def mries(*versions)
  versions.map do |v|
    %w(ruby mingw x64_mingw).map do |platform|
      "#{platform}_#{v}".to_sym unless platform == "x64_mingw" && v < "2.0"
    end.delete_if &:nil?
  end.flatten
end
# Specify your gem's dependencies in bumper_pusher.gemspec

if RUBY_VERSION && RUBY_VERSION >= "2.0"
  gem "debase", "~> 0.2", ">= 0.2.2", :platforms => mries('20', '21', '22', '23', '24', '25')
end

gemspec

group :development do
  gem "bundler"
end
