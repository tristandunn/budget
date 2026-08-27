# frozen_string_literal: true

class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :budget
  belongs_to :payee
  belongs_to :subcategory, class_name:  "Category",
                           foreign_key: :category_id,
                           inverse_of:  :transactions,
                           optional:    true
  belongs_to :transfer_pair, class_name: "Transaction", optional: true

  enum :frequency,
       {
         daily:            1,
         weekly:           7,
         every_other_week: 14,
         monthly:          30,
         yearly:           365
       },
       validate: { allow_nil: true }
  enum :status, { pending: 0, cleared: 1, reconciled: 2, upcoming: 3 }, validate: true

  validates :amount, presence: true, numericality: { only_integer: true, other_than: 0 }
  validates :date,   presence: true

  validate :validate_subcategory

  normalizes :memo, with: ->(value) { value.strip }

  default_scope -> { order(date: :asc, created_at: :asc) }

  scope :activation_due, -> { upcoming.where(date: ..Date.current) }
  scope :recent,         -> { where(date: 30.days.ago.to_date..) }

  # Return whether this transaction may be cleared or uncleared. Only pending
  # and cleared transactions may be toggled, and upcoming and reconciled
  # transactions may not.
  #
  # @return [Boolean] Whether the transaction may be cleared or uncleared.
  def clearable?
    pending? || cleared?
  end

  # Return the attributes to copy when creating a new occurrence. The payee
  # association is included in place of its foreign key so an unsaved new payee
  # is carried over and autosaved with the copy.
  #
  # @return [Hash{Symbol => Object}] The attributes to copy to the new occurrence.
  def copyable_attributes
    attributes.symbolize_keys
              .slice(:account_id, :amount, :budget_id, :category_id, :memo)
              .merge(payee: payee)
  end

  # Return whether this transaction may be destroyed. Both the transaction and,
  # if a transfer, its partner must be unreconciled.
  #
  # @return [Boolean] Whether the transaction may be destroyed.
  def destroyable?
    !reconciled? && !transfer_pair&.reconciled?
  end

  # Return the date for the next recurring occurrence.
  #
  # @param frequency [String, Symbol, nil] The frequency to advance by, defaulting to the transaction's frequency.
  # @return [Date] The next recurring date.
  # @return [nil] When the frequency is blank or unrecognized.
  def next_recurring_date(frequency: self.frequency)
    case frequency.to_s
    when "daily"            then date.advance(days: 1)
    when "weekly"           then date.advance(weeks: 1)
    when "every_other_week" then date.advance(weeks: 2)
    when "monthly"          then date.advance(months: 1)
    when "yearly"           then date.advance(years: 1)
    end
  end

  # Return whether the transaction has a frequency and a future date. This is
  # distinct from the upcoming status, which is set explicitly.
  #
  # @return [Boolean] Whether the transaction is a scheduled recurring transaction.
  def recurring_scheduled?
    frequency.present? && scheduled?
  end

  # Return whether the transaction date is in the future.
  #
  # @return [Boolean] Whether the transaction date is in the future.
  def scheduled?
    date.future?
  end

  # Return whether this transaction is one half of a transfer pair.
  #
  # @return [Boolean] Whether the transaction is part of a transfer.
  def transfer?
    transfer_pair_id.present?
  end

  # Return whether this transaction may not be edited through the
  # standard form.
  #
  # @return [Boolean] Whether the transaction may not be edited.
  def uneditable?
    reconciled? || transfer?
  end

  private

  # Return whether an assigned subcategory is a top-level category, which has
  # no parent and so cannot hold a transaction.
  #
  # @return [Boolean] Whether the assigned subcategory is a top-level category.
  def invalid_subcategory?
    subcategory.present? && subcategory.parent.blank?
  end

  # Validate that an assigned subcategory is not a top-level category.
  #
  # @return [void]
  def validate_subcategory
    if invalid_subcategory?
      errors.add(:subcategory, :not_a_subcategory)
    end
  end
end
