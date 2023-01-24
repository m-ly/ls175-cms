ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../cms"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "history.txt"
  end

  def test_history_text_view
    get "/history.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "Lorem ipsum dolor"
  end 

  def test_about_text_view
    get "/about.md"
    assert_equal 200, last_response.status
    assert_equal "text/markdown", last_response["Content-Type"]
    assert_includes last_response.body, "Hac volui posita Minervae"
  end 

  def test_non_existent_path
    get "/bad-path.txt"
    assert_equal 302, last_response.status

    get last_response["location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, "bad-path.txt does not exist."

    get "/"
    refute_includes last_response.body, "bad-path.txt does not exist."
  end
end