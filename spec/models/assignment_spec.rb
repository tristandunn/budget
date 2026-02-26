# frozen_string_literal: true

require "rails_helper"

describe Assignment do
  it { is_expected.to be_a(ActiveModel::Model) }

  describe "validations" do
    it { is_expected.to validate_numericality_of(:amount).only_integer }
  end
end
