# app/models/etl_execution.rb
class EtlExecution < ApplicationRecord
  self.table_name = "etl_executions"

  validates :description, presence: true
  validates :created, presence: true
  validates :succeded, inclusion: { in: [true, false] }

  scope :successful, -> { where(succeded: true) }
  scope :failed, -> { where(succeded: false) }
  scope :recent, -> { order(created: :desc) }
end