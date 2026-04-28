# frozen_string_literal: true

class AccountForm < BaseForm
  attr_accessor :account, :budget, :name
  attr_writer :credit

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
      account.save!
    end
  end

  private

  # Return the form attributes as a hash for assigning to the account.
  #
  # @return [Hash] The account attributes.
  def attributes
    { credit: credit, name: name }
  end

  # Validate the account, merging errors into the form.
  #
  # @return [Boolean] Whether the account is valid.
  def valid?(context = nil)
    account.valid?(context).tap do
      errors.merge!(account.errors)
    end
  end
end
