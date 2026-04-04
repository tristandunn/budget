# frozen_string_literal: true

class Settings
  # Initialize the settings.
  #
  # @param budget [Budget] The budget whose settings to manage.
  def initialize(budget)
    @budget = budget
  end

  # Whether reconciled transactions should be hidden from transaction lists.
  #
  # @return [Boolean] Whether reconciled transactions should be hidden.
  def hide_reconciled?
    enabled?(:hide_reconciled)
  end

  # Update settings from a permitted parameters hash.
  #
  # @param attributes [Hash] The settings to update.
  # @return [void]
  def update(attributes)
    attributes.each do |key, value|
      if ActiveModel::Type::Boolean.new.cast(value)
        store[key.to_s] = true
      else
        store.delete(key.to_s)
      end
    end

    budget.save!
  end

  private

  attr_reader :budget

  # Whether a setting value is truthy.
  #
  # @param key [Symbol] The setting key.
  # @return [Boolean] Whether the setting is enabled.
  def enabled?(key)
    store[key.to_s] == true
  end

  # Return the raw settings hash from the budget.
  #
  # @return [Hash] The raw settings hash.
  def store
    budget.read_attribute(:settings)
  end
end
