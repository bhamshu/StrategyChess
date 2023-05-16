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

    EmptyPiece = "None_None"

    Opponent = "Opponent"

    INIT_STATE={
        "stage": Constants::Strategise,
        "main_board":  (Array.new (32) { EmptyPiece }).concat([EmptyPiece, EmptyPiece, EmptyPiece, EmptyPiece, EmptyPiece, EmptyPiece, EmptyPiece, EmptyPiece, EmptyPiece, 'White_Knight', EmptyPiece, EmptyPiece, EmptyPiece, 'White_Pawn', 'White_Pawn', 'White_Pawn', EmptyPiece, 'White_Bishop', EmptyPiece, 'White_Rook', 'White_Rook', 'White_Pawn', 'White_Bishop', 'White_Pawn', 'White_Knight', EmptyPiece, 'White_Pawn', EmptyPiece, 'White_Queen', 'White_Pawn', 'White_Pawn', 'White_King',]),
        "side_drawers": (Array.new (32) { EmptyPiece }),
    }
    INIT_STATE_STR = INIT_STATE.to_json
end

module Utils
    def Utils.send_pusher_msg_to_player(player_id, event, message)
        if Rails.env.test?
            return 
        end
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

    def Utils.get_board_with_inverted_colors(board)
        return board.map {|color_name|
            color, name = color_name.split("_")
            # last case is for None
            color=="White"? "Black_"+name : (color=="Black"? "White_"+name : color_name)
        }
    end

    def Utils.color_of_piece(piece)
        piece.split("_")[0]
    end

    def Utils.is_move_valid(main_board, init_index, final_index)
        # Basic sanity checks like whose turn it is, if the indices
        # lie within bounds, the pieces are of different colors, the source piece 
        # is not empty - they should have been checked before calling
        # this method. This method is just for validating the piece's signature move
        source_piece = main_board[init_index].split("_")[1]
        init_x, init_y = init_index%8, init_index/8
        final_x, final_y = final_index%8, final_index/8
        x_abs_diff = (final_x - init_x).abs
        y_abs_diff = (final_y - init_y).abs
        # x_step and y_step are either +1 or -1
        x_step = (x_abs_diff != 0) ? ((final_x - init_x)/x_abs_diff) : 0
        y_step = (y_abs_diff != 0) ? ((final_y - init_y)/y_abs_diff) : 0

        case source_piece
        when "Pawn"
            # Remember that the indices start from 0 at top left to 63 at bottom right
            case (init_index-final_index)
            when 8
                if (main_board[final_index]==Constants::EmptyPiece)
                    return true
                else
                    return false
                end
            when 7..9 # and not 8, which has been sieved above
                dest_piece = main_board[final_index]
                if (dest_piece!=Constants::EmptyPiece)
                    # assuming that color is different has been checked
                    # as that is common condition for all pieces and cases
                    return true
                else
                    return false
                end
            else
                return false
            end
        when "Knight"
            if (x_abs_diff==2 && y_abs_diff==1) || (x_abs_diff==1 && y_abs_diff==2)
                return true
            else
                return false
            end
        when "Bishop"
            if x_abs_diff == y_abs_diff
                for i in 1...x_abs_diff do
                    if (main_board[(init_y + y_step*i)*8 + (init_x + x_step*i)]!=Constants::EmptyPiece)
                        return false
                    end
                end        
                return true
            else 
                return false
            end
        when "Rook"
            p x_abs_diff, y_abs_diff
            if (x_abs_diff == 0) || (y_abs_diff == 0)
                moving_axis_abs_diff = [x_abs_diff, y_abs_diff].max
                p moving_axis_abs_diff, "AAAAAAAAAAAAAAAAAAAAAAAAA"
                for i in 1...moving_axis_abs_diff do
                    if (main_board[(init_y + y_step*i)*8 + (init_x + x_step*i)]!=Constants::EmptyPiece)
                        p main_board[(init_y + y_step*i)*8 + (init_x + x_step*i)], "PPPPPPPPPPP", (init_y + y_step*i)*8 + (init_x + x_step*i), init_x, init_y, x_step, y_step
                        return false
                    end
                end        
                return true
            else
                return false
            end
        when "Queen"
            if (x_abs_diff == y_abs_diff) || (x_abs_diff == 0) || (y_abs_diff == 0)
                moving_axis_abs_diff = [x_abs_diff, y_abs_diff].max
                for i in 1...moving_axis_abs_diff do
                    if (main_board[(init_y + y_step*i)*8 + (init_x + x_step*i)]!=Constants::EmptyPiece)
                        return false
                    end
                end        
                return true
            else 
                return false
            end
        when "King"
            if (x_abs_diff <= 1) && (y_abs_diff <= 1)
                return true
            else
                return false
            end
        else
            p "shouldn't happen - unless you've added provision for new pieces, in which case add a case above"
            return false
        end
    end
end
