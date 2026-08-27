# frozen_string_literal: true

class HealthController < ActionController::Base
  CHECKS = {
    database:   -> { ActiveRecord::Base.connection.execute("SELECT 1") },
    migrations: -> { ActiveRecord::Migration.check_all_pending! }
  }.freeze

  # Render the health status based on defined checks.
  def index
    render json: results, status: status
  end

  private

  # Return the result of every check, running each one and treating any raised
  # error as a failure.
  #
  # @return [Hash{Symbol => Boolean}] Whether each check succeeded, by name.
  def results
    @results ||= CHECKS.transform_values do |method|
      method.call

      true
    rescue StandardError
      false
    end
  end

  # Return the HTTP status based on whether every check was successful.
  #
  # @return [Symbol] Either `:ok` or `:service_unavailable`.
  def status
    if results.values.all?
      :ok
    else
      :service_unavailable
    end
  end
end
