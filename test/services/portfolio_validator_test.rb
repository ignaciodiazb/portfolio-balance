require "test_helper"

class PortfolioValidatorTest < ActiveSupport::TestCase
  test "valid with portfolio and supported fiat currency" do
    params = { portfolio: { "BTC" => 0.5 }, fiat_currency: "CLP" }
    validator = PortfolioValidator.new(params)

    assert validator.valid?
    assert_empty validator.errors
  end

  test "valid with empty portfolio and supported fiat currency" do
    params = { portfolio: {}, fiat_currency: "PEN" }
    validator = PortfolioValidator.new(params)

    assert validator.valid?
    assert_empty validator.errors
  end

  test "invalid when portfolio parameter is missing" do
    params = { fiat_currency: "CLP" }
    validator = PortfolioValidator.new(params)

    assert_not validator.valid?
    assert_includes validator.errors, "portfolio parameter is required"
  end

  test "invalid when fiat_currency parameter is missing" do
    params = { portfolio: { "BTC" => 0.5 } }
    validator = PortfolioValidator.new(params)

    assert_not validator.valid?
    assert_includes validator.errors, "fiat_currency parameter is required"
  end

  test "invalid when fiat_currency is blank" do
    params = { portfolio: { "BTC" => 0.5 }, fiat_currency: "" }
    validator = PortfolioValidator.new(params)

    assert_not validator.valid?
    assert_includes validator.errors, "fiat_currency parameter is required"
  end

  test "invalid when fiat_currency is nil" do
    params = { portfolio: { "BTC" => 0.5 }, fiat_currency: nil }
    validator = PortfolioValidator.new(params)

    assert_not validator.valid?
    assert_includes validator.errors, "fiat_currency parameter is required"
  end

  test "invalid for unsupported fiat currency" do
    params = { portfolio: { "BTC" => 0.5 }, fiat_currency: "USD" }
    validator = PortfolioValidator.new(params)

    assert_not validator.valid?
    assert_includes validator.errors, "fiat_currency must be one of: CLP, PEN, COP"
  end

  test "valid for all supported currencies" do
    PortfolioValidator::SUPPORTED_CURRENCIES.each do |currency|
      params = { portfolio: { "BTC" => 0.5 }, fiat_currency: currency }
      validator = PortfolioValidator.new(params)

      assert validator.valid?, "Expected #{currency} to be valid"
      assert_empty validator.errors
    end
  end

  test "multiple validation errors are collected" do
    params = { fiat_currency: "USD" }  # Missing portfolio, invalid currency
    validator = PortfolioValidator.new(params)

    assert_not validator.valid?
    assert_includes validator.errors, "portfolio parameter is required"
    assert_includes validator.errors, "fiat_currency must be one of: CLP, PEN, COP"
    assert_equal 2, validator.errors.size
  end
end
