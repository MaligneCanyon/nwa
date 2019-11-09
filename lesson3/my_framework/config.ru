# config.ru (Rack config file)

# load app.rb (formerly hello_world.rb)
# require_relative 'hello_world'
require_relative 'app'

# spec which ap to run on our server
# run HelloWorld.new # (code in the HelloWorld class, found in hello_world.rb)
run App.new # (code in the App class, found in app.rb)
