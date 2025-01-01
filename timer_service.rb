# timer_service.rb
require 'sinatra'
require 'sqlite3'
require 'json'
require 'fileutils'

configure do
  set :port, 9987
  set :bind, '0.0.0.0'
  set :show_exceptions, false
  enable :static
  set :public_folder, File.join(File.dirname(__FILE__), 'public')
end
def db
  FileUtils.mkdir_p '/app/data' unless Dir.exist?('/app/data')
  @db ||= SQLite3::Database.new "/app/data/timer_data.db"
end

def init_db
  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS timers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      time INTEGER NOT NULL CHECK (time > 0 AND time <= 86400),
      topic TEXT NOT NULL CHECK (length(topic) <= 255),
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
  SQL
end

init_db

get '/' do
  erb :index
end

get '/health' do
  content_type :json
  { status: 'ok', timestamp: Time.now }.to_json
end

get '/beaver_logo' do
  content_type 'image/svg+xml'
  File.read('public/beaver-logo.svg')
end

get '/timer' do
  begin
    time = params['time']&.to_i
    topic = params['topic']&.to_s

    if time.nil? || topic.nil?
      status 400
      return { error: "Missing parameters" }.to_json
    end

    if time <= 0 || time > 86400
      status 400
      return { error: "Invalid time" }.to_json
    end

    if topic.empty? || topic.length > 255
      status 400
      return { error: "Invalid topic" }.to_json
    end

    db.execute(
      "INSERT INTO timers (time, topic) VALUES (?, ?)",
      [time, topic]
    )

    content_type :html
    erb :response, locals: { time: time, topic: topic }

  rescue SQLite3::Exception => e
    status 500
    { error: "Database error: #{e.message}" }.to_json
  end
end

helpers do
  def format_duration(seconds)
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    seconds = seconds % 60

    if hours > 0
      sprintf("%02d:%02d:%02d", hours, minutes, seconds)
    else
      sprintf("%02d:%02d", minutes, seconds)
    end
  end
end

get '/view' do
  results = db.execute(
    "SELECT id, time, topic, created_at FROM timers ORDER BY created_at DESC"
  )

  timers = results.map do |row|
    {
      id: row[0],
      time: row[1],
      topic: row[2],
      created_at: row[3]
    }
  end

  erb :timers, locals: { timers: timers }
end

post '/clear' do
  db.execute("DELETE FROM timers")
  redirect '/view'
end

# Add to timer_service.rb
get '/instructions' do
  erb :instructions
end



get '/timers' do
  content_type :json
  begin
    results = db.execute(
      "SELECT id, time, topic, created_at FROM timers ORDER BY created_at DESC LIMIT 100"
    )

    timers = results.map do |row|
      {
        id: row[0],
        time: row[1],
        topic: row[2],
        created_at: row[3]
      }
    end

    { timers: timers }.to_json
  rescue SQLite3::Exception => e
    status 500
    { error: "Database error: #{e.message}" }.to_json
  end

  get '/favicon.ico' do
    content_type 'image/x-icon'
    send_file File.join(settings.public_folder, 'favicon.ico')
  end

end