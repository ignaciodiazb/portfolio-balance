class BudaApiClient
  include HTTParty

  base_uri "https://www.buda.com/api/v2"

  def fetch_tickers
    response = self.class.get("/tickers")

    if response.success?
      { data: response.parsed_response["tickers"], success: true }
    else
      Rails.logger.error "Buda API error: #{response.code} - #{response.message}"
      { details: response.message, error: "API unavailable", success: false }
    end
  rescue => e
    Rails.logger.error "Buda API network error: #{e.message}"
    { details: e.message, error: "Network error", success: false }
  end
end
