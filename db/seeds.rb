# frozen_string_literal: true

date = Date.current.beginning_of_month

Budget.first_or_create!.tap do |budget|
  budget.accounts.find_or_create_by!(name: "Checking") do |account|
    account.balance = 250_000
  end
  budget.accounts.find_or_create_by!(name: "Savings") do |account|
    account.balance = 1_000_000
  end
  budget.accounts.find_or_create_by!(name: "United Club") do |account|
    account.balance = -45_000
    account.credit  = true
  end

  budget.categories.find_or_create_by(name: "Immediate Obligations", position: 0).tap do |parent|
    parent.snapshots.find_or_create_by!(budget: budget, date: date) do |snapshot|
      snapshot.amount_assigned = 112_500
      snapshot.amount_used     = 100_000
    end

    parent.subcategories.find_or_create_by(budget: budget, name: "Rent", position: 0).tap do |category|
      category.snapshots.find_or_create_by!(budget: budget, date: date) do |snapshot|
        snapshot.amount_assigned = 100_000
        snapshot.amount_used     = 100_000
      end
    end
    parent.subcategories.find_or_create_by(budget: budget, name: "Water", position: 1).tap do |category|
      category.snapshots.find_or_create_by!(budget: budget, date: date) do |snapshot|
        snapshot.amount_assigned = 5_000
      end
    end
    parent.subcategories.find_or_create_by(budget: budget, name: "Phone", position: 2).tap do |category|
      category.snapshots.find_or_create_by!(budget: budget, date: date) do |snapshot|
        snapshot.amount_assigned = 7_500
      end
    end
  end

  budget.categories.find_or_create_by(name: "Food & Drink", position: 1).tap do |parent|
    parent.snapshots.find_or_create_by!(budget: budget, date: date) do |snapshot|
      snapshot.amount_assigned = 45_000
      snapshot.amount_used     = 17_500
    end

    parent.subcategories.find_or_create_by(budget: budget, name: "Groceries", position: 0).tap do |category|
      category.snapshots.find_or_create_by!(budget: budget, date: date) do |snapshot|
        snapshot.amount_assigned = 30_000
      end
    end
    parent.subcategories.find_or_create_by(budget: budget, name: "Dining Out", position: 1).tap do |category|
      category.snapshots.find_or_create_by!(budget: budget, date: date) do |snapshot|
        snapshot.amount_assigned = 15_000
        snapshot.amount_used     = 17_500
      end
    end
  end
end
