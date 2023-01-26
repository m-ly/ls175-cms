ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"
require "pry"

require_relative "../cms"

class AppTest < Minitest::Test
  include Rack::Test::Methods


  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def session 
    last_request.env["rack.session"]
  end 

  def admin_session
    { "rack.session" => { username: "admin" } }
  end

  def test_index
    create_document "about.md"
    create_document "changes.txt"

    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
  end

  def test_text_document
    create_document("changes.txt", "hello")
    
    get "/changes.txt"

    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "hello"

  end

  def test_view_md_docuement
    create_document("about.md", "Hello World")

    get "/about.md"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Hello World"
  end

  def test_non_existent_path
    get "/bad-path.doc"
    assert_equal 302, last_response.status
    assert_equal "bad-path.doc does not exist.", session[:message]
  end

  def test_editing_document
    create_document "changes.txt"

    get "/changes.txt/edit", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_edit
    # get initial text data
    create_document "changes.txt"
    post "/changes.txt", {content: "new content"}, admin_session
    assert_equal 302, last_response.status
    
    assert_equal "changes.txt has been updated.", session[:message]
   
    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end

  def test_new_document_form
    get "/new", {}, admin_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Add a new document:"
  end 

  def test_new_document_creation
    post "/create", {filename: "a_new_file"}, admin_session
    assert_equal 302, last_response.status

    get last_response["location"]
    assert_includes last_response.body, "a_new_file"
  end

  def test_new_document_error
    post "/create", {filename: nil}, admin_session
    assert_equal 422, last_response.status 
    assert_includes last_response.body, "File name must be at least one character"
  end

  def test_delete_document
    create_document("a_new_file")
    
    post "a_new_file/delete", {}, admin_session
    assert_equal 302, last_response.status
    assert_equal "a_new_file has been deleted.", session[:message]

    get '/'
    refute_includes "a_new_file", last_response.body
  end 

  def test_sign_in_page
    # texst that page renders correctly
    get "/users/signin"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_successful_sign_in
    post "/users/signin", username: 'admin', password:'secret'
    assert_equal 302, last_response.status
    assert_equal "Welcome!", session[:message]
    assert_equal "admin", session[:username]

    get last_response['location']
  end
  
  def test_sign_in_with_bad_credentials
    post "/users/signin", username: 'bob', password:'1234'
    assert_equal 302, last_response.status
    assert_equal "Invalid Credentials", session[:message]
  end

  def test_sign_out
    test_successful_sign_in

    post "/users/signout"
    assert_equal 302, last_response.status
  
    assert_equal "You have been signed out.", session[:message]
    
    get "/"
    assert_nil session[:username]
    assert_includes last_response.body, "Sign In"
  end

  def test_must_be_signed_in_to_edit
    create_document("changes.txt")

    post "/changes.txt", {content: "new content"}
    assert_equal 302, last_response.status

    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_must_be_signed_in_to_delete
    create_document("changes.txt")

    post "/changes.txt/delete"
    assert_equal 302, last_response.status

    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_must_be_signed_in_to_create
    create_document("changes.txt")

    post "/create", {content: "a_new_file"}
    assert_equal 302, last_response.status

    assert_equal "You must be signed in to do that.", session[:message]
  end
end
