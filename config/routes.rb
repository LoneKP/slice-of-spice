Rails.application.routes.draw do
  devise_for :users, controllers: { 
    registrations: "users/registrations", 
    #sessions: "users/sessions",
    #confirmations: "users/confirmations" ,
    #omniauth_callbacks: "users/omniauth_callbacks",
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  
    root "recipes#index"
    
    resources :recipes, only: [:index, :create, :update, :new]

    get "/my_recipes", to: "recipes#my_recipes" 

end
