# frozen_string_literal: true

Budget.first_or_create!.tap do |budget|
  budget.categories.find_or_create_by(name: "Immediate Obligations", position: 0).tap do |parent|
    parent.subcategories.find_or_create_by(budget: budget, name: "Rent", position: 0)
    parent.subcategories.find_or_create_by(budget: budget, name: "Water", position: 1)
    parent.subcategories.find_or_create_by(budget: budget, name: "Phone", position: 2)
  end

  budget.categories.find_or_create_by(name: "Food & Drink", position: 1).tap do |parent|
    parent.subcategories.find_or_create_by(budget: budget, name: "Groceries", position: 0)
    parent.subcategories.find_or_create_by(budget: budget, name: "Dining Out", position: 1)
  end
end
