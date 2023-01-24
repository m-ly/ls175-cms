require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "securerandom"
require "redcarpet"

root = File.expand_path("..", __FILE__)

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

before do 
  @files = Dir.glob(root + "/data/*").map do |path|
    File.basename(path)
  end
end 




# Display an index with each filename
get "/" do
  @session = session.inspect
  erb :layout
end


get "/:filename" do 
  file_path = root + "/data/" + params['filename']
  
  if File.exist?(file_path)
    headers["Content-Type"] = "text/plain"
    File.read(file_path)
  else
    session[:not_found_msg] = "#{params[:filename]} does not exist."
    redirect "/"
  end 
end
