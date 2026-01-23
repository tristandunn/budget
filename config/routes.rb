# frozen_string_literal: true

Rails.application.routes.draw do
  resources :budgets, only: [:show]

  get "/health", to: "health#index"

  root "budgets#index"
end
