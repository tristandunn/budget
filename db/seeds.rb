# frozen_string_literal: true

date = Date.current.beginning_of_month

Budget.first_or_create!.tap do |budget|
  budget.categories.find_or_create_by(name: "Immediate Obligations", position: 0).tap do |parent|
    parent.snapshots.find_or_create_by!(budget: budget, date: date) do |snapshot|
      snapshot.amount_assigned = 1125
    end

    parent.subcategories.find_or_create_by(budget: budget, name: "Rent", position: 0).tap do |category|
      category.snapshots.find_or_create_by!(budget: budget, date: date) do |snapshot|
        snapshot.amount_assigned = 1000
        snapshot.amount_used     = 1000
      end
    end
    parent.subcategories.find_or_create_by(budget: budget, name: "Water", position: 1).tap do |category|
      category.snapshots.find_or_create_by!(budget: budget, date: date) do |snapshot|
        snapshot.amount_assigned = 50
      end
    end
    parent.subcategories.find_or_create_by(budget: budget, name: "Phone", position: 2).tap do |category|
      category.snapshots.find_or_create_by!(budget: budget, date: date) do |snapshot|
        snapshot.amount_assigned = 75
      end
    end
  end

  budget.categories.find_or_create_by(name: "Food & Drink", position: 1).tap do |parent|
    parent.snapshots.find_or_create_by!(budget: budget, date: date) do |snapshot|
      snapshot.amount_assigned = 450
    end

    parent.subcategories.find_or_create_by(budget: budget, name: "Groceries", position: 0).tap do |category|
      category.snapshots.find_or_create_by!(budget: budget, date: date) do |snapshot|
        snapshot.amount_assigned = 300
      end
    end
    parent.subcategories.find_or_create_by(budget: budget, name: "Dining Out", position: 1).tap do |category|
      category.snapshots.find_or_create_by!(budget: budget, date: date) do |snapshot|
        snapshot.amount_assigned = 150
        snapshot.amount_used     = 175
      end
    end
  end
end
