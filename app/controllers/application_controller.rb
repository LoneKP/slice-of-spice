class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def after_sign_in_path_for(user)
    recipes_path
  end
end
