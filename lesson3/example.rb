require 'erb'
template = File.read('example.erb')
erb = ERB.new(template)
p erb.result
