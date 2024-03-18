class Recipe < ApplicationRecord
  include OrderableByTimestamp

  belongs_to :recipe_source
  belongs_to :user
  enum :status, { want_to_cook: 0, cooked: 1 }

  validates :recipe_source, 
    uniqueness: { scope: :user_id, message: "You already added this recipe!"}


end
