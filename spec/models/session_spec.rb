# frozen_string_literal: true

require "rails_helper"

describe Session do
  describe "class" do
    it { is_expected.to be_a(ApplicationRecord) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user).optional(false) }
  end

  describe "#revoke_others" do
    subject(:revoke_others) { session.revoke_others }

    let(:session) { create(:session) }

    it "destroys the other sessions of the user" do
      other = create(:session, user: session.user)

      revoke_others

      expect(described_class).not_to exist(other.id)
    end

    it "keeps the session" do
      revoke_others

      expect(described_class).to exist(session.id)
    end

    it "keeps the sessions of other users" do
      other = create(:session)

      revoke_others

      expect(described_class).to exist(other.id)
    end
  end

  describe "secure token" do
    it { is_expected.to have_secure_token(:token) }
  end
end
