# frozen_string_literal: true

class AccountForm < BaseForm
  attr_accessor :account, :budget, :name
  attr_writer :credit

  validate :validate_account

  # Build a form prepopulated from an existing account.
  #
  # @param account [Account] The account to prepopulate from.
  # @return [AccountForm] The prepopulated form.
  def self.from(account:)
    new(
      account: account,
      budget:  account.budget,
      credit:  account.credit,
      name:    account.name
    )
  end

  # Return the credit value cast to a boolean.
  #
  # @return [Boolean, nil] The cast credit value.
  def credit
    ActiveModel::Type::Boolean.new.cast(@credit)
  end

  # Whether the underlying account has been persisted.
  #
  # @return [Boolean] Whether the account is persisted.
  def persisted?
    account&.persisted? || false
  end

  # Attempt to create the account if the form is valid.
  #
  # @return [Boolean] Whether the account was created successfully.
  def save
    self.account = budget.accounts.new(attributes)

    if valid?
      account.save!
    end
  end

  # Attempt to update the account if the form is valid.
  #
  # @return [Boolean] Whether the account was updated successfully.
  def update
    account.assign_attributes(attributes)

    if valid?
      ActiveRecord::Base.transaction do
        if account.name_changed?
          rename_transfer_payees
        end

        account.save!
      end
    end
  end

  private

  # Return the form attributes as a hash for assigning to the account.
  #
  # @return [Hash] The account attributes.
  def attributes
    { credit: credit, name: name }
  end

  # Rename a single direction's transfer payee to mirror the account's new name.
  # When a payee already uses the new name, the renamed payee is merged into it
  # instead so the uniqueness validation is not violated.
  #
  # @param direction [Symbol] The transfer direction.
  # @param old_name [String] The account's previous name.
  # @param new_name [String] The account's new name.
  # @return [void]
  def rename_transfer_payee(direction, old_name, new_name)
    payee = budget.payees.find_by(name: transfer_payee_name(direction, old_name))

    if payee
      renamed  = transfer_payee_name(direction, new_name)
      existing = budget.payees.find_by(name: renamed)

      if existing
        payee.merge_into(existing)
      else
        payee.update!(name: renamed)
      end
    end
  end

  # Rename the transfer payees that mirror this account's previous name so they
  # stay in sync rather than leaving stale payees behind.
  #
  # @return [void]
  def rename_transfer_payees
    old_name, new_name = account.changes[:name]

    %i(from to).each do |direction|
      rename_transfer_payee(direction, old_name, new_name)
    end
  end

  # Build the transfer payee name for a direction and account name.
  #
  # @param direction [Symbol] The transfer direction, :from or :to.
  # @param account_name [String] The account name to embed in the payee name.
  # @return [String] The translated transfer payee name.
  def transfer_payee_name(direction, account_name)
    I18n.t("transfers.payee.#{direction}", account: account_name)
  end

  # Validate the account, merging its errors into the form.
  #
  # @return [void]
  def validate_account
    if account.invalid?
      errors.merge!(account.errors)
    end
  end
end
