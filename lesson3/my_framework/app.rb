# app.rb (formerly hello_world.rb)
require 'erb' # loads the ERB lib
require_relative 'web_frame' # loads (our little web framework) web_frame.rb
require_relative 'advice' # loads advice.rb

# class HelloWorld
class App
  def call(env)
    # template = File.read("views/index.erb") # move to #erb method
    # content = ERB.new(template).result      # move to #erb method
    case env["REQUEST_PATH"]
    when "/"
      # [
      #   "200",
      #   {"Content-Type" => "text/html"},
      #   # ["<html><body><h2>Hello World!</h2></body></html>"]
      #   # [content.result] # replaces line above
      #   [erb(:index)]      # replaces line above
      # ]
      status = '200'
      headers = {"Content-Type" => 'text/html'}
      response(status, headers) { erb(:index) }
    when "/advice"
      # [
      #   "200",
      #   {"Content-Type" => "text/html"},
      #   # ["<html><body><b><em>#{Advice.new.generate}</em></b></body></html>"]
      #   [erb(:advice, message: Advice.new.generate)]
      # ]
      status = '200'
      headers = {"Content-Type" => 'text/html'}
      response(status, headers) { erb(:advice, message: Advice.new.generate) }
    else
      content = erb(:not_found) # use to calc Content-Length dynamically
      # [
      #   "404",
      #   # {"Content-Type" => "text/html", "Content-Length" => "48"},
      #   # ["<html><body><h4>404 Not Found</h4></body></html>"]
      #   {"Content-Type" => "text/html", "Content-Length" => "#{content.size}"},
      #   [content]
      # ]
      status = '404'
      headers = {
        "Content-Type" => 'text/html',
        "Content-Length" => "#{content.size}"
      }
      response(status, headers) { content }
    end
  end
end
