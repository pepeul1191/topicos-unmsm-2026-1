# app/models/infraction.rb
class Infraction < ApplicationRecord
  belongs_to :car

  validates :description, presence: true
  validates :created, presence: true
end