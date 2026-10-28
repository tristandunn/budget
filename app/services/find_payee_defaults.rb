# frozen_string_literal: true

class FindPayeeDefaults
  LATEST_COUNT = 3

  # Initialize the service.
  #
  # @param payee [Payee] The payee to find the defaults for.
  def initialize(payee:)
    @payee = payee
  end

  # Find the defaults to apply when the payee is selected on a transaction.
  #
  # @param payee [Payee] The payee to find the defaults for.
  # @return [Hash{Symbol => String, Array<String>}] The defaults to apply.
  def self.call(payee:)
    new(payee: payee).call
  end

  # Find the defaults to apply when the payee is selected on a transaction.
  #
  # The previous account, the most recent subcategory used, the subcategories
  # most often used, and the memo consistently used are included.
  #
  # @return [Hash{Symbol => String, Array<String>}] The defaults to apply.
  def call
    {
      account_id:                previous_account_id,
      memo:                      consistent_memo,
      subcategory_id:            previous_subcategory_id,
      suggested_subcategory_ids: payee.suggested_subcategory_ids
    }.deep_transform_values(&:to_s)
  end

  private

  attr_reader :payee

  # Return the memo shared by the payee's most recent transactions.
  #
  # A memo is only returned when the latest transactions all have the same
  # non-blank memo, so a one-off note is not suggested.
  #
  # @return [String] The consistently used memo.
  # @return [nil] When the memos differ, are blank, or there are too few transactions.
  def consistent_memo
    memos = latest_transactions.map(&:memo)

    if consistent_memo?(memos)
      memos.first.presence
    end
  end

  # Return whether `LATEST_COUNT` memos were found and they are all the same.
  #
  # @param memos [Array<String, nil>] The memos of the most recent transactions.
  # @return [Boolean] Whether enough memos were loaded and they match.
  def consistent_memo?(memos)
    memos.size == LATEST_COUNT && memos.uniq.one?
  end

  # Return the latest transactions, loaded with only the columns needed.
  #
  # @return [Array<Transaction>] The most recent transactions for the payee.
  def latest_transactions
    @latest_transactions ||= payee.transactions
                                  .reorder(date: :desc, id: :desc)
                                  .limit(LATEST_COUNT)
                                  .select(:account_id, :category_id, :memo)
                                  .to_a
  end

  # Return the account ID from the most recent transaction for the payee.
  #
  # @return [Integer] The most recent account ID.
  # @return [nil] When the payee has no transactions.
  def previous_account_id
    latest_transactions.first&.account_id
  end

  # Return the subcategory ID from the most recent categorized transaction among
  # the latest transactions.
  #
  # @return [Integer] The most recent subcategory ID.
  # @return [nil] When none of the latest transactions are categorized.
  def previous_subcategory_id
    latest_transactions.filter_map(&:category_id).first
  end
end
