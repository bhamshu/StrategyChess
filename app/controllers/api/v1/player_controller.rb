require File.join(__dir__, "./utils")

class Api::V1::PlayerController < ApplicationController
    def register_player
        uniq_pub_name = params[:uniq_pub_name]
        unless uniq_pub_name
            render json: { error: 'Missing param uniq_pub_name' }, status: 400
            return
        end

        game = Game.new(state: Constants::INIT_STATE_STR)
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

        render json: {uniq_pub_name: uniq_pub_name, id: player.id, state: Constants::INIT_STATE}
    end

    # TODO: Validate the integrity of main_board here and after every round.
    def mark_player_ready
        # Player sends their board state to the server and requests to be marked ready
        id = params[:id]
        chosen_main_board = params[:main_board]
        side_drawers = params[:side_drawers] # verify this is empty
        
        player = Player.find_by(id: id)
        game = Game.find_by(id: player.games_id)
        hash_state = JSON.parse(game.state)

        unless hash_state["stage"] == Constants::Strategise
            render json: { error: 'Dont call this method, player state is ' + hash_state["stage"] }, status: 403
            return
        end

        unless side_drawers.to_set == Set["None"]
            render json: { error: 'Player not ready yet' }, status: 403
            return
        end

        hash_state["main_board"] = chosen_main_board
        hash_state["side_drawers"] = ["None"]*16
        hash_state["stage"] = Constants::PartnerSelection
        game.state = hash_state.to_json
        game.save

        Utils.send_pusher_msg_to_player("singles", "new_player_on_mkt", player.uniq_pub_name)

        render json: {uniq_pub_name: player.uniq_pub_name, id: player.id, state: JSON.parse(game.state)}
    end

    def send_request_to_player
        my_id = params[:id]
        partner_pub_name = params[:partner_pub_name]
        partner = Player.find_by(uniq_pub_name: partner_pub_name)
        partner_stage = JSON.parse(Game.find_by(id: partner.games_id).state)["stage"]
        # TODO: make atomic

        unless partner_stage == Constants::PartnerSelection
            render json: { error: 'Partner stage incompatible: ' + partner_stage }, status: 404
            return
        end

        unless ActiveRequest.where(:from_id=> partner.id, :to_id=> my_id).empty?
            # the other player has also sent a request to me
            # TODO: redirect to accept_request_and_start_game
        end
        ActiveRequest.new(from_id: my_id, to_id: partner.id).save
        my_pub_name = Player.find_by(id: my_id).uniq_pub_name
        Utils.send_pusher_msg_to_player(partner.id, "challenge_request", my_pub_name)
        render json: {status: "success"}, status: 200
    end

    def accept_request_and_start_game
        my_id = params[:id]
        partner_pub_name = params[:partner_pub_name]
        partner = Player.find_by(uniq_pub_name: partner_pub_name)
        if not partner
            render json: {error: "No player found with this name."}, status: 404
        end
        if ActiveRequest.where(from_id: partner.id, to_id: my_id).empty?
            # the other player hasn't sent a request, how can you accept
            render json: {error: "Player has not sent a request. Can't accept. Send them a request if you want to play with them."}, status: 403
            return
        end
        # TODO: maybe use joins to get game in single query. In all methods.
        partner_game = Game.find_by(id: partner.games_id)
        partner_game_state = JSON.parse(partner_game.state) 
        unless partner_game_state["stage"] == Constants::PartnerSelection
            # the other player hasn't sent a request, how can you accept
            render json: {error: "Too late, they've paired up with someone else."}, status: 404
            return
        end
        partner_game_state["stage"] = Constants::GamePlay
        me = Player.find_by(id: my_id)
        my_game = Game.find_by(id: me.games_id)
        my_game_state = JSON.parse(my_game.state)
        # This check is down here because it's frivolous - frontend won't
        # make this request. It's just an extra check for malicious use
        # Above we have checks which are way more likely to occur

        unless my_game_state["stage"] == Constants::PartnerSelection
            # the other player hasn't sent a request, how can you accept
            render json: {error: "Go strategise, or play with your partner depending on your stage which is " + my_game_state["stage"]}, status: 403
            return
        end
        
        # Now we will delete my game and switch over to partner's game
        partner_game_state["main_board"] += my_game_state["main_board"].reverse 
        # TODO: assert that side drawers are null at this point
        partner_game.state = partner_game_state.to_json
        partner_game.turn = partner.id
        my_old_game_id = me.games_id
        me.games_id = partner_game.id 

        # TODO: These should be atomic.
        ActiveRequest.where(:from_id => [my_id, partner.id], :to_id => [my_id, partner.id]).destroy_all
        partner.save
        me.save
        partner_game.save
        Game.destroy(my_old_game_id)

        Utils.send_pusher_msg_to_player(partner.id, "challenge_accepted", me.uniq_pub_name)

        turn_str = Utils.get_turn_str(me.id, partner_game.turn)

        render json: {uniq_pub_name: me.uniq_pub_name, partner_pub_name: partner.uniq_pub_name, state: partner_game_state, turn: turn_str}
    end

    def get_my_game_state
        # Player will call this after their partner accepts request/ makes a move 
        id = params[:id]
        me = Player.find_by(id: id)
        game = Game.find_by(id: me.games_id)
        if game.turn == me.id
            render json: {state: JSON.parse(game.state)}
        else
            state = JSON.parse(game.state, symbolize_names: false)
            p state
            state["main_board"] = state["main_board"].reverse
            state["side_drawers"] = state["side_drawers"].reverse
            render json: {state: state}
        end
    end

    def make_a_move
        my_id = params[:id]
        init_index = params[:init_index].to_i
        final_index = params[:final_index].to_i

        me = Player.find_by(id: my_id)
        game = Game.find_by(id: me.games_id)

        unless game.turn == me.id
            render json: { error: 'Not my turn' }, status: 403
            return 
        end

        if init_index<0 or init_index>63 or final_index<0 or final_index>63
            render json: { error: 'Invalid move' }, status: 403
            return 
        end

        # TODO: Check if the move is valid
        # TODO: allow people to invent pieces by writing custom validation functions
        
        # Reverse the board
        hash_state = JSON.parse(game.state)

        unless hash_state["stage"] == Constants::GamePlay
            render json: { error: "Game not in play, can't move" }, status: 403
            return 
        end

        final_index_piece = hash_state["main_board"][final_index]
        hash_state["main_board"][final_index] =  hash_state["main_board"][init_index]
        hash_state["main_board"][init_index] = "None"

        unless final_index_piece == "None"
            first_none_idx = hash_state["side_drawers"].find_index("None")
            hash_state["side_drawers"][first_none_idx] = final_index_piece
        end

        hash_state["main_board"] = hash_state["main_board"].reverse
        hash_state["side_drawers"] = hash_state["side_drawers"].reverse

        game_over = false
        if final_index_piece == "King"
            game_over = true
            hash_state["stage"] = Constants::GameOver
            hash_state["winner_uniq_pub_name"] = me.uniq_pub_name
        end

        game.state = hash_state.to_json

        partner = Player.where.not(id: me.id).find_by(games_id: game.id)

        game.turn = partner.id
        game.save

        # Partner may be able to calculate new board state on frontend 
        # but they should fetch it using get_my_game_state, The info in 
        # pusher is just for animation.
        Utils.send_pusher_msg_to_player(partner.id, "opponent_moved", {"init_index": init_index, "final_index": final_index, "game_over": game_over})

        render json: {main_board: hash_state["main_board"].reverse, side_drawers: hash_state["side_drawers"].reverse, "game_over": game_over}, status: 200
    end

    def register_new_game_for_player
        # Large parts of this will be from register_player
        # Check if the player's game is GameOver
        # TODO: implement
        my_id = params[:id]
    end
end
