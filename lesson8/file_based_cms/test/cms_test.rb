ENV["RACK_ENV"] = "test"

require "rack/test"
require "fileutils"
require "minitest/autorun"
require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  # setup and teardown data structures for each test
  # the data_path method is located in cms.rb
  def setup
    FileUtils.mkdir_p(data_path)
  end
  def teardown
    FileUtils.rm_rf(data_path)
  end

  # def create_document # moved to cms.rb

  def session
    last_request.env["rack.session"]
  end

  def admin_session
    { "rack.session" => { username: "admin" } }
  end

  def test_index_signed_out
    # skip
    # setup necessary data
    create_document("about.md")
    create_document("changes.txt")
    # execute the code being tested
    get "/"
    # assert results of execution
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Sign In"
    # refute_includes last_response.body, "about.md"
    # refute_includes last_response.body, "changes.txt"
  end

  def test_markdown_file
    # skip
    str = "this is about.md"
    create_document("about.md", str)
    get "/about.md"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    code = <<~'HEREDOC'
      <p>this is about.md</p>
    HEREDOC
    assert_includes last_response.body, code
    assert_includes last_response.body, str
  end

  def test_file_changes
    # skip
    str = "this is changes.txt"
    create_document("changes.txt", str)
    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, str
  end

  def test_file_history
    # skip
    str = <<~'HEREDOC'
      1993 - Yukihiro Matsumoto dreams up Ruby.
      1995 - Ruby 0.95 released.
      1996 - Ruby 1.0 released.
      1998 - Ruby 1.2 released.
      1999 - Ruby 1.4 released.
      2000 - Ruby 1.6 released.
      2003 - Ruby 1.8 released.
      2007 - Ruby 1.9 released.
      2013 - Ruby 2.0 released.
      2013 - Ruby 2.1 released.
      2014 - Ruby 2.2 released.
      2015 - Ruby 2.3 released.
    HEREDOC
    create_document("history.txt", str)
    get "/history.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, str
  end

  # def test_non_existant_file
  #   # skip
  #   # from the solution ...
  #   get "/notafile.ext" # Attempt to access a nonexistent file
  #   assert_equal 302, last_response.status # Assert that the user was redirected
  #   get last_response["Location"] # Request the page that the user was redirected to
  #   assert_equal 200, last_response.status
  #   assert_includes last_response.body, "notafile.ext does not exist"
  #   get "/" # Reload the page
  #   # Assert that our message has been removed
  #   refute_includes last_response.body, "notafile.ext does not exist"
  # end
  def test_non_existant_file
    # skip
    get "/notafile.ext" # Attempt to access a nonexistent file
    assert_equal 302, last_response.status # Assert that the user was redirected
    assert_includes session[:msg], "notafile.ext does not exist"
    get last_response["Location"] # Request the page that the user was redirected to
    get "/" # Reload the page
    refute_includes last_response.body, "notafile.ext does not exist"
  end

  # def test_editing_file
  #   # skip
  #   str = "this is changes.txt"
  #   create_document("changes.txt", str)
  #   get "/changes.txt/edit"
  #   assert_equal 200, last_response.status
  #   assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
  #   assert_includes last_response.body, str

  #   post "/changes.txt/edit", text: "my new content"
  #   assert_includes (300..399), last_response.status
  #   assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
  #   # there is no 'body' to chk w/ a redirect

  #   get last_response["Location"]
  #   assert_equal 200, last_response.status
  #   assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
  #   assert_includes last_response.body, "changes.txt has been updated"

  #   get "/changes.txt"
  #   assert_equal 200, last_response.status
  #   assert_equal "text/plain", last_response["Content-Type"]
  #   assert_includes last_response.body, "my new content"
  # end
  def test_editing_file
    # skip
    str = "this is changes.txt"
    create_document("changes.txt", str)

    get "/changes.txt/edit"
    assert_includes (300..399), last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes session[:msg], "You must be signed in to do that"

    get "/changes.txt/edit", {}, admin_session
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, str

    post "/changes.txt/edit", text: "my new content"
    assert_includes (300..399), last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    # there is no 'body' to chk w/ a redirect
    assert_includes session[:msg], "changes.txt has been updated"

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "my new content"
  end

  # def test_creating_file
  #   # skip
  #   get "/new"
  #   assert_equal 200, last_response.status
  #   assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
  #   assert_includes last_response.body, %q(<button type="submit">Create</button>)

  #   post "/new", filename: ""
  #   assert_equal 422, last_response.status
  #   assert_includes last_response.body, "A name is required"

  #   post "/new", filename: "cat.txt"
  #   assert_includes (300..399), last_response.status

  #   get last_response["Location"]
  #   assert_equal 200, last_response.status
  #   assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
  #   assert_includes last_response.body, "cat.txt was created"

  #   get "/"
  #   assert_includes last_response.body, "cat.txt"
  # end
  def test_creating_file
    # skip
    get "/new"
    assert_includes (300..399), last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes session[:msg], "You must be signed in to do that"

    get "/new", {}, admin_session
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, %q(<button type="submit">Create</button>)

    post "/new", filename: ""
    assert_equal 422, last_response.status
    assert_includes last_response.body, "A name is required"

    post "/new", filename: "cat.txt"
    assert_includes (300..399), last_response.status
    assert_includes session[:msg], "cat.txt was created"

    get "/"
    assert_includes last_response.body, "cat.txt"
  end

  # def test_deleting_file
  #   # skip
  #   create_document("dog.txt")
  #   post "/users/signin", username: "admin", pswd: "secret"

  #   get "/"
  #   assert_includes last_response.body, "dog.txt"

  #   post "/dog.txt/delete"
  #   assert_includes (300..399), last_response.status
  #   assert_equal "text/html;charset=utf-8", last_response["Content-Type"]

  #   get last_response["Location"]
  #   assert_equal 200, last_response.status
  #   assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
  #   assert_includes last_response.body, "dog.txt was deleted"

  #   get "/"
  #   refute_includes last_response.body, "dog.txt"
  # end
  def test_deleting_file
    # skip
    create_document("dog.txt")
    # post "/users/signin", username: "admin", pswd: "secret"

    get "/"
    assert_includes last_response.body, "dog.txt"

    post "/dog.txt/delete"
    assert_includes (300..399), last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes session[:msg], "You must be signed in to do that"

    post "/dog.txt/delete", {}, admin_session
    assert_includes (300..399), last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes session[:msg], "dog.txt was deleted"

    get "/" # load the index page
    get "/" # reload the index page
    refute_includes last_response.body, "dog.txt"
  end

  def test_signin_page
    # skip
    get "/users/signin"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Username"
    assert_includes last_response.body, "Password"
  end

  def test_bad_signin
    # skip
    post "/users/signin", username: "admin", pswd: "bad_pswd"
    assert_equal 422, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_nil session[:username]
    assert_includes last_response.body, "Invalid credentials"
  end

  # def test_good_signin
  #   # skip
  #   post "/users/signin", username: "admin", pswd: "secret"
  #   assert_includes (300..399), last_response.status
  #   assert_equal "text/html;charset=utf-8", last_response["Content-Type"]

  #   get last_response["Location"]
  #   assert_equal 200, last_response.status
  #   assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
  #   assert_includes last_response.body, "Welcome admin"
  #   assert_includes last_response.body, "Signed in as admin"
  # end
  def test_good_signin
    # skip
    post "/users/signin", username: "admin", pswd: "secret"
    assert_includes (300..399), last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes session[:msg], "Welcome admin"
    assert_equal "admin", session[:username]
  end

  def test_index_signed_in
    # skip
    # setup necessary data
    create_document("about.md")
    create_document("changes.txt")

    # execute the code being tested
    post "/users/signin", username: "admin", pswd: "secret"
    get last_response["Location"]

    # assert results of execution
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    # better to just test a small sample of the rtn'd text,
    # rather than try to match a large chunk of it
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "Signed in as admin"
  end

  # def test_signout
  #   # skip
  #   create_document("about.md")
  #   create_document("changes.txt")
  #   post "/users/signin", username: "admin", pswd: "secret"

  #   post "/users/signout"
  #   assert_includes (300..399), last_response.status
  #   assert_equal "text/html;charset=utf-8", last_response["Content-Type"]

  #   get last_response["Location"]
  #   assert_equal 200, last_response.status
  #   assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
  #   assert_includes last_response.body, "You have been signed out"
  #   refute_includes last_response.body, "about.md"
  #   refute_includes last_response.body, "changes.txt"
  #   assert_includes last_response.body, "Sign In"
  # end
  def test_signout
    # skip
    create_document("about.md")
    create_document("changes.txt")
    post "/users/signin", username: "admin", pswd: "secret"

    post "/users/signout"
    assert_includes (300..399), last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes session[:msg], "You have been signed out"

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    # refute_includes last_response.body, "about.md"
    # refute_includes last_response.body, "changes.txt"
    assert_nil session[:username]
    assert_includes last_response.body, "Sign In"
  end
end
