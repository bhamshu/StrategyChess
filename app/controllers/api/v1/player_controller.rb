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
        partner = Player.find_by(uniq_pub_name: player_pub_name)
        partner_stage = JSON.parse(Game.find_by(id: partner.games_id).state)["stage"]
        # TODO: make atomic
        unless stage == Constants::PartnerSelection
            render json: { error: 'Partner stage incompatible: ' + partner_stage }, status: 404
            return
        end
        unless ActiveRequest.where(from: partner.id, to: my_id).empty?
            # the other player has also sent a request to me
            # TODO: redirect to accept_request_and_start_game
        end
        ActiveRequest.new(from: my_id, to: partner.id).save
        Utils.send_pusher_msg_to_player(partner_id, "challenge_request", my_pub_name)
        render json: {status: "success"}, status: 200
    end

    def accept_request_and_start_game
        my_id = params[:id]
        partner_pub_name = params[:partner_pub_name]
        partner = Player.find_by(uniq_pub_name: partner_pub_name)
        unless ActiveRequest.where(from: partner.id, to: my_id).empty?
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
        partner_game_state["main_board"] += my_game_state["main_board"] 
        # TODO: assert that side drawers are null at this point
        partner_game.state = partner_game_state.to_json
        partner_game.turn = partner.id
        my_old_game_id = me.games_id
        me.games_id = partner_game.id 

        # TODO: These should be atomic.
        ActiveRequest.where(:from => [my_id, partner.id], :to => [my_id, partner.id]).destroy
        partner.save
        me.save
        partner_game.save
        Game.destroy(my_old_game_id)

        Utils.send_pusher_msg_to_player(partner_id, "challenge_accepted", me.uniq_pub_name)

        turn_str = Utils.get_turn_str(me.id, partner_game.turn)

        render json: {uniq_pub_name: player.uniq_pub_name, partner_pub_name: partner.uniq_pub_name, state: JSON.parse(partner_game_state), turn: turn_str}
    end

    def get_my_game_state
        # Player will call this after their partner accepts request/ makes a move 
        id = params[:id]
        me = Player.find_by(id: id)
        game = Game.find_by(id: me.games_id)
        # TODO: turn could also be part of game state?
        render json: {turn: game.turn, state: JSON.parse(game.state)}
    end


    def make_a_move
        my_id = params[:id]
        init_index = params[:init_index]
        final_index = params[:final_index]

        me = Player.find_by(id: id)
        game = Game.find_by(id: me.games_id)

        unless game.turn == me.id
            render json: { error: 'Not my turn' }, status: 403
        end

        # TODO: Check if the move is valid
        # TODO: Update game state
        
        # Reverse the board
        hash_state = JSON.parse(game.state)

        unless hash_state["stage"] == Constants::GamePlay
            render json: { error: "Game not in play, can't move" }, status: 403
        end

        hash_state["main_board"] = hash_state["main_board"].reverse
        hash_state["side_board"] = hash_state["side_board"].reverse
        game.state = hash_state.to_json

        partner = Player.where.not(id: me.id).find_by(games_id: game.id)

        game.turn = partner.id
        game.save

        # TODO: Check if game over

        # Partner may be able to calculate new board state on frontend 
        # but they should fetch it using get_my_game_state
        Utils.send_pusher_msg_to_player(partner.id, "opponent_moved", {"init_index": init_index, "final_index": final_index})
    end

    def register_new_game_for_player
        # Large parts of this will be from register_player
        # Check if the player's game is GameOver
        # TODO: implement
        my_id = params[:id]
    end
end
