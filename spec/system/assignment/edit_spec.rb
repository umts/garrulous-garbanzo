# frozen_string_literal: true

RSpec.describe 'edit an assignment' do
  let(:roster) { create :roster }
  let(:user) { create :user, rosters: [roster] }
  let(:assignment) do
    create :assignment,
           user: user,
           roster: roster,
           start_date: start_date,
           end_date: end_date
  end
  let(:date_today) { Date.new(2017, 4, 4) }
  let(:start_date) { Date.new(2017, 3, 31) }
  let(:end_date) { Date.new(2017, 4, 6) }

  before { set_current_user(user) }

  context 'returns the user to the appropriate index page' do
    it 'redirects to the correct URL' do
      assignment.start_date = start_date
      visit edit_roster_assignment_path(roster, assignment)
      click_button 'Save'
      expect(page).to have_current_path(roster_assignments_path(roster))
    end
  end

  context 'Viewing the page' do
    it 'displays the correct owner' do
      last_name = assignment.user.last_name
      visit edit_roster_assignment_path(roster, assignment)
      expect(page).to have_selector :select, text: last_name
    end

    it 'displays the start date' do
      visit edit_roster_assignment_path(roster, assignment)
      expect(find_field('Start date').value)
        .to eq start_date.strftime('%Y-%m-%d')
    end

    it 'displays the end date' do
      visit edit_roster_assignment_path(roster, assignment)
      expect(find_field('End date').value)
        .to eq end_date.strftime('%Y-%m-%d')
    end
  end

  context 'changing the assignment' do
    let(:last_name) { user.last_name }

    it 'updates the assignment' do
      visit edit_roster_assignment_path(roster, assignment)
      fill_in('End date', with: date_today)
      click_button 'Save'
      expect(assignment.reload.end_date).to eq(date_today)
    end

    it 'destroys the assignment' do
      visit edit_roster_assignment_path(roster, assignment)
      click_button 'Delete assignment'
      expect(Assignment.find_by(id: assignment)).to be_blank
    end
  end

  context 'only correct users can edit assignment' do
    before do
      @new_user = create :user, rosters: [roster]
      @last_name = @new_user.last_name
    end

    it 'stops users from changing assignments they do not own' do
      visit edit_roster_assignment_path(roster, assignment)
      select(@last_name, from: 'User')
      click_button 'Save'
      within('div.alert.alert-danger') do
        expect(page).to have_selector 'li', text: 'You may only edit'
      end
    end

    it 'allows admin users to edit all assignments' do
      user.membership_in(roster).update admin: true
      visit edit_roster_assignment_path(roster, assignment)
      select(@last_name, from: 'User')
      click_button 'Save'
      expect(assignment.reload.user).to eq @new_user
    end
  end
end
