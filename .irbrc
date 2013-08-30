# -*- mode: ruby -*-
# https://github.com/carlhuda/bundler/issues/183#issuecomment-1149953
# http://lucapette.com/pry/pry-everywhere/

if defined?(::Bundler)
  Dir.glob("#{Gem.default_dir}/gems/*/lib").each do |path|
    $LOAD_PATH << path
  end
end
require 'awesome_print'
# Use Pry everywhere
require 'pry'
Pry.start
exit
