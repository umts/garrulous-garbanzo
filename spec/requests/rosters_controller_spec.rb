# frozen_string_literal: true

RSpec.describe RostersController do
  describe '#index' do
    subject(:json) do
      when_current_user_is :anyone
      get "/rosters/#{roster.to_param}.json"
      response.parsed_body
    end

    let(:roster) { create :roster }

    it 'contains roster attributes' do
      expect(json['name']).to eq(roster.name)
    end

    context 'when no one is on-call' do
      it 'has a null on_call value' do
        expect(json['on_call']).to be_nil
      end
    end

    context 'when the fallback user is on-call' do
      let(:fallback) { create :user, last_name: "O'Hanraha-hanrahan" }
      let(:roster) { create :roster, fallback_user: fallback }

      it 'lists the fallback user as on-call' do
        expect(json['on_call']['last_name']).to eq(fallback.last_name)
      end

      it 'does not list an end date' do
        expect(json['on_call']['until']).to be_nil
      end
    end

    context 'when someone is on-call' do
      let(:user) { create :user, last_name: 'Kanasis', rosters: [roster] }

      let! :assignment do
        create :assignment, start_date: Date.yesterday, end_date: Date.tomorrow, roster:, user:
      end

      it 'lists the on-call user' do
        expect(json['on_call']['last_name']).to eq(user.last_name)
      end

      it 'lists an end date and time' do
        expect(Time.zone.parse(json['on_call']['until'])).to eq(assignment.effective_end_datetime)
      end
    end
  end
end
