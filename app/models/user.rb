class User < ApplicationRecord
  has_many :user_recipes
  has_many :recipes, through: :user_recipes
  has_one :meal_plan, dependent: :destroy
  has_many :planned_user_recipes, through: :meal_plan, source:  :user_recipe
  has_many :planned_recipes, through: :planned_user_recipes, source:  :recipe

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end