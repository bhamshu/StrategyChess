require 'pusher'

class Constants
    @@pusher_client = nil
    def self.pusher_client
       unless @@pusher_client
          @@pusher_client = Pusher::Client.new(
            app_id: '1598484',
            key: ENV.fetch("PUSHER_APP_KEY"),
            secret: ENV.fetch("PUSHER_SECRET"),
            cluster: 'mt1',
            encrypted: true
          )
       end
       @@pusher_client
    end

    # Game Stages
    Strategise = "Strategise"
    PartnerSelection = "PartnerSelection"
    GamePlay = "GamePlay"
    GameOver = "GameOver"
    
    # Turn Strings
    MyTurn = "MyTurn"
    OtherPersonsTurn = "OtherPersonsTurn"
end

module Utils
    def Utils.send_pusher_msg_to_player(player_id, event, message)
        Constants.pusher_client.trigger(
            player_id, event, {
            message: message
        })
    end

    def Utils.get_turn_str(my_id, turn_player_id)
        if my_id == turn_player_id
            return Constants::MyTurn
        else
            return Constants::OtherPersonsTurn
        end
    end
end
