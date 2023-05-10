INIT_STATE="fds" # TODO: implement

class Api::V1::PlayerController < ApplicationController
    def register_player
        uniq_pub_name = params[:uniq_pub_name]
        unless uniq_pub_name
            render json: { error: 'Missing param uniq_pub_name' }, status: 400
            return
        end
        
        uniq_backend_id = SecureRandom.uuid

        # TODO: this should be atomic - checking for name and then registering
        unless Player.where(uniq_pub_name: uniq_pub_name).empty?
            render json: { error: 'Player name already taken. Choose another.' }, status: 406
            return
        end

        game = Game.new(game_state: INIT_STATE, game_stage: "STRATEGISE")
        game.save

        player = Player.new(uniq_pub_name: uniq_pub_name, uniq_backend_id: uniq_backend_id, game_id: game.id)

        unless player.save
            # This shouldn't happen - only case it could happen is simultaneously two
            # players choosing a name which is unlikely (see above TODO)
            render json: { error: 'Some error occured' }, status: 500
            return
        end

        render json: {uniq_pub_name: uniq_pub_name, uniq_backend_id: uniq_backend_id }
    end
end
