# frozen_string_literal: true

require "rails_helper"

describe SessionForm, type: :form do
  describe "class" do
    it "inherits from the base form" do
      expect(described_class.superclass).to eq(BaseForm)
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }

    it { is_expected.to validate_presence_of(:password) }
  end

  describe "#initialize" do
    subject(:form) { described_class.new(email: email, password: password) }

    let(:email)    { generate(:email) }
    let(:password) { generate(:password) }

    it "assigns the e-mail" do
      expect(form.email).to eq(email)
    end

    it "assigns the password" do
      expect(form.password).to eq(password)
    end
  end

  describe "#user" do
    subject(:form) { described_class.new(email: email, password: password) }

    let(:user) { create(:user, password: password) }

    context "with a valid user and password" do
      let(:email)    { user.email }
      let(:password) { generate(:password) }

      it "returns the user" do
        expect(form.user).to eq(user)
      end
    end

    context "with an unknown user" do
      let(:email)    { generate(:email) }
      let(:password) { generate(:password) }

      it "returns nil" do
        expect(form.user).to be_nil
      end
    end

    context "with a blank e-mail" do
      let(:email)    { "" }
      let(:password) { generate(:password) }

      it "returns nil" do
        expect(form.user).to be_nil
      end
    end

    context "with an oddly formatted e-mail" do
      let(:email)    { "  #{user.email.upcase}  " }
      let(:password) { generate(:password) }

      it "returns the user" do
        expect(form.user).to eq(user)
      end
    end
  end

  describe "#valid?" do
    subject(:valid?) { form.valid? }

    let(:form) { described_class.new(email: generate(:email), password: generate(:password)) }

    context "with a user" do
      let(:user) { create(:user) }

      before do
        allow(form).to receive(:user).and_return(user)
      end

      it "is valid" do
        expect(valid?).to be(true)
      end

      it "does not add errors" do
        valid?

        expect(form.errors).to be_empty
      end
    end

    context "without a user" do
      before do
        allow(form).to receive(:user).and_return(nil)
      end

      it "is not valid" do
        expect(valid?).to be(false)
      end

      it "adds an error message for e-mail" do
        valid?

        expect(form.errors[:email]).to eq(
          [t("activemodel.errors.models.session_form.attributes.email.unknown")]
        )
      end
    end
  end
end
