# frozen_string_literal: true

RSpec.describe 'viewing the index' do
  let(:roster) { create :roster }
  let(:user) { roster_user(roster) }

  context 'interacting with the ICS feed URL', js: true do
    before :each do
      set_current_user(user)
      visit root_path
    end
    it 'displays copy url info' do
      find('.glyphicon-info-sign').click.hover
      expect(page).to have_selector '.tooltip',
                                    text: 'Use this address to subscribe'
    end
    it 'displays click to copy tooltip' do
      find('.copy-text-btn').hover
      expect(page).to have_selector '.tooltip', text: 'Click to copy link'
    end
    it 'copys link on button press' do
      find('.copy-text-btn').click.hover
      expect(page).to have_selector '.tooltip', text: 'Copied successfully!'
    end
  end

  describe 'interacting with the calendar', js: true do
    before(:each) do
      set_current_user(user)
    end

    it 'highlights today' do
      visit roster_assignments_path(roster)
      today = Time.zone.today.day
      expect(page).to have_selector('td.fc-day-today', text: today)
    end

    context 'assignment belongs to user' do
      it 'appears highlighted for your assignment' do
        create :assignment, start_date: 3.days.ago, end_date: 3.days.since,
                            user: user, roster: roster
        visit roster_assignments_path(roster)
        expect(page).to have_selector('.assignment-event-owned')
      end
    end

    context 'assignment does not belong to user' do
      it 'appears highlighted differently for other assignments' do
        create :assignment, start_date: 3.days.ago, end_date: 3.days.since,
                            user: roster_user(roster), roster: roster
        visit roster_assignments_path(roster)
        expect(page).to have_selector(
          '.assignment-event:not(.assignment-event-owned)'
        )
      end
    end

    context 'clicking on an empty day' do
      let(:date) { Time.zone.today.change(day: 14) }
      let(:new_path) do
        new_roster_assignment_path roster_id: roster.id,
                                   date: date.to_s(:db)
      end

      it 'sends you to create a new assignment' do
        visit roster_assignments_path(roster)

        find('td.fc-day', text: '14').click
        expect(page).to have_current_path(new_path)
      end
    end

    context 'switching months' do
      it 'stores the last viewed month' do
        visit roster_assignments_path(roster)
        3.times { click_on 'next' }

        # Go anywhere else, come back
        visit edit_roster_user_path(roster, user)
        visit roster_assignments_path(roster)

        three_months_from_now = (Time.zone.now + 3.months).strftime('%B %Y')
        expect(page).to have_text(three_months_from_now)
      end
    end
  end
end
