require "sinatra"
require "json"
require "leveldb"

DB = LevelDB::DB.new("./db")

# CORS *
before do
  headers "Access-Control-Allow-Origin" => "*",
          "Access-Control-Allow-Methods" => "GET, OPTIONS",
          "Access-Control-Allow-Headers" => "Content-Type"
end

# Responder preflight (OPTIONS)
options "*" do
  200
end

get "/:key" do
  value = DB.get(params[:key])

  halt 404, { error: "no encontrado" }.to_json unless value

  content_type :json

  {
    key: params[:key],
    value: JSON.parse(value)
  }.to_json
end