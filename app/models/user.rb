# frozen_string_literal: true

class User < ApplicationRecord
  has_paper_trail
  has_many :assignments, dependent: :restrict_with_error
  has_many :memberships, dependent: :destroy
  has_many :rosters, through: :memberships
  has_many :fallback_rosters, class_name: 'Roster',
                              foreign_key: :fallback_user_id,
                              inverse_of: 'fallback_user',
                              dependent: :nullify

  validates :first_name, :last_name, :spire, :email, :phone, :rosters,
            presence: true
  validates :spire, :email, :phone,
            uniqueness: {case_sensitive: false}
  validates :spire,
            format: { with: /\A\d{8}@umass.edu\z/,
                      message: 'must be 8 digits followed by @umass.edu' }
  validates :phone,
            format: { with: /\A\+1\d{10}\z/,
                      message: 'must be "+1" followed by 10 digits' }
  before_save :generate_calendar_access_token,
              unless: -> { calendar_access_token.present? }
  before_save -> { assignments.future.destroy_all }, if: :being_deactivated?

  scope :active, -> { where active: true }
  scope :inactive, -> { where active: false }

  def full_name
    "#{first_name} #{last_name}"
  end

  def proper_name
    "#{last_name}, #{first_name}"
  end

  def admin_in?(roster)
    membership_in(roster).try(:admin?) || false
  end

  def admin?
    memberships.any?(&:admin?)
  end

  def membership_in(roster)
    memberships.find_by(roster: roster)
  end

  def generate_calendar_access_token
    loop do
      self.calendar_access_token = SecureRandom.hex
      break unless self.class
                       .exists?(calendar_access_token: calendar_access_token)
    end
  end

  def being_deactivated?
    active_changed? && !active?
  end
end
