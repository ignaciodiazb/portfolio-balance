class Api::V1::PortfoliosController < ApplicationController
  # Disable Rails parameter wrapping to prevent automatic nesting
  # (avoids portfolio: {fiat_currency: "CLP"} when sending only fiat_currency)
  wrap_parameters false

  def balance
    validator = PortfolioValidator.new(params)

    unless validator.valid?
      render json: { errors: validator.errors }, status: :bad_request
      return
    end

    portfolio = params[:portfolio]
    fiat_currency = params[:fiat_currency]

    service = PortfolioService.new(portfolio)
    result = service.calculate_balance(fiat_currency)

    if result[:success]
      render json: result[:data]
    else
      render json: { error: "Unable to fetch market data", details: result[:error] }, status: :service_unavailable
    end
  end
end
