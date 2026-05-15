# frozen_string_literal: true

Rails.application.routes.draw do
  resources :budgets, only: [:show] do
    get ":year/:month", action:      :show,
                        as:          :month,
                        constraints: { year: /\d{4}/, month: /\d{1,2}/ },
                        on:          :member

    resources :accounts, only: %i(index new create edit update destroy) do
      resources :transactions, only: %i(index), controller: "accounts/transactions"
      resource :reconciliation, only: %i(create), controller: "accounts/reconciliations"
    end
    resources :categories, only: %i(show edit update) do
      resource :assignment, only: %i(edit update)
      resource :snooze, only: %i(create destroy)
      resource :target, only: %i(edit update destroy)
    end
    resources :payees, only: %i(index edit update) do
      member do
        get :previous_category
      end
    end
    resource :settings, only: :update
    resources :transactions, only: %i(index new create edit update destroy) do
      member do
        patch  "clear", action: :clear
        delete "clear", action: :unclear
      end
    end
    resources :transfers, only: %i(new create)
  end

  resource :session, only: %i(new create destroy)

  get "/health", to: "health#index"
  get "/manifest", to:          "rails/pwa#manifest",
                   as:          :pwa_manifest,
                   constraints: { format: :json }

  root "budgets#index"
end
