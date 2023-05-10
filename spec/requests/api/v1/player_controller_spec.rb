require 'rails_helper'

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
      before { Player.create(uniq_pub_name: uniq_pub_name) }

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
          'state' => JSON.parse(INIT_STATE_STR)
        })
      end
    end
  end
end
