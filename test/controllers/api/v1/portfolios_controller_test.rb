require "test_helper"

class Api::V1::PortfoliosControllerTest < ActionDispatch::IntegrationTest
  test "successful balance calculation with valid portfolio" do
    portfolio_data = { "BTC" => 0.5, "ETH" => 2.0 }

    # Mock successful service response
    PortfolioService.any_instance.stubs(:calculate_balance).returns({
      success: true,
      data: {
        total_value: 25000000.0,
        currency: "CLP",
        breakdown: [
          { currency: "BTC", quantity: 0.5, price: 40000000.0, value: 20000000.0 },
          { currency: "ETH", quantity: 2.0, price: 2500000.0, value: 5000000.0 }
        ]
      }
    })

    post "/api/v1/portfolios/balance",
         params: { portfolio: portfolio_data, fiat_currency: "CLP" },
         as: :json

    assert_response :success
    assert_equal "application/json; charset=utf-8", response.content_type

    json_response = JSON.parse(response.body)
    assert_equal 25000000.0, json_response["total_value"]
    assert_equal "CLP", json_response["currency"]
    assert_equal 2, json_response["breakdown"].size
  end

  test "successful balance calculation with empty portfolio" do
    PortfolioService.any_instance.stubs(:calculate_balance).returns({
      success: true,
      data: { total_value: 0.0, currency: "CLP", breakdown: [] }
    })

    post "/api/v1/portfolios/balance",
         params: { portfolio: {}, fiat_currency: "CLP" },
         as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 0.0, json_response["total_value"]
  end

  test "returns bad_request when portfolio parameter is missing" do
    post "/api/v1/portfolios/balance",
         params: { fiat_currency: "CLP" },
         as: :json

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "portfolio parameter is required"
  end

  test "returns bad_request when fiat_currency parameter is missing" do
    post "/api/v1/portfolios/balance",
         params: { portfolio: { "BTC" => 0.5 } },
         as: :json

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "fiat_currency parameter is required"
  end

  test "returns bad_request for unsupported fiat currency" do
    post "/api/v1/portfolios/balance",
         params: { portfolio: { "BTC" => 0.5 }, fiat_currency: "USD" },
         as: :json

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "fiat_currency must be one of: CLP, PEN, COP"
  end

  test "returns service_unavailable when external API fails" do
    PortfolioService.any_instance.stubs(:calculate_balance).returns({
      success: false,
      error: "API connection failed"
    })

    post "/api/v1/portfolios/balance",
         params: { portfolio: { "BTC" => 0.5 }, fiat_currency: "CLP" },
         as: :json

    assert_response :service_unavailable
    json_response = JSON.parse(response.body)
    assert_equal "Unable to fetch market data", json_response["error"]
    assert_equal "API connection failed", json_response["details"]
  end
end
