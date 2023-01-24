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

    get last_response["Location"]
    

    assert_equal 200, last_response.status
    
    last_response.body
    assert_equal "bad-path.doc does not exist.", session[:message]
    assert_includes last_response.body, "bad-path.doc does not exist."

  end

  def test_editing_document
    create_document "about.md"
    create_document "changes.txt"

    get "/changes.txt/edit"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_edit
    # get initial text data
    create_document "changes.txt"
    post "/changes.txt", content: "new content"
    assert_equal 302, last_response.status
    
    get last_response["location"]
    assert_equal "changes.txt has been updated", session[:message]
    assert_includes last_response.body, "changes.txt has been updated"
    
    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end
end