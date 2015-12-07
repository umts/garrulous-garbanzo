require 'rails_helper'

describe User do
  describe 'validations' do
    it 'allows only one fallback user' do
      expect { create :user, is_fallback: true }
        .not_to raise_error
      expect { create :user, is_fallback: true }
        .to raise_error(ActiveRecord::RecordInvalid,
                        'Validation failed: ' \
                        'Fallback may be true for only one user')
    end
  end
  describe 'full_name' do
    it 'returns first name followed by last name' do
      user = create :user
      expect(user.full_name).to eql [user.first_name, user.last_name].join(' ')
    end
  end
  describe 'proper name' do
    it 'returns first name followed by last name' do
      user = create :user
      expect(user.proper_name)
        .to eql [user.last_name, user.first_name].join(', ')
    end
  end
  describe 'self.fallback' do
    it 'returns the fallback user if one is present' do
      fallback = create :user, is_fallback: true
      expect(User.fallback).to eql fallback
    end
    it 'returns nil if no fallback user is present' do
      expect(User.fallback).to eql nil
    end
  end
end
