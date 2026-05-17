# app/models/technical_review.rb
class TechnicalReview < ApplicationRecord
  belongs_to :car

  validates :description, presence: true
  validates :created, presence: true
end