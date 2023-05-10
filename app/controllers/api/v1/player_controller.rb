INIT_STATE_STR={
    "stage": "Strategise",
    "main_board": [
        "None", "None", "None", "None", "None", "None", "None", "None",
        "None", "None", "None", "None", "None", "None", "None", "None",
        "None", "None", "None", "None", "None", "None", "None", "None",
        "None", "None", "None", "None", "None", "None", "None", "None",
    ],
    "side_drawers": [
        "King", "Queen",     "Rook",   "Rook", 
        "Bishop", "Bishop",  "Knight", "Knight",
        "Pawn", "Pawn",      "Pawn",   "Pawn", 
        "Pawn", "Pawn",      "Pawn",   "Pawn",
    ],
}.to_json


class Api::V1::PlayerController < ApplicationController
    def register_player
        uniq_pub_name = params[:uniq_pub_name]
        unless uniq_pub_name
            render json: { error: 'Missing param uniq_pub_name' }, status: 400
            return
        end

        game = Game.new(state: INIT_STATE_STR)
        # Saving here so that there's as little gap between the (ideally)
        # atomic operations of checking player unique pub name and saving it 
        game.save

        # TODO: this should be atomic - checking for name and then registering
        unless Player.where(uniq_pub_name: uniq_pub_name).empty?
            render json: { error: 'Player name already taken. Choose another.' }, status: 406
            return
        end

        player = Player.new(uniq_pub_name: uniq_pub_name, games_id: game.id)

        unless player.save
            # This shouldn't happen - only case it could happen is simultaneously two
            # players choosing a name which is unlikely (see above TODO)
            render json: { error: 'Some error occured' }, status: 500
            return
        end

        render json: {uniq_pub_name: uniq_pub_name, id: player.id, state: JSON.parse(INIT_STATE_STR)}
    end

    def get_player_game_state
        id = params[:id]
        player = Player.find_by(id: id)
        game = Game.find_by(id: player.games_id)
        render json: {uniq_pub_name: player.uniq_pub_name, id: player.id, state: JSON.parse(game.state)}
    end

    def player_is_ready
        # Player sends their board state to the server and requests to be marked ready
        id = params[:id]
        chosen_main_board = params[:main_board]
        side_drawers = params[:side_drawers] # verify this is empty
        
        player = Player.find_by(id: id)
        game = Game.find_by(id: player.games_id)
        json_state = JSON.parse(game.state)

        unless json_state["stage"] == "Strategise"
            render json: { error: 'Dont call this method, player state is ' + json_state["stage"] }, status: 400
        end

        unless side_drawers.to_set == Set["None"]
            render json: { error: 'Player not ready yet' }, status: 400
        end

        json_state["main_board"] = chosen_main_board
        json_state["side_drawers"] = side_drawers
        json_state["stage"] = "ready"
        game.state = json_state.to_json
        game.save

        # TODO: add this player to the list of ready players and broadcast to all 
        # players who are in Strategise or PartnerSelection.

        render json: {uniq_pub_name: player.uniq_pub_name, id: player.id, state: JSON.parse(game.state)}
    end

    def send_request_to_player
        my_id = params[:id]
        partner_pub_name = params[:partner_pub_name]
        # Check if partner is ready
        # Broadcast request to partner
    end

    def accept_request_and_start_game
        my_id = params[:id]
        partner_pub_name = params[:partner_pub_name]
        # Check if partner sent a request to start the game
        # Check if partner is in PartnerSelection (not Strategise, GamePlay etc)
        # TODO: maybe use joins to get game in single query. In all methods.
        partner = Player.find_by(uniq_pub_name: partner_pub_name)
        partner_game = Game.find_by(id: partner.games_id)
        partner_game_state = JSON.parse(partner_game.state) 
        partner_game_state["stage"] = "GamePlay"
        my_game = Game.find_by(: partner_pub_name)
        my_game_state = JSON.parse(my_game.state)
        partner_game_state["main_board"] += my_game_state["main_board"] 
        partner_game.state = partner_game_state.to_json
        partner_game.turn = my_id
        me = Player.find_by(id: my_id)
        my_old_game_id = me.games_id
        me.games_id = partner_game.id 

        # TODO: These should be atomic.
        partner.save
        me.save
        partner_game.save
        Game.destroy(my_old_game_id)

        # TODO broadcast this good news to the partner

        render json: {uniq_pub_name: player.uniq_pub_name, partner_pub_name: partner.uniq_pub_name, state: JSON.parse(partner_game_state), turn: partner_game.turn}
    end

    def make_a_move
        my_id = params[:id]
        init_index = params[:init_index]
        final_index = params[:final_index]
        # Check if it is indeed my turn
        # Check if the move is valid
        # Update game state
        # Check if game over. 
        # Broadcast to the partner
    end

    def register_new_game_for_player
        # Large parts of this will be from register_player
        # Check if the player's game is GameOver
        my_id = params[:id]
    end
end
