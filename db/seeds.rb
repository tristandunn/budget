# frozen_string_literal: true

class BudgetSeeder
  # Initialize the seeder.
  #
  # @param budget [Budget] The budget to seed records into.
  def initialize(budget)
    @budget = budget
  end

  # Derive the account balances and available to assign from the records that
  # were created, so neither has to be maintained by hand.
  #
  # @return [void]
  def recalculate!
    budget.accounts.each do |account|
      account.update!(balance: account.transactions.where.not(status: :upcoming).sum(:amount))
    end

    budget.update!(available_to_assign: inflow - assigned)
  end

  # Find or create a transaction, keyed on the account, payee, and frequency so
  # an actual occurrence and its recurring template stay distinct. The remaining
  # attributes, including the date as on, are passed through.
  #
  # @return [Transaction] The found or created transaction.
  def record(account:, payee:, frequency: nil, **attributes)
    budget.transactions.find_or_create_by!(account: account, payee: payee, frequency: frequency) do |transaction|
      transaction.amount      = attributes[:amount]
      transaction.date        = attributes[:on]
      transaction.status      = attributes.fetch(:status, :pending)
      transaction.subcategory = attributes[:subcategory]
    end
  end

  # Build a parent category's snapshots by summing the subcategory snapshots
  # already created for each month.
  #
  # @return [void]
  def rollup(parent)
    totals = parent.subcategories
                   .joins(:snapshots)
                   .group("category_snapshots.date")
                   .pluck(
                     "category_snapshots.date",
                     "SUM(category_snapshots.amount_assigned)",
                     "SUM(category_snapshots.amount_used)"
                   )

    totals.each do |on, assigned, used|
      parent.snapshots.find_or_create_by!(budget: budget, date: on) do |category_snapshot|
        category_snapshot.amount_assigned = assigned
        category_snapshot.amount_used     = used
      end
    end
  end

  # Find or create a category snapshot for a month.
  #
  # @return [CategorySnapshot] The found or created snapshot.
  def snapshot(category, assigned:, on:, used: 0)
    category.snapshots.find_or_create_by!(budget: budget, date: on) do |category_snapshot|
      category_snapshot.amount_assigned = assigned
      category_snapshot.amount_used     = used
    end
  end

  private

  attr_reader :budget

  # The total assigned across every subcategory snapshot.
  #
  # @return [Integer] The assigned amount in cents.
  def assigned
    budget.category_snapshots
          .joins(:category)
          .where.not(categories: { parent_id: nil })
          .sum(:amount_assigned)
  end

  # The total inflow that is not upcoming.
  #
  # @return [Integer] The inflow amount in cents.
  def inflow
    budget.transactions
          .where.not(status: :upcoming)
          .joins(:subcategory)
          .where(categories: { name: Category::AVAILABLE_TO_ASSIGN })
          .sum(:amount)
  end
end

date      = Date.current.beginning_of_month
next_date = date.next_month

user = User.find_or_create_by!(email: "user@example.com") do |new_user|
  new_user.password = "password"
end

budget = user.budgets.first || Budget.create!(users: [user])
seeder = BudgetSeeder.new(budget)

checking    = budget.accounts.find_or_create_by!(name: "Checking")
savings     = budget.accounts.find_or_create_by!(name: "Savings")
united_club = budget.accounts.find_or_create_by!(name: "United Club") do |account|
  account.credit = true
end

amazon         = budget.payees.find_or_create_by!(name: "Amazon")
capital_grille = budget.payees.find_or_create_by!(name: "The Capital Grille")
costco         = budget.payees.find_or_create_by!(name: "Costco")
electric       = budget.payees.find_or_create_by!(name: "Electric Company")
employer       = budget.payees.find_or_create_by!(name: "Employer")
landlord       = budget.payees.find_or_create_by!(name: "Landlord")
netflix        = budget.payees.find_or_create_by!(name: "Netflix")
opening        = budget.payees.find_or_create_by!(name: "Opening Balance")
water_utility  = budget.payees.find_or_create_by!(name: "Water Utility")

budget.categories.find_or_create_by(name: Category::INFLOW, position: 0).tap do |parent|
  available_to_assign = parent.subcategories.find_or_create_by(budget: budget, name: Category::AVAILABLE_TO_ASSIGN,
                                                               position: 0)

  seeder.record(account: checking, payee: opening, subcategory: available_to_assign,
                amount: 350_000, on: date, status: :reconciled)
  seeder.record(account: savings, payee: opening, subcategory: available_to_assign,
                amount: 100_000, on: date, status: :reconciled)

  seeder.record(account: checking, payee: employer, subcategory: available_to_assign,
                amount: 200_000, on: date + 12, status: :cleared)
  seeder.record(account: checking, payee: employer, subcategory: available_to_assign,
                amount: 200_000, on: date + 26, status: :upcoming, frequency: :every_other_week)
end

budget.categories.find_or_create_by(name: "Immediate Obligations", position: 1).tap do |parent|
  rent = parent.subcategories.find_or_create_by(budget: budget, name: "Rent", position: 0) do |category|
    category.target_type   = :monthly_spending
    category.target_amount = 100_000
  end

  seeder.snapshot(rent, on: date, assigned: 100_000, used: 100_000)
  seeder.snapshot(rent, on: next_date, assigned: 100_000)

  water = parent.subcategories.find_or_create_by(budget: budget, name: "Water", position: 1) do |category|
    category.target_type   = :monthly_spending
    category.target_amount = 5_000
  end

  seeder.snapshot(water, on: date, assigned: 5_000)

  phone = parent.subcategories.find_or_create_by(budget: budget, name: "Phone", position: 2) do |category|
    category.target_type   = :monthly_spending
    category.target_amount = 7_500
  end

  seeder.snapshot(phone, on: date, assigned: 7_500)

  electric_category = parent.subcategories.find_or_create_by(budget: budget, name: "Electric",
                                                             position: 3) do |category|
    category.target_type   = :monthly_spending
    category.target_amount = 9_000
  end

  seeder.snapshot(electric_category, on: date, assigned: 9_000, used: 8_500)

  seeder.record(account: checking, payee: landlord, subcategory: rent,
                amount: -100_000, on: date + 1, status: :reconciled)
  seeder.record(account: checking, payee: landlord, subcategory: rent,
                amount: -100_000, on: next_date + 1, status: :upcoming, frequency: :monthly)

  seeder.record(account: united_club, payee: electric, subcategory: electric_category,
                amount: -8_500, on: date + 9, status: :pending)

  seeder.record(account: united_club, payee: water_utility, subcategory: water,
                amount: -5_000, on: date + 20, status: :upcoming)

  seeder.rollup(parent)
end

budget.categories.find_or_create_by(name: "Food & Drink", position: 2).tap do |parent|
  groceries = parent.subcategories.find_or_create_by(budget: budget, name: "Groceries", position: 0) do |category|
    category.target_type   = :monthly_spending
    category.target_amount = 30_000
  end

  seeder.snapshot(groceries, on: date, assigned: 30_000, used: 27_500)

  dining_out = parent.subcategories.find_or_create_by(budget: budget, name: "Dining Out", position: 1)

  seeder.snapshot(dining_out, on: date, assigned: 15_000, used: 17_500)

  seeder.record(account: united_club, payee: costco, subcategory: groceries,
                amount: -27_500, on: date + 5, status: :cleared)
  seeder.record(account: united_club, payee: capital_grille, subcategory: dining_out,
                amount: -17_500, on: date + 8)

  seeder.rollup(parent)
end

budget.categories.find_or_create_by(name: "Quality of Life", position: 3).tap do |parent|
  fun_money = parent.subcategories.find_or_create_by(budget: budget, name: "Fun Money", position: 0)

  seeder.snapshot(fun_money, on: date, assigned: 10_000, used: 6_000)

  netflix_category = parent.subcategories.find_or_create_by(budget: budget, name: "Netflix", position: 1) do |category|
    category.target_type   = :monthly_spending
    category.target_amount = 1_500
  end

  seeder.snapshot(netflix_category, on: date, assigned: 1_500, used: 1_500)

  vacation = parent.subcategories.find_or_create_by(budget: budget, name: "Vacation", position: 2) do |category|
    category.target_type   = :monthly_savings
    category.target_amount = 25_000
  end

  seeder.snapshot(vacation, on: date, assigned: 25_000)
  seeder.snapshot(vacation, on: next_date, assigned: 25_000)

  seeder.record(account: united_club, payee: amazon, subcategory: fun_money,
                amount: -6_000, on: date + 11, status: :reconciled)

  seeder.record(account: united_club, payee: netflix, subcategory: netflix_category,
                amount: -1_500, on: date + 7, status: :pending)
  seeder.record(account: united_club, payee: netflix, subcategory: netflix_category,
                amount: -1_500, on: next_date + 7, status: :upcoming, frequency: :monthly)

  seeder.rollup(parent)
end

seeder.recalculate!
