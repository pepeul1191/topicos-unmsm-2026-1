require "sinatra"
require "json"
require "leveldb"

DB = LevelDB::DB.new("./db")

get "/:key" do
  value = DB.get(params[:key])

  halt 404, { error: "no encontrado" }.to_json unless value

  content_type :json

  {
    key: params[:key],
    value: value
  }.to_json
end