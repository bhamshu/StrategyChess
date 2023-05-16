Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # TODO: make the appropriate ones POST requests
      get '/register_player', to: 'player#register_player'
      get '/get_player_game_state', to: 'player#get_player_game_state'
      get '/mark_player_ready', to: 'player#mark_player_ready'
      get '/send_request_to_player', to: 'player#send_request_to_player'
      get '/accept_request_and_start_game', to: 'player#accept_request_and_start_game'
      get '/get_my_game_state', to: 'player#get_my_game_state'
      get '/make_a_move', to: 'player#make_a_move'
      get '/register_new_game_for_player', to: 'player#register_new_game_for_player'
      get '/resign', to: 'player#resign'
    end
  end
end
