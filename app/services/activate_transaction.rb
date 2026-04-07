# frozen_string_literal: true

class ActivateTransaction
  # Initialize the service.
  #
  # @param attributes [Hash] The new attributes for the transaction.
  # @param transaction [Transaction] The transaction to activate.
  def initialize(attributes:, transaction:)
    @attributes  = attributes
    @transaction = transaction
  end

  # Apply balance effects and update the transaction to become regular.
  #
  # @param attributes [Hash] The new attributes for the transaction.
  # @param transaction [Transaction] The transaction to activate.
  # @return [Boolean] Whether the transaction was activated successfully.
  def self.call(attributes:, transaction:)
    new(attributes: attributes, transaction: transaction).call
  end

  # Apply balance effects and update the transaction to become regular.
  #
  # @return [Boolean] Whether the transaction was activated successfully.
  def call
    ActiveRecord::Base.transaction do
      transaction.update!(attributes)

      increment_account

      if subcategory.inflow?
        increment_available_to_assign
      else
        increment_snapshots
      end

      true
    end
  end

  private

  attr_reader :attributes, :transaction

  delegate :account, :amount, :budget, :date, :subcategory, to: :transaction

  # Update the account based on the transaction amount.
  #
  # @return [void]
  def increment_account
    account.increment!(:balance, amount)
  end

  # Update the budget available to assign based on the transaction amount.
  #
  # @return [void]
  def increment_available_to_assign
    budget.increment!(:available_to_assign, amount)
  end

  # Update the category and subcategory snapshots based on transaction amount.
  #
  # @return [void]
  def increment_snapshots
    snapshots.each do |snapshot|
      if amount.positive?
        snapshot.increment!(:amount_assigned, amount)
      else
        snapshot.increment!(:amount_used, amount.abs)
      end
    end
  end

  # Return the category and subcategory snapshots for the transaction month.
  #
  # @return [Array<CategorySnapshot>] The snapshots for the category and subcategory.
  def snapshots
    [
      subcategory.parent.snapshots.for_month(date).find_or_create_by!(budget: budget),
      subcategory.snapshots.for_month(date).find_or_create_by!(budget: budget)
    ]
  end
end
