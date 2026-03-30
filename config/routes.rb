# frozen_string_literal: true

Rails.application.routes.draw do
  resources :budgets, only: [:show] do
    get ":year/:month", action:      :show,
                        as:          :month,
                        constraints: { year: /\d{4}/, month: /\d{1,2}/ },
                        on:          :member

    resources :accounts, only: %i(index) do
      resources :transactions, only: %i(index), controller: "accounts/transactions"
    end
    resources :categories, only: [] do
      resource :assignment, only: %i(edit update)
    end
    resources :transactions, only: %i(index new create edit update destroy)
  end

  get "/health", to: "health#index"

  root "budgets#index"
end
