# echo server

# socket is a R. lib w/ classes used to create and interact w/ servers and
# perform other networking tasks
require "socket"

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

  ###Chrome###
    # add a status line b4 the msg body content
    client.puts "HTTP/1.1 200 OK\r\n\r\n" # superfulous, given the next line below ?

    # add a status line and a response header b4 the msg body content
    client.puts "HTTP/1.1 200 OK"
    client.puts "Content-Type: text/plain\r\n\r\n"
  ############

  # send the req line back to the client so that it appears in the web browser;
  # this is the response msg body
  client.puts request_line

  # then close the connection
  client.close
end
