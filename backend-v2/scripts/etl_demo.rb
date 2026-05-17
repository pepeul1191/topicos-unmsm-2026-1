# scripts/etl_demo.rb

require_relative '../config/environment'

cars = Car.includes(:technical_reviews, :infractions, :complains)

cars = cars.as_json(
  include: [
    :technical_reviews,
    :infractions,
    :complains
  ]
)

cars.each do |car|
  puts '1 ++++++++++++++++++++++++++++++'
  plate = car["plate"]
  tmp = {
    plate => {
      "car" => {
        "id"=> car["id"], 
        "owner"=> car["owner"], 
        "branch"=> car["branch"], 
        "model"=> car["model"], 
        "color"=> car["color"], 
        "frabricated"=> car["frabricated"], 
        "plate"=> car["plate"]
      }, 
      "technical_reviews"=> car["technical_reviews"], 
      "infractions"=> car["infractions"], 
      "complains"=> car["complains"]
    } 
  }
  puts tmp
end
