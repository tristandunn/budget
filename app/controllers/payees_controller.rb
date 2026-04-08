# frozen_string_literal: true

class PayeesController < ApplicationController
  # Render payee names ordered by most recent transaction date.
  def index
    render json: payees.map(&:name)
  end

  private

  # Return the budget for the given `budget_id` parameter.
  #
  # @return [Budget] The requested budget.
  def budget
    @budget ||= Budget.find(params[:budget_id])
  end

  # Return payees for the budget ordered by most recent transaction date.
  #
  # @return [ActiveRecord::Relation] The payees ordered by recency.
  def payees
    budget.payees
          .select("payees.name, MAX(transactions.date) AS last_used_on")
          .left_joins(:transactions)
          .group("payees.id")
          .order(Arel.sql("last_used_on DESC, payees.name ASC"))
          .limit(25)
  end
end
