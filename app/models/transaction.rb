# frozen_string_literal: true

class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :budget
  belongs_to :payee
  belongs_to :subcategory, class_name:  "Category",
                           foreign_key: :category_id,
                           inverse_of:  :transactions

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

  default_scope -> { order(date: :desc, created_at: :desc) }

  scope :activation_due, -> { upcoming.where(date: ..Date.current) }

  # Returns the attributes to copy when creating a new occurrence.
  #
  # @return [Hash]
  def copyable_attributes
    attributes.symbolize_keys.slice(:account_id, :amount, :budget_id, :category_id, :memo, :payee_id)
  end

  # Returns the date for the next recurring occurrence.
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

  # Returns true if the transaction has a frequency and a future date. This is
  # distinct from the upcoming status, which is set explicitly.
  #
  # @return [Boolean]
  def recurring_scheduled?
    frequency.present? && scheduled?
  end

  # Returns true if the transaction date is in the future.
  #
  # @return [Boolean]
  def scheduled?
    date.future?
  end

  private

  # Validate that the subcategory is a subcategory.
  #
  # @return [void]
  def validate_subcategory
    if subcategory&.parent.blank?
      errors.add(:subcategory, :not_a_subcategory)
    end
  end
end
