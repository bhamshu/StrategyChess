require 'pusher'

class Constants
    @@pusher_client = nil
    def self.pusher_client
       unless @@pusher_client
          @@pusher_client =  = Pusher::Client.new(
            app_id: '1598484',
            key: ENV.fetch("PUSHER_APP_KEY"),
            secret: ENV.fetch("PUSHER_SECRET"),
            cluster: 'mt1',
            encrypted: true
          )
       end
       @@pusher_client
    end

    Strategise = "Strategise"
    PartnerSelection = "PartnerSelection"
    GamePlay = "GamePlay"
    GameOver = "GameOver"
end

module Utils
    def send_pusher_msg_to_player(player_id, event, message)
        Constants.pusher_client.trigger(
            player_id, event, {
            message: message
        })      
    end 
end
