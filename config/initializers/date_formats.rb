# frozen_string_literal: true

Date::DATE_FORMATS[:full_date_ordinal] = lambda do |date|
  I18n.l(date, format: :full_date_ordinal).sub("{day}", date.day.ordinalize)
end
