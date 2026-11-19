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

  validates :amount,      presence: true, numericality: { only_integer: true, other_than: 0 }
  validates :date,        presence: true
  validates :subcategory, presence: true, unless: -> { transfer_pair }

  validate :validate_subcategory

  normalizes :memo, with: ->(value) { value.strip }

  default_scope -> { order(date: :asc, created_at: :asc) }

  scope :activation_due, -> { upcoming.where(date: ..Date.current) }
  scope :recent,         -> { where(date: 30.days.ago.to_date..) }
  scope :transfer,       -> { where.not(transfer_pair_id: nil) }

  # Return whether this transaction may be cleared or uncleared. Only pending
  # and cleared transactions may be toggled, and upcoming and reconciled
  # transactions may not.
  #
  # @return [Boolean] Whether the transaction may be cleared or uncleared.
  def clearable?
    pending? || cleared?
  end

  # Return the attributes to copy when creating a new occurrence. Associations
  # are included in place of their foreign keys so an unsaved new payee is
  # carried over and autosaved with the copy, and so validating the copy reuses
  # the loaded records rather than querying for each one again.
  #
  # @return [Hash{Symbol => Object}] The attributes to copy to the new occurrence.
  def copyable_attributes
    attributes.symbolize_keys
              .slice(:amount, :memo)
              .merge(account: account, budget: budget, payee: payee, subcategory: subcategory)
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
  # @param from [Date] The date to advance, defaulting to the transaction's date.
  # @return [Date] The next recurring date.
  # @return [nil] When the frequency is blank or unrecognized.
  def next_recurring_date(frequency: self.frequency, from: date)
    case frequency.to_s
    when "daily"            then from.advance(days: 1)
    when "weekly"           then from.advance(weeks: 1)
    when "every_other_week" then from.advance(weeks: 2)
    when "monthly"          then from.advance(months: 1)
    when "yearly"           then from.advance(years: 1)
    end
  end

  # Return the dates of the transaction and its projected recurring
  # occurrences that fall within the given range. Only the next occurrence of
  # a recurring transaction is stored, so each later one is projected the same
  # way posting creates it.
  #
  # @param within [Range<Date>] The dates to include, which must have an end.
  # @return [Array<Date>] The occurrence dates.
  def occurrence_dates(within:)
    Enumerator.produce(date) { |current| next_recurring_date(from: current) }
              .take_while { |current| current && current <= within.end }
              .select { |current| within.cover?(current) }
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
