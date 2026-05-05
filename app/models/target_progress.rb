# frozen_string_literal: true

class TargetProgress
  attr_reader :category

  def initialize(category:, snapshot:)
    @category = category
    @snapshot = snapshot
  end

  # Returns true when the target has been fully funded.
  #
  # @return [Boolean] Whether the target is fully funded.
  def funded?
    funded_percentage == 100
  end

  # Returns the amount funded toward the target.
  #
  # @return [Integer] The funded amount in cents.
  def funded_amount
    snapshot.amount_assigned
  end

  # Returns the percentage of the target that has been funded, clamped
  # between 0 and 100. Returns 0 when the target amount is missing or zero
  # so callers don't have to guard the implicit category-validation invariant.
  #
  # @return [Integer] The funded percentage, between 0 and 100.
  def funded_percentage
    target_amount = category.target_amount.to_i

    if target_amount.positive?
      (funded_amount * 100 / target_amount).clamp(0, 100)
    else
      0
    end
  end

  # Returns the amount still needed to fully fund the target.
  #
  # @return [Integer] The underfunded amount in cents.
  def underfunded
    [category.target_amount - funded_amount, 0].max
  end

  # Returns true when the target has not yet been fully funded.
  #
  # @return [Boolean] Whether the target is underfunded.
  def underfunded?
    funded_percentage < 100
  end

  private

  attr_reader :snapshot
end
