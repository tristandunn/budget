# frozen_string_literal: true

class CalculateAmount
  EXPRESSION         = %r{\A(?<left>[+-]?[\d.]+)(?:(?<operator>[-+*/])(?<right>[\d.]+)?)?\z}
  INVALID_CHARACTERS = %r{[^\d.+*/-]}

  # Initialize the service with a sanitized expression.
  #
  # @param expression [String, nil] The expression to calculate.
  def initialize(expression)
    @expression = expression.to_s.gsub(INVALID_CHARACTERS, "")
  end

  # Calculate the amount for an expression with at most one operation.
  #
  # @param expression [String, nil] The expression to calculate.
  # @return [Money] The calculated amount.
  # @return [nil] When the expression is not a supported amount.
  def self.call(expression)
    new(expression).call
  end

  # Calculate the amount for an expression with at most one operation.
  #
  # @return [Money] The calculated amount.
  # @return [nil] When the expression is not a supported amount.
  def call
    match = EXPRESSION.match(expression)

    if match
      evaluate(match[:left].to_d, match[:operator], match[:right].to_d)
    end
  end

  private

  attr_reader :expression

  # Calculate the amount from the operands.
  #
  # @param left [BigDecimal] The left operand.
  # @param operator [String, nil] The operator to apply.
  # @param right [BigDecimal] The right operand.
  # @return [Money] The calculated amount.
  def evaluate(left, operator, right)
    if right.zero?
      Money.from_amount(left)
    else
      Money.from_amount(operate(left, operator, right))
    end
  end

  # Apply the operator to the operands, defaulting to subtraction.
  #
  # @param left [BigDecimal] The left operand.
  # @param operator [String, nil] The operator to apply.
  # @param right [BigDecimal] The right operand.
  # @return [BigDecimal] The result of the operation.
  def operate(left, operator, right)
    case operator
    when "+"
      left + right
    when "*"
      left * right
    when "/"
      left / right
    else
      left - right
    end
  end
end
