# frozen_string_literal: true

date = Date.current.beginning_of_month

Budget.first_or_create!.tap do |budget|
  checking = budget.accounts.find_or_create_by!(name: "Checking") do |account|
    account.balance = 250_000
  end

  savings = budget.accounts.find_or_create_by!(name: "Savings") do |account|
    account.balance = 100_000
  end

  united_club = budget.accounts.find_or_create_by!(name: "United Club") do |account|
    account.balance = -45_000
    account.credit  = true
  end

  budget.categories.find_or_create_by(name: Category::INFLOW, position: 0).tap do |parent|
    available_to_assign = parent.subcategories.find_or_create_by(budget: budget, name: Category::AVAILABLE_TO_ASSIGN,
                                                                 position: 0)

    budget.transactions.find_or_create_by!(account: checking, payee: "Opening Balance") do |transaction|
      transaction.subcategory = available_to_assign
      transaction.amount      = 350_000
      transaction.date        = date
    end
    budget.transactions.find_or_create_by!(account: savings, payee: "Opening Balance") do |transaction|
      transaction.subcategory = available_to_assign
      transaction.amount      = 100_000
      transaction.date        = date
    end
  end

  budget.categories.find_or_create_by(name: "Immediate Obligations", position: 1).tap do |parent|
    parent.snapshots.find_or_create_by!(budget: budget, date: date) do |snapshot|
      snapshot.amount_assigned = 112_500
      snapshot.amount_used     = 100_000
    end

    rent = parent.subcategories.find_or_create_by(budget: budget, name: "Rent", position: 0).tap do |category|
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

    budget.transactions.find_or_create_by!(account: checking, payee: "Landlord") do |transaction|
      transaction.subcategory = rent
      transaction.amount      = -100_000
      transaction.date        = date
    end
  end

  budget.categories.find_or_create_by(name: "Food & Drink", position: 2).tap do |parent|
    parent.snapshots.find_or_create_by!(budget: budget, date: date) do |snapshot|
      snapshot.amount_assigned = 45_000
      snapshot.amount_used     = 45_000
    end

    groceries = parent.subcategories.find_or_create_by(budget: budget, name: "Groceries",
                                                       position: 0).tap do |category|
      category.snapshots.find_or_create_by!(budget: budget, date: date) do |snapshot|
        snapshot.amount_assigned = 30_000
        snapshot.amount_used     = 27_500
      end
    end

    dining_out = parent.subcategories.find_or_create_by(budget: budget, name: "Dining Out",
                                                        position: 1).tap do |category|
      category.snapshots.find_or_create_by!(budget: budget, date: date) do |snapshot|
        snapshot.amount_assigned = 15_000
        snapshot.amount_used     = 17_500
      end
    end

    budget.transactions.find_or_create_by!(account: united_club, payee: "Whole Foods") do |transaction|
      transaction.subcategory = groceries
      transaction.amount      = -27_500
      transaction.date        = date
    end
    budget.transactions.find_or_create_by!(account: united_club, payee: "Olive Garden") do |transaction|
      transaction.subcategory = dining_out
      transaction.amount      = -17_500
      transaction.date        = date
    end
  end

  budget.update!(available_to_assign: 292_500)
end
