# frozen_string_literal: true

require "rails_helper"

describe BudgetsController, type: :routing do
  it { is_expected.to route(:get, "/").to(action: :index) }
  it { is_expected.to route(:get, "/budgets/1").to(action: :show, id: 1) }
end
