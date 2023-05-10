INIT_STATE_STR={
    "stage": "strategising",
    "main_board":[
        ["None", "None", "None", "None"],
        ["None", "None", "None", "None"],
        ["None", "None", "None", "None"],
        ["None", "None", "None", "None"],
    ],
    "side_drawers": [
        ["King", "Queen", "Rook", "Rook"],
        ["Bishop", "Bishop", "Knight", "Knight"],
        ["Pawn", "Pawn", "Pawn", "Pawn"],
        ["Pawn", "Pawn", "Pawn", "Pawn"],
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
end
