# frozen_string_literal: true

class Payee < ApplicationRecord
  SUGGESTED_CATEGORY_LIMIT = 3

  belongs_to :budget

  has_many :transactions, dependent: :restrict_with_error

  validates :name, presence:   true,
                   uniqueness: { case_sensitive: false, scope: :budget_id }

  normalizes :name, with: ->(value) { value.strip }

  scope :by_name, ->(name) { where("LOWER(name) = LOWER(?)", name.to_s.strip) }

  # Reassign this payee's transactions to another payee and destroy
  # this payee.
  #
  # @param other [Payee] The payee to absorb this payee's transactions.
  # @return [Payee] The destroyed payee.
  def merge_into(other)
    transaction do
      transactions.update_all(payee_id: other.id) # rubocop:disable Rails/SkipsModelValidations

      destroy!
    end
  end

  # Return the account id from the most recent transaction for this payee.
  #
  # @return [Integer] The most recent account id.
  # @return [nil] When the payee has no transactions.
  def previous_account_id
    transactions.reorder(date: :desc, id: :desc).pick(:account_id)
  end

  # Return the subcategory id from the most recent categorized transaction for
  # this payee.
  #
  # @return [Integer] The most recent subcategory id.
  # @return [nil] When the payee has no categorized transactions.
  def previous_subcategory_id
    transactions.where.not(category_id: nil).reorder(date: :desc, id: :desc).pick(:category_id)
  end

  # Return the three subcategory IDs most used for this payee, ordered by
  # usage count descending, tiebroken by most recent transaction date and ID.
  #
  # @return [Array<Integer>] The most used subcategory IDs.
  def suggested_subcategory_ids
    transactions
      .where.not(category_id: nil)
      .group(:category_id)
      .reorder(Arel.sql("COUNT(*) DESC, MAX(date) DESC, MAX(id) DESC"))
      .limit(SUGGESTED_CATEGORY_LIMIT)
      .pluck(:category_id)
  end
end
