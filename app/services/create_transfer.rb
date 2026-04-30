# frozen_string_literal: true

class CreateTransfer
  # Initialize the service.
  #
  # @param accounts [Hash{Symbol => Account}] The :from and :to accounts.
  # @param amount [Money] The amount being transferred.
  # @param budget [Budget] The budget the transfer belongs to.
  # @param date [Date] The transfer date applied to both rows.
  # @param memo [String, nil] An optional memo applied to both rows.
  def initialize(accounts:, amount:, budget:, date:, memo: nil)
    @from_account = accounts.fetch(:from)
    @to_account   = accounts.fetch(:to)
    @amount       = amount
    @budget       = budget
    @date         = date
    @memo         = memo
  end

  # Create the paired transactions and update both account balances.
  #
  # @param accounts [Hash{Symbol => Account}] The :from and :to accounts.
  # @param amount [Money] The amount being transferred.
  # @param budget [Budget] The budget the transfer belongs to.
  # @param date [Date] The transfer date applied to both rows.
  # @param memo [String, nil] An optional memo applied to both rows.
  # @return [Boolean] Whether the transfer was created successfully.
  def self.call(accounts:, amount:, budget:, date:, memo: nil)
    new(accounts: accounts, amount: amount, budget: budget, date: date, memo: memo).call
  end

  # Create the paired transactions and update both account balances.
  #
  # @return [Boolean] Whether the transfer was created successfully.
  def call
    ActiveRecord::Base.transaction do
      outflow = build_outflow
      outflow.save!

      inflow = build_inflow
      inflow.save!

      link_pair(outflow, inflow)

      from_account.increment!(:balance, -amount.cents)
      to_account.increment!(:balance,    amount.cents)
    end

    true
  end

  private

  attr_reader :amount, :budget, :date, :from_account, :memo, :to_account

  # Build the inflow row credited to the destination account.
  #
  # @return [Transaction] The destination-side transaction.
  def build_inflow
    Transaction.new(
      account: to_account,
      amount:  amount.cents,
      budget:  budget,
      date:    date,
      memo:    memo,
      payee:   payee_for(from_account)
    )
  end

  # Build the outflow row debited from the source account.
  #
  # @return [Transaction] The source-side transaction.
  def build_outflow
    Transaction.new(
      account: from_account,
      amount:  -amount.cents,
      budget:  budget,
      date:    date,
      memo:    memo,
      payee:   payee_for(to_account)
    )
  end

  # Link the two transactions to each other via transfer_pair_id.
  #
  # @param outflow [Transaction] The source-side transaction.
  # @param inflow [Transaction] The destination-side transaction.
  # @return [void]
  def link_pair(outflow, inflow)
    outflow.update!(transfer_pair: inflow)
    inflow.update!(transfer_pair: outflow)
  end

  # Find or create the payee for a transfer counterpart account.
  #
  # @param account [Account] The counterpart account whose name labels the payee.
  # @return [Payee] The found or created payee record.
  def payee_for(account)
    Payee.find_or_create_by!(
      budget: budget,
      name:   I18n.t("transfers.payee.name", account: account.name)
    )
  end
end
