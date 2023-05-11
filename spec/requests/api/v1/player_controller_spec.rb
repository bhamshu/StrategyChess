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
end
