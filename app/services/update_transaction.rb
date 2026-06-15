# frozen_string_literal: true

class UpdateTransaction
  # Initialize the service.
  #
  # @param attributes [Hash] The new attributes for the transaction.
  # @param transaction [Transaction] The transaction to update.
  def initialize(attributes:, transaction:)
    @attributes           = attributes
    @previous_transaction = transaction.dup
    @transaction          = transaction
  end

  # Update the transaction and adjust the related balances.
  #
  # @param attributes [Hash] The new attributes for the transaction.
  # @param transaction [Transaction] The transaction to update.
  # @return [Boolean] Whether the transaction was updated successfully.
  def self.call(attributes:, transaction:)
    new(attributes: attributes, transaction: transaction).call
  end

  # Update the transaction and adjust the related balances.
  #
  # @return [Boolean] Whether the transaction was updated successfully.
  def call
    ActiveRecord::Base.transaction do
      transaction.update!(attributes)
      adjust_account_balance
      adjust_category_effects

      true
    end
  end

  private

  attr_reader :attributes, :previous_transaction, :transaction

  delegate :account, :amount, :budget, :date, :subcategory, to: :transaction
  delegate :account, :amount, :date, :subcategory, to: :previous_transaction, prefix: :previous

  # Adjust the account balance based on what changed.
  #
  # @return [void]
  def adjust_account_balance
    if account == previous_account
      if amount_delta.nonzero?
        account.increment!(:balance, amount_delta)
      end
    else
      previous_account.increment!(:balance, -previous_amount)
      account.increment!(:balance, amount)
    end
  end

  # Adjust the category effects based on what changed. When the same snapshots
  # are affected, a single net adjustment by the amount delta avoids reversing
  # and reapplying the full effect, and an unchanged amount needs no adjustment
  # at all.
  #
  # @return [void]
  def adjust_category_effects
    if snapshots_changed?
      apply_category_effect(previous_subcategory, previous_date, -previous_amount)
      apply_category_effect(subcategory, date, amount)
    elsif amount_delta.nonzero?
      apply_category_effect(subcategory, date, amount_delta)
    end
  end

  # Return the difference between the new and previous amounts.
  #
  # @return [Integer] The difference between the new and previous amounts.
  def amount_delta
    @amount_delta ||= amount - previous_amount
  end

  # Apply a signed amount to the appropriate balance for the subcategory. An
  # inflow moves available to assign, while any other subcategory moves the used
  # column of each snapshot by the negated amount, since spending is negative
  # and a refund is positive. The caller negates the amount to reverse an
  # effect.
  #
  # @param subcategory [Category] The subcategory to apply the effect to.
  # @param date [Date] The date for snapshot lookup.
  # @param amount [Integer] The signed amount to apply.
  # @return [void]
  def apply_category_effect(subcategory, date, amount)
    if subcategory.inflow?
      budget.increment!(:available_to_assign, amount)
    else
      snapshots_for(subcategory, date).each do |snapshot|
        snapshot.increment!(:amount_used, -amount)
      end
    end
  end

  # Return whether different snapshots are affected due to a subcategory or
  # month change.
  #
  # @return [Boolean] Whether the snapshots have changed.
  def snapshots_changed?
    previous_subcategory != subcategory ||
      previous_date.beginning_of_month != date.beginning_of_month
  end

  # Return the category and subcategory snapshots for the given subcategory
  # and date.
  #
  # @param subcategory [Category] The subcategory to look up snapshots for.
  # @param date [Date] The date for month-based snapshot lookup.
  # @return [Array<CategorySnapshot>] The parent and subcategory snapshots.
  def snapshots_for(subcategory, date)
    [
      subcategory.parent.snapshots.for_month(date).find_or_create_by!(budget: budget),
      subcategory.snapshots.for_month(date).find_or_create_by!(budget: budget)
    ]
  end
end
