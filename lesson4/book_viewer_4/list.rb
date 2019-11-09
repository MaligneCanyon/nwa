# list.rb (Code Challenge: Dynamic Directory Index for "Working w/ Sinatra")

require "tilt/erubis" # for ERB purposes
require "sinatra"
require "sinatra/reloader"

get "/" do
  @title = "The Psychotic Adventures of Sherlock Holmes"
  @contents = File.readlines("data/toc.txt")

  # gen a list of files in the `public` dir
  dir = "./public/"
  @public_files = Dir.entries(dir).reject { |elem| File.directory?(dir + elem) }.sort
  @public_files.reverse! if params[:sort] == "desc"

  erb :list
end
