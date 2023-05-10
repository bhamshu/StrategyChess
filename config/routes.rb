Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get '/register_player', to: 'player#register_player'
    end
  end
end
