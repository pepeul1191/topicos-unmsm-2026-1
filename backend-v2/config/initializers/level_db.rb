# config/initializers/level_db.rb
require "leveldb"

OLAP_PATH = Rails.root.join("db", "olap")

OLAP_DB = LevelDB::DB.new(OLAP_PATH.to_s)