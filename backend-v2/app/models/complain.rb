# app/models/complain.rb
class Complain < ApplicationRecord
  belongs_to :car

  validates :description, presence: true
  validates :created, presence: true
end