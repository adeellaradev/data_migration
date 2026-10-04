class Session < ApplicationRecord
  IDLE_TIMEOUT = 30.minutes
  ABSOLUTE_TIMEOUT = 12.hours
  ACTIVITY_WRITE_INTERVAL = 1.minute

  belongs_to :user

  before_validation { self.last_active_at ||= Time.current }

  def expired?
    last_active_at < IDLE_TIMEOUT.ago || created_at < ABSOLUTE_TIMEOUT.ago
  end

  def record_activity
    update_column(:last_active_at, Time.current) if last_active_at < ACTIVITY_WRITE_INTERVAL.ago
  end
end
