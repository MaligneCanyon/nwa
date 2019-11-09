require "find"
require 'yaml'

def file_path(filename)
  File.join(data_path, filename)
end

def data_path
  File.expand_path("..", __FILE__)
end

def data_files
  files = Find.find(data_path).reject { |path| File.directory?(path) }
  files.map { |path| File.basename(path) }
end

def valid_credentials?(username, pswd)
  # username == "admin" && pswd == "secret"
  users = { "admin" => "secret" } # default
  filename = "users.yaml"
  filepath = file_path(filename)
  if data_files.include?(filename) # read the hsh of permitted users from a yaml file
    users.merge!(YAML.load_file(filepath))
  else # create the yaml file
    File.write(filepath, users.to_yaml)
  end
  users.one? { |key, value| key == username && value == pswd } # look for a single exact match
end

p valid_credentials?("boy", "girl")
p valid_credentials?("admin", "girl")
p valid_credentials?("admin", "secret")
