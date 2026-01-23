# frozen_string_literal: true

class CreateTransaction
  # Initialize the service.
  #
  # @param transaction [Transaction] The transaction to create.
  def initialize(transaction:)
    @transaction = transaction
  end

  # Create the transaction and update the category snapshots.
  #
  # @param transaction [Transaction] The transaction to create.
  # @return [Boolean]
  def self.call(transaction:)
    new(transaction: transaction).call
  end

  # Create the transaction and update the category snapshots.
  #
  # @return [Boolean]
  def call
    ActiveRecord::Base.transaction do
      transaction.save!

      category_snapshot.increment!(:amount_used, amount)         # rubocop:disable Rails/SkipsModelValidations
      parent_category_snapshot&.increment!(:amount_used, amount) # rubocop:disable Rails/SkipsModelValidations

      true
    end
  end

  private

  attr_reader :transaction

  delegate :amount, :category, to: :transaction

  # Return the category snapshot for the current month.
  #
  # @return [CategorySnapshot] The snapshot of the category.
  def category_snapshot
    @category_snapshot ||= category.snapshots.for_month(Date.current).first
  end

  # Return the parent category of the transaction category.
  #
  # @return [Category] The parent category.
  # @return [nil] When there is no parent category.
  def parent_category
    @parent_category ||= category.parent
  end

  # Return the parent category snapshot for the current month.
  #
  # @return [CategorySnapshot] The snapshot for the parent category.
  # @return [nil] When there is no parent category.
  def parent_category_snapshot
    @parent_category_snapshot ||= if parent_category
                                    parent_category.snapshots.for_month(Date.current).first
                                  end
  end
end
