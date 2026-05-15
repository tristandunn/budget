# frozen_string_literal: true

require "rails_helper"

describe User do
  it { is_expected.to be_a(ApplicationRecord) }

  describe "validations" do
    subject(:user) { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to allow_value("MrBoB@example.com").for(:email) }
    it { is_expected.not_to allow_value("@.com").for(:email) }

    it { is_expected.to validate_presence_of(:password).allow_blank }

    it "limits the e-mail to the maximum length" do
      expect(user).to validate_length_of(:email)
        .is_at_most(described_class::MAXIMUM_EMAIL_LENGTH)
    end

    it "requires the password to meet the minimum length" do
      expect(user).to validate_length_of(:password)
        .is_at_least(described_class::MINIMUM_PASSWORD_LENGTH)
    end
  end

  describe "normalizations" do
    subject(:user) { create(:user, email: "  AN@EXAMPLE.COM  ") }

    it "downcases and strips e-mail" do
      expect(user.email).to eq("an@example.com")
    end
  end
end
