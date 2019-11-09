require "tilt/erubis" # for ERB purposes
require 'sinatra'
require 'sinatra/reloader'
require 'yaml'


before do
  @title = "Users and Interests"
  @user_arr = YAML.load_file('./data/users.yaml') # read the user data from a yaml file
  @user_names = @user_arr.keys.map(&:to_s)
end

helpers do
  def list(arr)
    arr.join(', ')
  end

  def count_interests(arr)
    # total = 0
    # arr.each_value do |hsh|
    #   total += hsh[:interests].size
    # end
    # total
    arr.reduce(0) do |total, (name, hsh)|
      total + hsh[:interests].size
    end
  end
end

not_found do
  "User not found"
end

get '/' do
  redirect '/users'
end

get '/users' do
  @sub_title = "Users"
  erb :users
end

get '/users/:name' do
  name = params[:name]
  redirect '/' unless @user_names.include?(name) # avoid non-existent users
  @sub_title = name.capitalize
  @info = @user_arr[name.to_sym]
  @other_users = @user_names.reject { |user| user == name }
  erb :user
end
