INIT_STATE="fds" # TODO: implement

class Api::V1::PlayerController < ApplicationController
    def register_player
        uniq_pub_name = params[:uniq_pub_name]
        unless uniq_pub_name
            render json: { error: 'Missing param uniq_pub_name' }, status: 400
            return
        end

        game = Game.new(state: INIT_STATE)
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

        render json: {uniq_pub_name: uniq_pub_name, uniq_backend_id: player.id }
    end
end
