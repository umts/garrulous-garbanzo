# frozen_string_literal: true

RSpec.describe 'editing an assignment' do
  let(:assignment) do
    create :assignment, start_date:, end_date:
  end
  let(:start_date) { Date.new(2017, 3, 31) }
  let(:end_date) { Date.new(2017, 4, 6) }

  before do
    when_current_user_is assignment.user
    visit edit_roster_assignment_path(assignment.roster, assignment)
  end

  it 'redirects to the correct URL' do
    click_button 'Save'
    expect(page).to have_current_path(roster_assignments_path(assignment.roster))
  end

  context 'when viewing the page' do
    it 'displays the correct owner' do
      expect(page).to have_field 'assignment_user_name', with: assignment.user.last_name, disabled: true
    end

    it 'displays the start date' do
      expect(find_field('Start date').value).to eq start_date.strftime('%Y-%m-%d')
    end

    it 'displays the end date' do
      expect(find_field('End date').value).to eq end_date.strftime('%Y-%m-%d')
    end
  end

  context 'when changing the assignment' do
    it 'updates the assignment' do
      date_today = Date.new(2017, 4, 4)
      fill_in('End date', with: date_today)
      click_button 'Save'
      expect(assignment.reload.end_date).to eq(date_today)
    end
  end

  context 'when the current user is an admin' do
    let!(:new_user) { roster_user(assignment.roster) }

    before do
      assignment.user.membership_in(assignment.roster).update admin: true
      visit current_path
    end

    it 'allows them to edit all assignments' do
      select(new_user.last_name, from: 'User')
      click_button 'Save'
      expect(assignment.reload.user).to eq new_user
    end

    it 'destroys the assignment' do
      click_button 'Delete assignment'
      expect(Assignment.find_by(id: assignment)).to be_blank
    end
  end

  context 'when the current user is not an admin' do
    it 'does not allow them to delete the assignment' do
      expect(page).to have_no_button 'Delete assignment'
    end
  end
end
