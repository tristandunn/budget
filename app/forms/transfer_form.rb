# frozen_string_literal: true

class TransferForm < BaseForm
  attr_accessor :amount, :budget, :from_account, :memo, :to_account
  attr_writer   :date

  validates :amount,       presence: true, numericality: { allow_blank: true, greater_than: 0 }
  validates :from_account, presence: true
  validates :to_account,   presence: true

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
  # @return [Boolean] Whether the transfer was created successfully.
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

  # Validate that the source and destination accounts differ.
  #
  # @return [void]
  def validate_distinct_accounts
    if accounts_match?
      errors.add(:to_account, :must_not_match_source)
    end
  end
end
