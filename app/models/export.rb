class Export < ApplicationRecord
  belongs_to :user
  has_one_attached :file
  validates :status, presence: true

  enum status: { pendiente: 0, listo: 1, fallo: 2 }
end