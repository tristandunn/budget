# frozen_string_literal: true

module Transactions
  class SummariesController < ApplicationController
    # Render the summary for the selected transactions.
    def show
      @summary = TransactionSummary.new(current_budget, ids: params.expect(ids: []))
    end
  end
end
