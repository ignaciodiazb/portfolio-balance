class PortfolioService
  def initialize(portfolio)
    @buda_client = BudaApiClient.new
    @portfolio = portfolio
  end

  def calculate_balance(fiat_currency)
    return { data: empty_balance(fiat_currency), success: true } if @portfolio.empty?

    # Fetch current market prices from Buda API
    tickers_result = @buda_client.fetch_tickers

    unless tickers_result[:success]
      return { details: tickers_result[:details], error: tickers_result[:error], success: false }
    end

    tickers = tickers_result[:data]
    tickers_by_market = tickers.index_by { |ticker| ticker["market_id"] }

    breakdown = []
    total_value = 0.0

    @portfolio.each do |currency, quantity|
      market_id = "#{currency}-#{fiat_currency}"
      ticker = tickers_by_market[market_id]

      if ticker
        price = ticker["last_price"][0].to_f
        value = price * quantity
        breakdown << {
          currency: currency,
          price: price,
          quantity: quantity,
          value: value
        }
        total_value += value
      else
        breakdown << {
          currency: currency,
          error: "No market data available for #{market_id}",
          price: nil,
          quantity: quantity,
          value: nil
        }
      end
    end

    {
      data: {
        breakdown: breakdown,
        calculated_at: Time.current.iso8601,
        currency: fiat_currency,
        total_value: total_value
      },
      success: true
    }
  end

  private

  def empty_balance(fiat_currency)
    {
      breakdown: [],
      calculated_at: Time.current.iso8601,
      currency: fiat_currency,
      total_value: 0.0
    }
  end
end
