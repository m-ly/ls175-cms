require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "securerandom"
require "redcarpet"
require "yaml"

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
    erb render_markdown(content)
  end
end

def logged_in?
  session[:username]
end

def require_signed_in_user
  unless logged_in?
    session[:message] = "You must be signed in to do that."
    redirect "/"
  end
end

# Retrieving user data
def users

end 





get "/" do
  @files = Dir.glob(data_path + "/*").map do |path|
    File.basename(path)
  end

  erb :index
end

get "/new" do
  require_signed_in_user
  erb :new
end 

post "/create" do
  require_signed_in_user

  filename = params[:filename].to_s

  if filename.size == 0 
    session[:message] = "File name must be at least one character."
    status 422
    erb :new
  else
    file_path = File.join(data_path, filename)

    File.write(file_path, "")

    session[:message] = "#{filename} has been created."
    redirect "/"
  end 
end

# Signin forms
get "/users/signin" do
  erb :signin
end 

post "/users/signin" do 
  if params[:username] == 'admin' && params[:password] =='secret'
    session[:username] = params[:username]
    session[:message] = "Welcome!"
    redirect "/"
  else 
    session[:message] = "Invalid Credentials"
    redirect '/users/signin'
  end 
end 

post "/users/signout" do 
  session.delete(:username)
  session[:message] = "You have been signed out."
  redirect "/"
end 

# Delete a file
post "/:filename/delete" do
  require_signed_in_user
  
  filename = params[:filename].to_s
  file_path = File.join(data_path, filename)

  File.delete(file_path)

  session[:message] = "#{filename} has been deleted."
  redirect "/"
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
  require_signed_in_user

  file_path = File.join(data_path, params[:filename])
  
  @filename = params[:filename]
  @content = File.read(file_path)
  
  erb :edit
end 

# Submit form to edit a document
post "/:filename" do
  require_signed_in_user

  file_path = File.join(data_path, params[:filename])

  File.write(file_path, params[:content])

  session[:message] = "#{params[:filename]} has been updated."
  redirect "/"
end




