# server prog to incr/decr a counter
# - display a num on the screen
# - incr the num using one link; decr it using another

require "socket"

def parse_request(request_line)
  http_method, path_and_params, http = request_line.split(" ")
  path, params = path_and_params.split("?")
  # account for case where no params are passed in thru the URL
  # (should produce an empty params hsh)
  # if params
    # params = params.split("&").each_with_object({}) do |pair, hash|
    params = (params || "").split("&").each_with_object({}) do |pair, hash|
      key, value = pair.split("=")
      hash[key] = value
    end
  # end
  [http_method, path, params]
end

server = TCPServer.new("localhost", 3003)
loop do
  client = server.accept

  request_line = client.gets
  puts request_line

  next if !request_line || request_line =~ /favicon/

  http_method, path, params = parse_request(request_line)

  client.puts "HTTP/1.1 200 OK"
  client.puts "Content-Type: text/html"
  client.puts
  client.puts "<html>"
  client.puts "<body>"
  client.puts "<pre>"
  client.puts http_method# == "GET"
  client.puts path# == "/"
  client.puts params# == { "number" => "4" }
  client.puts "</pre>"

  # the current num is passed as a URL param;
  # since calling to_i on nil rtns 0, code will not fail if no 'number' param
  # is spec'd
  number = params["number"].to_i

  # display the current num
  client.puts "<h3>Counter:</h3>"
  client.puts "<p>The current number is #{number}.</p>"

  # display links to incr/decr the counter;
  # ex. client.puts "<a href='http://localhost:3003/?number=#{number + 1}'>Add one</a>";
  # we don't need to spec the scheme, host, port or path again
  client.puts "<a href='?number=#{number + 1}'>Plus one</a>"
  client.puts "<a href='?number=#{number - 1}'>Minus one</a>"

  client.puts "</body>"
  client.puts "</html>"

  client.close
end
