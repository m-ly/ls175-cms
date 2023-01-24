require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "securerandom"
require "redcarpet"

configure do 
  enable :sessions
  set "session_secret", SecureRandom.hex(32)
end 

def data_path
  if ENV["RACK_ENV"]== "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end
 
def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  if File.extname(path) == ".txt"
    headers["Content-Type"] = "text/plain"
    content
  elsif File.extname(path) == ".md"
    render_markdown(content)
  end
end


# Display an index with each filename
get "/" do
  @files = Dir.glob(data_path + "/*").map do |path|
    File.basename(path)
  end
  erb :index
end

# Retrieve a specific file from the system
get "/:filename" do 
  file_path = File.join(data_path, params[:filename])
  
  if File.exist?(file_path)
    
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end 
end


# Get the form to edit a document
get "/:filename/edit" do 
  file_path = File.join(data_path, params[:filename])
  
  @filename = params[:filename]
  @content = File.read(file_path)
  
  erb :edit
end 

# Submit form to edit a document
post "/:filename" do
  file_path = File.join(data_path, params[:filename])

  File.write(file_path, params[:content])

  session[:message] = "#{params[:filename]} has been updated."
  redirect "/"
end