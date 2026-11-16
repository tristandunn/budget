# frozen_string_literal: true

require "rails_helper"

describe PasswordForm, type: :form do
  let(:confirmation)     { new_password }
  let(:current_password) { "old-password" }
  let(:new_password)     { "new-password" }
  let(:user)             { create(:user, password: "old-password") }

  let(:attributes) do
    {
      user:                  user,
      current_password:      current_password,
      password:              new_password,
      password_confirmation: confirmation
    }
  end

  describe "class" do
    it "inherits from the base form" do
      expect(described_class.superclass).to eq(BaseForm)
    end
  end

  describe "#save" do
    subject(:form) { described_class.new(**attributes) }

    it "changes the password" do
      form.save

      expect(user.reload.authenticate(new_password)).to be_truthy
    end

    it "returns true" do
      expect(form.save).to be(true)
    end

    context "when invalid" do
      let(:current_password) { "wrong" }

      it "returns false" do
        expect(form.save).to be_falsey
      end

      it "does not change the password" do
        form.save

        expect(user.reload.authenticate("old-password")).to be_truthy
      end
    end
  end

  describe "#valid?" do
    subject(:form) { described_class.new(**attributes) }

    it { is_expected.to be_valid }

    context "with an incorrect current password" do
      let(:current_password) { "wrong" }

      it "adds an error to the current password" do
        form.valid?

        expect(form.errors[:current_password]).to eq(
          [t("activemodel.errors.models.password_form.attributes.current_password.incorrect")]
        )
      end
    end

    context "with a blank current password" do
      let(:current_password) { "" }

      it "adds a blank error to the current password" do
        form.valid?

        expect(form.errors[:current_password]).to include(t("errors.messages.blank"))
      end
    end

    context "with a short password" do
      let(:new_password) { "short" }

      it "adds an error to the password" do
        form.valid?

        expect(form.errors[:password]).to eq(
          [t("errors.messages.too_short.other", count: User::MINIMUM_PASSWORD_LENGTH)]
        )
      end
    end

    context "with a password that is too long" do
      let(:new_password) { "a" * (User::MAXIMUM_PASSWORD_LENGTH + 1) }

      it "adds an error to the password" do
        form.valid?

        expect(form.errors[:password]).to eq(
          [t("errors.messages.too_long.other", count: User::MAXIMUM_PASSWORD_LENGTH)]
        )
      end
    end

    context "with a password of the maximum length" do
      let(:new_password) { "a" * User::MAXIMUM_PASSWORD_LENGTH }

      it { is_expected.to be_valid }
    end

    context "with a mismatched confirmation" do
      let(:confirmation) { "different-password" }

      it "adds an error to the confirmation" do
        form.valid?

        expect(form.errors[:password_confirmation]).to eq(
          [t("activemodel.errors.models.password_form.attributes.password_confirmation.confirmation")]
        )
      end
    end
  end
end
