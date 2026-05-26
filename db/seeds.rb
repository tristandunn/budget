# frozen_string_literal: true

date = Date.current.beginning_of_month
user = User.find_or_create_by!(email: "user@example.com") do |new_user|
  new_user.password = "password"
end

budget = user.budgets.first || Budget.create!(users: [user])

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

capital_grille = budget.payees.find_or_create_by!(name: "The Capital Grille")
costco         = budget.payees.find_or_create_by!(name: "Costco")
landlord       = budget.payees.find_or_create_by!(name: "Landlord")
opening        = budget.payees.find_or_create_by!(name: "Opening Balance")

budget.categories.find_or_create_by(name: Category::INFLOW, position: 0).tap do |parent|
  available_to_assign = parent.subcategories.find_or_create_by(budget: budget, name: Category::AVAILABLE_TO_ASSIGN,
                                                               position: 0)

  budget.transactions.find_or_create_by!(account: checking, payee: opening) do |transaction|
    transaction.subcategory = available_to_assign
    transaction.amount      = 350_000
    transaction.date        = date
    transaction.status      = :reconciled
  end
  budget.transactions.find_or_create_by!(account: savings, payee: opening) do |transaction|
    transaction.subcategory = available_to_assign
    transaction.amount      = 100_000
    transaction.date        = date
    transaction.status      = :reconciled
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

  budget.transactions.find_or_create_by!(account: checking, payee: landlord) do |transaction|
    transaction.subcategory = rent
    transaction.amount      = -100_000
    transaction.date        = date + 1
    transaction.status      = :reconciled
  end

  budget.transactions.find_or_create_by!(account: checking, payee: landlord, frequency: :monthly) do |transaction|
    transaction.subcategory = rent
    transaction.amount      = -100_000
    transaction.date        = (date + 1).advance(months: 1)
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

  budget.transactions.find_or_create_by!(account: united_club, payee: costco) do |transaction|
    transaction.subcategory = groceries
    transaction.amount      = -27_500
    transaction.date        = date + 5
    transaction.status      = :cleared
  end
  budget.transactions.find_or_create_by!(account: united_club, payee: capital_grille) do |transaction|
    transaction.subcategory = dining_out
    transaction.amount      = -17_500
    transaction.date        = date + 8
  end
end

budget.update!(available_to_assign: 292_500)
