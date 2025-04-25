class DirectionSection < ApplicationRecord
  belongs_to :recipe
  has_many   :direction_steps, -> { order(:position) }, dependent: :destroy
end
