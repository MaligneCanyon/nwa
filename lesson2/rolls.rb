# server prog to sim dice rolling

# socket is a R. lib w/ classes used to create and interact w/ servers and
# perform other networking tasks
require "socket"

# parse the URL str
# params can be entered in any order
def parse(str)
  http_method, path_and_params, misc = str.split(' ')
  if path_and_params
    path, param_str = path_and_params.split("?")
    if param_str
      param_pairs = param_str.split("&")
      params = {}
      param_pairs.each do |param_pair|
      # params =  param_pairs.each_with_object({}) do |param_pair, params|
        key, value = param_pair.split("=")
        params[key] = value
      end
    end
  end
  [http_method, path, params]
end


# create a TCP server on localhost (i.e. the server accepts reqs that go to
# the localhost);
# use port 3003 (as the connection to the server)
server = TCPServer.new("localhost", 3003)

loop do
  # wait for someone to req something from the server;
  # when a req comes in, accept that call and open a connection to the client;
  # rtn a client obj that we can use to interact w/ that remote system
  client = server.accept

  # get the 1st line of the req (ex. "GET /")
  request_line = client.gets

  # ignore seemingly empty requests or browser requests for 'favicon'
  next if !request_line || request_line =~ /favicon/

  # print the req line to the console
  puts request_line

  # parse the req
  http_method, path, params = parse(request_line)

  ###Chrome###
    # add a status line b4 the msg body content
    # client.puts "HTTP/1.1 200 OK\r\n\r\n"

    # add a status line and a response header b4 the msg body content
    # client.puts "HTTP/1.1 200 OK"
    # client.puts "Content-Type: text/plain\r\n\r\n"
  ############

  # send the resp code
  client.puts "HTTP/1.1 200 OK"

  # in the browser, we want to display what the server sends back as HTML, so
  # need to add the following resp header
  client.puts "Content-Type: text/html"

  # need a blank line before the resp msg body
  client.puts

  client.puts "<html>"
  client.puts "<body>"

  # send the req line back to the client so that it appears in the web browser;
  # this is the response msg body
  # ex. "GET /?rolls=2&sides=6 HTTP/1.1"
  client.puts request_line

  # output some debug info
  client.puts "<pre>" # display as-is, preserving whitespace
  client.puts http_method# == "GET"
  client.puts path# == "/"
  client.puts params# == { "rolls" => "2", "sides" => "6" }
  client.puts "</pre>"

  if params
    client.puts "<h3>Rolls:</h3>"

    # gen and output a random num indicating the result of rolling a die
    # client.puts rand(1..6)
    # we want to spec the num of dice to roll, and how many sides the dice have
    rolls = params["rolls"].to_i
    sides = params["sides"].to_i
    sides = 6 if sides.zero? # default to 6-sided dice if `sides` is not spec'd
    rolls.times { client.puts "<p>", rand(1..sides), "</p>" }
  end

  client.puts "</body>"
  client.puts "</html>"

  # then close the connection
  client.close
end
