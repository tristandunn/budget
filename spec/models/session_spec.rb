# frozen_string_literal: true

require "rails_helper"

describe Session do
  describe "class" do
    it { is_expected.to be_a(ApplicationRecord) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user).optional(false) }
  end

  describe "secure token" do
    it { is_expected.to have_secure_token(:token) }
  end
end
