# frozen_string_literal: true

class Membership < ApplicationRecord
  has_paper_trail
  belongs_to :user
  belongs_to :roster
  validates :user, uniqueness: { scope: :roster }
end
