# frozen_string_literal: true

require "rails_helper"

describe FindPayeeDefaults do
  describe ".call" do
    subject(:defaults) { described_class.call(payee: payee) }

    let(:budget) { create(:budget) }
    let(:payee)  { create(:payee, budget: budget) }

    context "when the payee has no transactions" do
      it "returns blank values" do
        expect(defaults).to eq(
          account_id:                "",
          memo:                      "",
          subcategory_id:            "",
          suggested_subcategory_ids: []
        )
      end
    end

    context "when the payee has transactions" do
      let(:account)     { create(:account, budget: budget) }
      let(:subcategory) { create(:category, :subcategory, budget: budget) }

      before do
        create_list(:transaction, 3,
                    account:     account,
                    budget:      budget,
                    payee:       payee,
                    subcategory: subcategory,
                    memo:        "Coffee.")
      end

      it "returns the account, memo, subcategory, and suggested subcategory IDs as strings" do
        expect(defaults).to eq(
          account_id:                account.id.to_s,
          memo:                      "Coffee.",
          subcategory_id:            subcategory.id.to_s,
          suggested_subcategory_ids: [subcategory.id.to_s]
        )
      end
    end

    describe "account_id" do
      it "uses the most recent account" do
        older = create(:account, budget: budget)
        newer = create(:account, budget: budget)

        create(:transaction, account: older, budget: budget, payee: payee, date: 5.days.ago)
        create(:transaction, account: newer, budget: budget, payee: payee, date: 1.day.ago)

        expect(defaults[:account_id]).to eq(newer.id.to_s)
      end

      it "breaks ties on the same date by the most recent transaction ID" do
        older = create(:account, budget: budget)
        newer = create(:account, budget: budget)

        create(:transaction, account: older, budget: budget, payee: payee, date: Date.current)
        create(:transaction, account: newer, budget: budget, payee: payee, date: Date.current)

        expect(defaults[:account_id]).to eq(newer.id.to_s)
      end
    end

    describe "memo" do
      it "is blank when there are too few transactions" do
        create_list(:transaction, 2, budget: budget, payee: payee, memo: "Coffee.")

        expect(defaults[:memo]).to eq("")
      end

      it "is blank when the recent memos differ" do
        create_list(:transaction, 2, budget: budget, payee: payee, memo: "Coffee.")
        create(:transaction, budget: budget, payee: payee, memo: "Tea.")

        expect(defaults[:memo]).to eq("")
      end

      it "is blank when the shared memo is blank" do
        create_list(:transaction, 3, budget: budget, payee: payee, memo: "")

        expect(defaults[:memo]).to eq("")
      end

      it "only considers the most recent transactions" do
        create(:transaction, budget: budget, payee: payee, date: 10.days.ago, memo: "Old")
        create_list(:transaction, 3, budget: budget, payee: payee, date: 1.day.ago, memo: "Coffee.")

        expect(defaults[:memo]).to eq("Coffee.")
      end
    end

    describe "subcategory_id" do
      it "is blank when the payee's only transactions have no subcategory" do
        create(:transaction, budget: budget, payee: payee, subcategory: nil)

        expect(defaults[:subcategory_id]).to eq("")
      end

      it "uses the most recent categorized subcategory" do
        older = create(:category, :subcategory, budget: budget)
        newer = create(:category, :subcategory, budget: budget)

        create(:transaction, budget: budget, payee: payee, subcategory: older, date: 5.days.ago)
        create(:transaction, budget: budget, payee: payee, subcategory: newer, date: 1.day.ago)

        expect(defaults[:subcategory_id]).to eq(newer.id.to_s)
      end

      it "breaks ties on the same date by the most recent transaction ID" do
        older = create(:category, :subcategory, budget: budget)
        newer = create(:category, :subcategory, budget: budget)

        create(:transaction, budget: budget, payee: payee, subcategory: older, date: Date.current)
        create(:transaction, budget: budget, payee: payee, subcategory: newer, date: Date.current)

        expect(defaults[:subcategory_id]).to eq(newer.id.to_s)
      end

      it "skips uncategorized transactions when finding the most recent" do
        categorized = create(:category, :subcategory, budget: budget)

        create(:transaction, budget: budget, payee: payee, subcategory: categorized, date: 5.days.ago)
        create(:transaction, budget: budget, payee: payee, subcategory: nil, date: 1.day.ago)

        expect(defaults[:subcategory_id]).to eq(categorized.id.to_s)
      end
    end
  end
end
