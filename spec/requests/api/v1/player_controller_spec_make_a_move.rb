require 'rails_helper'

RSpec.describe Api::V1::PlayerController, type: :controller do
  describe "POST #make_a_move" do
    let!(:game) { Game.create(state: Constants::INIT_STATE) }
    let!(:player1) { Player.create(games_id: game.id, uniq_pub_name:"p1") }
    let!(:player2) { Player.create(games_id: game.id, uniq_pub_name:"p2") }

    before do
      game.update_attributes(state: '{"stage":"GamePlay","main_board":["C","D","None","King"],"side_drawers":["King","None","Queen","None","None","None"]}', turn: player1.id)
    end

    context "when not player's turn" do
      it "returns a 403 error" do
        post :make_a_move, params: { id: player2.id, init_index: 0, final_index: 1 }
        expect(response).to have_http_status(403)
        expect(JSON.parse(response.body)).to eq({ "error" => "Not my turn" })
      end
    end

    context "when move is invalid" do
      it "returns a 403 error" do
        post :make_a_move, params: { id: player1.id, init_index: -1, final_index: 8 }
        expect(response).to have_http_status(403)
        expect(JSON.parse(response.body)).to eq({ "error" => "Invalid move" })
      end
    end

    context "when game is not in play" do
      it "returns a 403 error" do
        game.update_attributes(state: '{"stage":"partner_selection","main_board":["C","D","None","None"],"side_drawers":["None","None","None","None","None","None"]}')
        post :make_a_move, params: { id: player1.id, init_index: 0, final_index: 8 }
        expect(response).to have_http_status(403)
        expect(JSON.parse(response.body)).to eq({ "error" => "Game not in play, can't move" })
      end
    end

    context "when move is valid and game is in play" do
      it "updates the game state and returns correct state" do
        post :make_a_move, params: { id: player1.id, init_index: 0, final_index: 1 }
        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)).to eq({"main_board"=>["None", "C", "None", "King"], "side_drawers"=>["King", "D", "Queen", "None", "None", "None"], "game_over"=>false})

        game.reload
        expect(game.turn).to eq(player2.id)
        # Boards have been inverted 
        expect(game.state).to eq('{"stage":"GamePlay","main_board":["King","None","C","None"],"side_drawers":["None","None","None","Queen","D","King"]}')
        
      end
    end
    context "when move is valid and a player kills the king" do
      it "updates the game state and returns game over true" do
        post :make_a_move, params: { id: player1.id, init_index: 0, final_index: 3}
        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)).to eq({"main_board"=>["None", "D", "None", "C"], "side_drawers"=>["King", "King", "Queen", "None", "None", "None"], "game_over"=>true})

        game.reload
        expect(game.turn).to eq(player2.id)
        # Boards have been inverted 
        expect(game.state).to eq('{"stage":"GameOver","main_board":["C","None","D","None"],"side_drawers":["None","None","None","Queen","King","King"],"winner_uniq_pub_name":"p1"}')
        
      end
    end
  end
end
