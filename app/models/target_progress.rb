# frozen_string_literal: true

class TargetProgress
  attr_reader :category

  # Initialize the target progress.
  #
  # @param category [Category] The category whose target to evaluate.
  # @param rollover [Integer] The available amount carried in from prior months, in cents.
  # @param snapshot [CategorySnapshot] The displayed-month snapshot for the category.
  def initialize(category:, rollover:, snapshot:)
    @category = category
    @rollover = rollover
    @snapshot = snapshot
  end

  # Return whether the target has been fully funded.
  #
  # @return [Boolean] Whether the target is fully funded.
  def funded?
    funded_percentage == 100
  end

  # Return the amount funded toward the target. A monthly spending target
  # counts rollover carried in from prior months plus the displayed month's
  # assignment. A monthly savings target counts only the displayed month's
  # assignment, so each month requires a fresh contribution.
  #
  # @return [Integer] The funded amount in cents.
  def funded_amount
    if category.target_type_monthly_savings?
      snapshot.amount_assigned
    else
      rollover + snapshot.amount_assigned
    end
  end

  # Return the percentage of the target that has been funded, clamped between
  # 0 and 100.
  #
  # Fall back to 0 when the target amount is missing or zero, so callers do
  # not have to guard against a category with no target amount.
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

  # Return the amount still needed to fully fund the target.
  #
  # @return [Integer] The underfunded amount in cents.
  def underfunded
    [category.target_amount - funded_amount, 0].max
  end

  # Return whether the target has not yet been fully funded.
  #
  # @return [Boolean] Whether the target is underfunded.
  def underfunded?
    funded_percentage < 100
  end

  private

  attr_reader :rollover, :snapshot
end
