require 'rails_helper'

# docker-compose run -e "RAILS_ENV=test" web bundle exec rspec ./spec/requests/api/v1/player_controller_spec.rb

RSpec.describe Api::V1::PlayerController, type: :controller do
  describe '#register_player' do
    let(:uniq_pub_name) { 'test_player' }

    context 'when the player name is missing' do
      it 'returns a 400 error' do
        post :register_player
        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)).to eq({'error' => 'Missing param uniq_pub_name'})
      end
    end

    context 'when the player name is already taken' do
      before { 
        g = Game.create()
        Player.create(uniq_pub_name: uniq_pub_name, games_id: g.id) 
      }

      it 'returns a 406 error' do
        post :register_player, params: { uniq_pub_name: uniq_pub_name }
        expect(response.status).to eq(406)
        expect(JSON.parse(response.body)).to eq({'error' => 'Player name already taken. Choose another.'})
      end
    end

    context 'when the player is successfully registered' do
      it 'creates a new game and player' do
        expect { post :register_player, params: { uniq_pub_name: uniq_pub_name } }
          .to change(Game, :count).by(1)
          .and change(Player, :count).by(1)

        player = Player.last
        expect(JSON.parse(response.body)).to eq({
          'uniq_pub_name' => uniq_pub_name,
          'id' => player.id,
          'state' => JSON.parse(Constants::INIT_STATE_STR)
        })
      end
    end
  end

  describe '#mark_player_ready' do
    let(:uniq_pub_name) { 'test_player' }
    let!(:game) { Game.create(state: Constants::INIT_STATE_STR) }
    let!(:player) { Player.create(games_id: game.id, uniq_pub_name:uniq_pub_name) }
    let!(:params) do
      {
        id: player.id,
        main_board: ["A"]*32,
        side_drawers: ["None"] * 16
      }
    end
    context "when player is ready to move to the partner selection stage" do
      before do
        game.state = Constants::INIT_STATE_STR
        game.save
        allow(Player).to receive(:find_by).with(id: player.id).and_return(player)
        allow(Game).to receive(:find_by).with(id: player.games_id).and_return(game)
        post :mark_player_ready, params: params
      end

      it "updates the game state with the player's chosen main board and side drawers" do
        game.reload
        game_state_hash = JSON.parse(game.state)
        expect(game_state_hash).to_not eq(Constants::INIT_STATE)
        expect(game_state_hash["main_board"]).to eq(params[:main_board])
        expect(game_state_hash["side_drawers"]).to eq(params[:side_drawers])
        expect(game_state_hash["stage"]).to eq(Constants::PartnerSelection)
      end

      it "returns the updated player and game state in the response" do
        response_body = JSON.parse(response.body)
        expect(response_body["uniq_pub_name"]).to eq(player.uniq_pub_name)
        expect(response_body["id"]).to eq(player.id)
        expect(response_body["state"]).to eq(JSON.parse(game.state))
      end

      it "returns a successful HTTP status code" do
        expect(response).to have_http_status(200)
      end
    end
  end
  describe Api::V1::PlayerController do
    describe "#send_request_to_player" do
      let(:uniq_pub_name) { 'test_player' }
      let(:partner_pub_name) { 'partner_player' }
      let!(:player1game) { Game.create(state: Constants::INIT_STATE_STR) }
      let!(:player1) { Player.create(games_id: player1game.id, uniq_pub_name:uniq_pub_name) }
      let!(:player2game) { Game.create(state: Constants::INIT_STATE_STR) }
      let!(:player2) { Player.create(games_id: player2game.id, uniq_pub_name:partner_pub_name) }

      context "when player's stage is not PartnerSelection" do
        before do
          game = Game.find_by(id: player1.games_id)
          game.state = { "stage" => "SomeOtherStage" }.to_json
          game.save!
        end
  
        it "returns an error and does not create an active request" do
          post :send_request_to_player, params: { id: player1.id, partner_pub_name: partner_pub_name }

          response_body = JSON.parse(response.body)
          expect(response).to have_http_status(:not_found)
          expect(response_body["error"]).to include("Partner stage incompatible")
          expect(ActiveRequest.where(from_id: player1.id, to_id: player2.id)).to be_empty
        end
      end
  
      # TODO: implement this feature
      # context "when partner has already sent a request to player" do
      #   before do
      #     ActiveRequest.create(from: partner.id, to: my_id)
      #   end
  
      #   it "redirects to accept_request_and_start_game action" do
      #     post :send_request_to_player, params: { id: my_id, partner_pub_name: partner_pub_name }
  
      #     expect(response).to redirect_to("/api/v1/accept_request_and_start_game/#{my_id}/#{partner.id}")
      #   end
      # end
  
      context "when player and partner are both in PartnerSelection stage" do
        before do
          state = Constants::INIT_STATE
          state["stage"] = Constants::PartnerSelection
          player2game.state = state.to_json()
          player2game.save

          player1game.state = state.to_json()
          player1game.save
        end
        it "creates a new active request" do
          post :send_request_to_player, params: { id: player1.id, partner_pub_name: partner_pub_name }

          expect(response).to have_http_status(:ok)
          expect(ActiveRequest.where(from_id: player1.id, to_id: player2.id)).not_to be_empty
        end
      end
    end
  end  
end
