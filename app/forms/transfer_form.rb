# frozen_string_literal: true

class TransferForm < BaseForm
  attr_accessor :amount, :budget, :from_account, :memo, :to_account
  attr_writer   :date

  validates :amount,       presence: true, numericality: { allow_blank: true, greater_than: 0 }
  validates :from_account, presence: true
  validates :to_account,   presence: true

  validate :validate_account_kinds
  validate :validate_date
  validate :validate_distinct_accounts

  # Return the date, defaulting to today when blank or unparseable.
  #
  # @return [Date] The parsed date.
  def date
    Date.parse(@date.to_s)
  rescue Date::Error
    Date.current
  end

  # Attempt to create the transfer if the form is valid.
  #
  # @return [Boolean] When the form is valid and the transfer is created.
  # @return [nil] When the form is invalid.
  def save
    if valid?
      call_create_transfer
    end
  end

  private

  # Return whether both accounts are present and refer to the same record.
  #
  # @return [Boolean] Whether the accounts match.
  def accounts_match?
    from_account.present? && from_account == to_account
  end

  # Call the transfer service with the form's parsed attributes.
  #
  # @return [Boolean] The transfer service's return value.
  def call_create_transfer
    CreateTransfer.call(
      accounts: { from: from_account, to: to_account },
      amount:   Money.from_amount(BigDecimal(amount.to_s)),
      budget:   budget,
      date:     date,
      memo:     memo.presence
    )
  end

  # Return whether the source account is present and is a credit account.
  #
  # @return [Boolean] Whether the source account is the wrong kind.
  def from_account_invalid_kind?
    from_account.present? && from_account.credit?
  end

  # Return whether the destination account is present and is not a credit account.
  #
  # @return [Boolean] Whether the destination account is the wrong kind.
  def to_account_invalid_kind?
    to_account.present? && !to_account.credit?
  end

  # Validate that the source is a cash account and the destination is a credit account.
  #
  # @return [void]
  def validate_account_kinds
    if from_account_invalid_kind?
      errors.add(:from_account, :must_be_cash)
    end

    if to_account_invalid_kind?
      errors.add(:to_account, :must_be_credit)
    end
  end

  # Validate that the date is not in the future.
  #
  # @return [void]
  def validate_date
    if date.future?
      errors.add(:date, :in_the_future)
    end
  end

  # Validate that the source and destination accounts differ.
  #
  # @return [void]
  def validate_distinct_accounts
    if accounts_match?
      errors.add(:to_account, :must_not_match_source)
    end
  end
end
