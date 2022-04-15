require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"
require "find"
require "securerandom"
require "redcarpet"
require "yaml"
require "bcrypt"

configure do
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
  set :erb, :escape_html => true
end

helpers do
  # rtn an arr of filenames
  def data_files
    # look in the data_path; reject any dirs
    files = Find.find(data_path).reject { |path| File.directory?(path) }
    # rtn the file basenames (name plus ext)
    files.map { |path| File.basename(path) }
  end

  # a file is restricted if only certain users can view it
  # a restricted file cannot be deleted
  RESTRICTED_FILES = %w(users.yaml) # list restricted files here !
  def restricted_file?(filename)
    RESTRICTED_FILES.include?(filename)
  end

  # a file is displayable if the user is admin, or the file is unrestricted
  def displayable_file?(filename)
    session[:username] == "admin" || !restricted_file?(filename)
  end
end

# convert Markdown text to HTML
def render_md(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

# load the content of an existing file
def load_file_content(filename)
  # File.read calls file_path, which calls File.join, which calls data_path ...
  # data_path explicitly sets the dir from which we can view files ...
  content = File.read(file_path(filename))

  # danger !!!
  # File.read(path) on the other hand, does not spec a dir; this could lead to
  # problems where a carefully-crafted url could request the R. or YAML files
  # content = File.read(filename)

  # danger !!! don't rtn the content of any non-md file by default;
  # instead, whitelist the acceptable file types

  # if File.extname(filename) == ".md"
  #   # render_md(content) # render the Markdown file as HTML
  #   erb render_md(content) # render the Markdown file as HTML
  # else
  #   headers["Content-Type"] = "text/plain" # render the file as plain text
  #   content # rtn the file content
  # end

  case File.extname(filename)
  when ".md"
    # render_md(content) # render the Markdown file as HTML
    erb render_md(content) # render the Markdown file as HTML
  when ".txt"
    headers["Content-Type"] = "text/plain" # render the file as plain text
    content # rtn the file content
  end
  # we don't need to display the yaml file content except when editing the file
end

# create a file path
def file_path(filename)
  File.join(data_path, filename)
end

# rtn the path to the document storage location
def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

# create a new file
def create_document(filename, content = "") # content is optional
  File.open(file_path(filename), "w") do |file|
    file.write(content)
  end
end

# if a user is not signed-in, display a msg and redirect them back to the index page
def chk_logged_in
  unless session[:username]
    session[:msg] = "You must be signed in to do that."
    redirect "/"
  end
end

# determine whether a username:pswd combination is valid
def valid_credentials?(username, pswd)
  # use a hsh to hold username:pswd combos
  # username == "admin" && pswd == "secret" becomes
  # users = { "admin" => "secret" } # default
  users = get_users

  # chk that the username exists (to prevent matching a default hsh value)
  # should look for a single exact match between the usename and the hashed pswd
  # should log whether more than one pswd exists for a given user,
  #   or whether the username:pswd combo appears > 1x
  # users.key?(username) && users.one? { |key, value| key == username && value == pswd }
  # users.key?(username) && users.one? { |key, value| key == username && valid_pswd?(value, pswd) }
  users.key?(username) && valid_pswd?(users[username], pswd) # shortened for simplicity
end

# rtn a hsh of username:pswd combos
def get_users
  # users = { "admin" => "secret" } # default w/o encryption
  users = { "admin" => encrypt_pswd("secret") } # default
  filename = "users.yaml"
  filepath = file_path(filename)
  if data_files.include?(filename) # read the hsh of permitted users from a yaml file
    # merge the users from the yaml file with the default users
    # user pswds in the yaml file will supercede the default ones for existing default users
    users.merge!(YAML.load_file(filepath))
  else # create the yaml file
    File.write(filepath, users.to_yaml)
  end
  users
end

# encrypt a text password
def encrypt_pswd(text_pswd)
  BCrypt::Password.create(text_pswd).to_s
end

# compare an encrypted password to a user-supplied text password
def valid_pswd?(encrypted_pswd, text_pswd)
  # encrypted_pswd == text_pswd # w/o encryption
  BCrypt::Password.new(encrypted_pswd) == text_pswd
end

not_found do
  redirect "/"
end

# danger !!!
# this (and potentially any other similarly-named route) interferes w/
# the 'get "/:filename"' route and could lead to malicious access
# get "/view" do
#   file_path = File.join(data_path, params[:filename])
#   if File.exist?(file_path)
#     load_file_content(file_path)
#   else
#     session[:message] = "#{params[:filename]} does not exist."
#     redirect "/"
#   end
# end

get "/" do
  # "Getting started."
  # @test = "bbbb" # can display this in index.erb
  erb :index
end

# could use 'get "/new"' (before 'get "/:filename"'),
# or just call chk_logged_in and 'erb :new' in 'get "/:filename"' if filename == "new"
# get "/new" do
#   chk_logged_in
#   erb :new
# end

get "/:filename" do
  filename = params[:filename]
  if filename == "new"
    chk_logged_in
    erb :new
  elsif data_files.include?(filename)
    # for a non-admin user, the chk_logged_in() session[:msg] gives away the
    # fact that a yaml file does exist somewhere ...
    chk_logged_in if filename == "users.yaml"
    load_file_content(filename)
  else
    session[:msg] = "#{filename} does not exist."
    redirect "/"
  end
end

get "/:filename/edit" do
  chk_logged_in
  filename = params[:filename]
  if data_files.include?(filename)
    content = File.read(file_path(filename))
    @filename = filename
    @content = content
    erb :edit
  else
    session[:msg] = "#{filename} does not exist."
    redirect "/"
  end
end

post "/:filename/edit" do
  chk_logged_in
  filename = params[:filename]
  File.write(file_path(filename), params[:text])
  session[:msg] = "#{filename} has been updated."
  redirect "/"
end

post "/new" do
  chk_logged_in
  filename = params[:filename]
  if filename == ""
    session[:msg] = "A name is required."
    status 422 # set the status code
    erb :new # must call erb to set the status code (does not work using 'redirect "/new"')
  elsif data_files.include?(filename)
    session[:msg] = "#{filename} already exists."
    redirect "/new"
  else
    create_document(filename)
    session[:msg] = "#{filename} was created."
    redirect "/"
  end
end

# get "/:filename/delete" do # this works (with a simple delete button in index.erb),
# but safer to use post for a delete operation
post "/:filename/delete" do
  chk_logged_in
  filename = params[:filename]
  File.delete(file_path(filename)) # could error-chk this
  session[:msg] = "#{filename} was deleted."
  redirect "/"
end

get "/users/signin" do
  erb :signin
end

post "/users/signin" do
  username = params[:username]
  pswd = params[:pswd]
  if valid_credentials?(username, pswd)
    session[:username] = username
    session[:msg] = "Welcome #{username}!"
    # if we redirect here, we will loose the params values (ex. params[:username])
    # instead, we could just load index.erb directly;
    # however, the requirements specify a redirect
    # erb :index
    redirect "/"
  else
    session[:msg] = "Invalid credentials."
    status 422
    # if we redirect here, we will loose the params values (ex. params[:username])
    # instead, just load signin.erb directly
    # redirect "/users/signin"
    erb :signin
  end
end

post "/users/signout" do
  if session[:username]
    session[:username] = nil
    session[:msg] = "You have been signed out."
    redirect "/"
  end
end
