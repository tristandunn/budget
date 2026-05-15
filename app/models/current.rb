# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :budget
  attribute :user

  resets do
    Time.zone = nil
  end

  # Assign the active budget and apply its configured time zone.
  #
  # @param budget [Budget, nil] The budget for the current request or job.
  # @return [void]
  def budget=(budget)
    super

    Time.zone = budget&.settings&.time_zone
  end
end
