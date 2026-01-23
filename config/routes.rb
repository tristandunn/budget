# frozen_string_literal: true

Rails.application.routes.draw do
  resources :budgets, only: [:show] do
    resources :transactions, only: %i(new create)
  end

  get "/health", to: "health#index"

  root "budgets#index"
end
