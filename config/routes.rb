# frozen_string_literal: true

Rails.application.routes.draw do
  resources :budgets, only: [:show] do
    resources :accounts, only: %i(index)
    resources :categories, only: [] do
      resource :assignment, only: %i(edit update)
    end
    resources :transactions, only: %i(index new create)
  end

  get "/health", to: "health#index"

  root "budgets#index"
end
