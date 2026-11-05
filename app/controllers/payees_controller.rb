# frozen_string_literal: true

class PayeesController < ApplicationController
  # Render the list of payees in the budget.
  def index
    @budget = current_budget
    @payees = payees
  end

  # Render the payee edit form.
  def edit
    @budget = current_budget
    @payee  = payee
    @form   = PayeeForm.from(payee: payee)
  end

  # Update the payee, renaming or hiding it, or merging it into an
  # existing payee.
  def update
    @budget = current_budget
    @payee  = payee
    @form   = PayeeForm.new(payee: payee, **form_parameters)

    if @form.update
      if request.format.turbo_stream?
        @payees = payees
      else
        redirect_to budget_payees_path(current_budget), status: :see_other
      end
    else
      render :edit, status: :unprocessable_content, formats: [:html]
    end
  end

  # Render the defaults to apply when the payee is selected on a transaction:
  # the previous account, the most recent subcategory used, the
  # subcategories most often used, and the memo consistently used.
  def defaults
    render json: FindPayeeDefaults.call(payee: payee)
  end

  private

  # Return the permitted form parameters.
  #
  # @return [Hash] The permitted parameters for the form.
  def form_parameters
    params.expect(payee_form: %i(hidden name)).to_h.symbolize_keys
  end

  # Return the payee for the given `id` parameter, scoped to the budget and
  # excluding transfer payees, which are managed by the transfers themselves.
  #
  # @return [Payee] The requested payee.
  def payee
    @payee ||= payees.find(params.expect(:id))
  end

  # Return the budget's payees ordered by name, excluding transfer payees.
  #
  # @return [ActiveRecord::Relation] The payees that can be managed.
  def payees
    current_budget.payees.without_transfers.order(:name)
  end
end
