Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get '/register_player', to: 'player#register_player'
      get '/get_player_game_state', to: 'player#get_player_game_state'
    end
  end
end
