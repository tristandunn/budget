# frozen_string_literal: true

class PayeeForm < BaseForm
  attr_accessor :name, :payee

  # Build a form prepopulated from an existing payee.
  #
  # @param payee [Payee] The payee to prepopulate from.
  # @return [PayeeForm] The prepopulated form.
  def self.from(payee:)
    new(payee: payee, name: payee.name)
  end

  # Attempt to rename or merge the payee if the form is valid.
  #
  # When the new name matches another payee in the same budget, merge the
  # payees by reassigning the renamed payee's transactions and destroying it.
  # Otherwise, rename the payee in place.
  #
  # @return [Boolean] Whether the rename succeeded.
  def update
    if duplicate_payee
      merge
    else
      payee.assign_attributes(name: name)

      if valid?
        payee.save!
      end
    end
  end

  private

  # Return the other payee in the budget that already has the requested name.
  #
  # @return [Payee] The other payee with a matching name.
  # @return [nil] When no other payee has a matching name.
  def duplicate_payee
    @duplicate_payee ||= if name.present?
                           payee.budget.payees.where.not(id: payee.id).find_by(name: name)
                         end
  end

  # Reassign all of the payee's transactions to the existing payee, then
  # destroy the renamed payee.
  #
  # @return [Payee] The destroyed payee.
  def merge
    Payee.transaction do
      payee.transactions.find_each do |transaction|
        transaction.update!(payee: duplicate_payee)
      end

      payee.destroy!
    end
  end

  # Validate the payee, merging errors into the form.
  #
  # @return [Boolean] Whether the payee is valid.
  def valid?(context = nil)
    payee.valid?(context).tap do
      errors.merge!(payee.errors)
    end
  end
end
