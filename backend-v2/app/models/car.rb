# app/models/car.rb
class Car < ApplicationRecord
  validates :owner, presence: true, length: { maximum: 40 }
  validates :branch, presence: true, length: { maximum: 30 }
  validates :model, presence: true, length: { maximum: 30 }
  validates :color, presence: true, length: { maximum: 12 }

  validates :frabricated,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than: 1900,
              less_than_or_equal_to: Date.current.year + 1
            }

  validates :plate,
            presence: true,
            length: { maximum: 7 },
            uniqueness: true

  has_many :technical_reviews, dependent: :destroy
  has_many :infractions, dependent: :destroy
  has_many :complains, dependent: :destroy
end