# frozen_string_literal: true

Rails.application.config.session_store(
  :cookie_store,
  expire_after: 30.days,
  key:          "_budgeting_session"
)
