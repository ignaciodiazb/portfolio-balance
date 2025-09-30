require "test_helper"

class PortfolioServiceTest < ActiveSupport::TestCase
  def setup
    @portfolio = { "BTC" => 0.5, "ETH" => 2.0 }
    @service = PortfolioService.new(@portfolio)
  end

  test "returns empty balance for empty portfolio" do
    empty_service = PortfolioService.new({})
    result = empty_service.calculate_balance("CLP")

    assert result[:success]
    assert_equal 0.0, result[:data][:total_value]
    assert_equal "CLP", result[:data][:currency]
    assert_empty result[:data][:breakdown]
  end

  test "calculates balance successfully with valid API response" do
    # Mock successful API response
    mock_tickers = [
      {
        "market_id" => "BTC-CLP",
        "last_price" => [ "40000000.0", "CLP" ]
      },
      {
        "market_id" => "ETH-CLP",
        "last_price" => [ "2500000.0", "CLP" ]
      }
    ]

    BudaApiClient.any_instance.stubs(:fetch_tickers).returns({
      success: true,
      data: mock_tickers
    })

    result = @service.calculate_balance("CLP")

    assert result[:success]
    assert_equal 25000000.0, result[:data][:total_value] # (0.5 * 40M) + (2.0 * 2.5M) = 20M + 5M
    assert_equal "CLP", result[:data][:currency]
    assert_equal 2, result[:data][:breakdown].size

    # Check BTC breakdown
    btc_breakdown = result[:data][:breakdown].find { |item| item[:currency] == "BTC" }
    assert_equal 0.5, btc_breakdown[:quantity]
    assert_equal 40000000.0, btc_breakdown[:price]
    assert_equal 20000000.0, btc_breakdown[:value]

    # Check ETH breakdown
    eth_breakdown = result[:data][:breakdown].find { |item| item[:currency] == "ETH" }
    assert_equal 2.0, eth_breakdown[:quantity]
    assert_equal 2500000.0, eth_breakdown[:price]
    assert_equal 5000000.0, eth_breakdown[:value]
  end

  test "handles missing market data gracefully" do
    # Mock API response missing some markets
    mock_tickers = [
      {
        "market_id" => "BTC-CLP",
        "last_price" => [ "40000000.0", "CLP" ]
      }
      # Missing ETH-CLP
    ]

    BudaApiClient.any_instance.stubs(:fetch_tickers).returns({
      success: true,
      data: mock_tickers
    })

    result = @service.calculate_balance("CLP")

    assert result[:success]
    assert_equal 20000000.0, result[:data][:total_value] # Only BTC value
    assert_equal 2, result[:data][:breakdown].size # BTC + ETH (with error)

    # Check BTC is calculated correctly
    btc_breakdown = result[:data][:breakdown].find { |item| item[:currency] == "BTC" }
    assert_equal "BTC", btc_breakdown[:currency]
    assert_equal 20000000.0, btc_breakdown[:value]

    # Check ETH has error entry
    eth_breakdown = result[:data][:breakdown].find { |item| item[:currency] == "ETH" }
    assert_equal "ETH", eth_breakdown[:currency]
    assert_nil eth_breakdown[:value]
    assert_includes eth_breakdown[:error], "No market data available"
  end

  test "returns error when API call fails" do
    BudaApiClient.any_instance.stubs(:fetch_tickers).returns({
      success: false,
      error: "Network error",
      details: "Connection timeout"
    })

    result = @service.calculate_balance("CLP")

    assert_not result[:success]
    assert_equal "Network error", result[:error]
    assert_equal "Connection timeout", result[:details]
  end

  test "handles zero quantities correctly" do
    portfolio_with_zero = { "BTC" => 0.0, "ETH" => 2.0 }
    service = PortfolioService.new(portfolio_with_zero)

    mock_tickers = [
      {
        "market_id" => "BTC-CLP",
        "last_price" => [ "40000000.0", "CLP" ]
      },
      {
        "market_id" => "ETH-CLP",
        "last_price" => [ "2500000.0", "CLP" ]
      }
    ]

    BudaApiClient.any_instance.stubs(:fetch_tickers).returns({
      success: true,
      data: mock_tickers
    })

    result = service.calculate_balance("CLP")

    assert result[:success]
    assert_equal 5000000.0, result[:data][:total_value] # Only ETH value (2.0 * 2.5M)

    # Should still include BTC in breakdown but with zero value
    btc_breakdown = result[:data][:breakdown].find { |item| item[:currency] == "BTC" }
    assert_equal 0.0, btc_breakdown[:quantity]
    assert_equal 0.0, btc_breakdown[:value]
  end

  test "works with different fiat currencies" do
    mock_tickers = [
      {
        "market_id" => "BTC-PEN",
        "last_price" => [ "150000.0", "PEN" ]
      }
    ]

    BudaApiClient.any_instance.stubs(:fetch_tickers).returns({
      success: true,
      data: mock_tickers
    })

    btc_only_service = PortfolioService.new({ "BTC" => 1.0 })
    result = btc_only_service.calculate_balance("PEN")

    assert result[:success]
    assert_equal 150000.0, result[:data][:total_value]
    assert_equal "PEN", result[:data][:currency]
  end
end
