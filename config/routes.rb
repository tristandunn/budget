# frozen_string_literal: true

Rails.application.routes.draw do
  resources :budgets, only: [:show] do
    get ":year/:month", action:      :show,
                        as:          :month,
                        constraints: { year: /\d{4}/, month: /\d{1,2}/ },
                        on:          :member

    resources :accounts, only: %i(index) do
      resources :transactions, only: %i(index), controller: "accounts/transactions"
      resource :reconciliation, only: %i(create), controller: "accounts/reconciliations"
    end
    resources :categories, only: %i(edit update) do
      resource :assignment, only: %i(edit update)
    end
    resources :transactions, only: %i(index new create edit update destroy) do
      member do
        patch  "clear", action: :clear
        delete "clear", action: :unclear
      end
    end
  end

  get "/health", to: "health#index"

  root "budgets#index"
end
