module NumberOfUsers
  extend ActiveSupport::Concern

  included do
    scope :with_recipes, -> { joins(:recipes) }
  end
end