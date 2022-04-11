require "tilt/erubis" # for ERB purposes
require "sinatra"
require "sinatra/reloader"

before do
  @contents = File.readlines("data/toc.txt")
end

helpers do
  # wrap each non-empty line of the supplied text in <p> ... </p> tags
  def in_paragraphs(text)
    # text.split("\n\n").map { |parag| "<p>#{parag}</p>" }.join
    text.split("\n\n").map.with_index { |parag, ndx| "<p id='parag#{ndx}'>#{parag}</p>" }.join
  end

  # highlight a search str w/i a blk of text by wrapping it in <strong> tags
  def highlight(search_str, text)
    text.gsub!(search_str, "<strong>#{search_str}</strong>")
  end
end

get "/" do
  # File.read "public/template.html"
  @title = "The Psychotic Adventures of Sherlock Holmes"
  # @contents = File.read("data/toc.txt").split("\n") # not quite; want newline-terminated elems
  # @contents = File.readlines("data/toc.txt") # moved to the `before filter`

  erb :home # home.erb; replaces template.html
end

# This just echos the `name` param to the main content area
get "/show/:name" do
  @name = params[:name]

  erb :name
end

# get "/chapters/1" do
#   @title = "Chapter 1"
#   @contents = File.readlines("data/toc.txt")
#   @chapter = File.read("data/chp1.txt")
get "/chapters/:number" do
  num = params[:number].to_i
  redirect '/' unless (1..@contents.size).include?(num) # non-existent chapter
  @title = "Chapter #{num}: #{@contents[num - 1]}"
  @chapter = File.read("data/chp#{num}.txt")

  erb :chapter
end

# Add some code to the new route that checks if any of the chapters contain
# whatever text is entered into the search form. Render a list of links to
# the matching chapters in the template.
get "/search" do
  if params[:query]
    @matching_chapters = []
    (1..@contents.size).each do |num|
      title = @contents[num - 1]
      chapter = File.read("data/chp#{num}.txt")
      parags = chapter.split("\n\n").select do |parag|
        parag.include?(params[:query])
      end
      unless parags.empty?
        @matching_chapters << {num: num, title: title, parags: parags}
      end
    end
  end

  erb :search
end

not_found do
  # "Page Not found"
  redirect '/'
end
