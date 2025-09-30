# Validates portfolio balance API request parameters
# Assumptions: empty portfolios are valid, only CLP/PEN/COP supported
class PortfolioValidator
  SUPPORTED_CURRENCIES = %w[CLP PEN COP].freeze

  def initialize(params)
    @params = params
    @errors = []
  end

  def valid?
    validate_required_fields
    validate_fiat_currency
    @errors.empty?
  end

  def errors
    @errors
  end

  private

  def validate_required_fields
    @errors << "portfolio parameter is required" unless @params.key?(:portfolio)
    @errors << "fiat_currency parameter is required" if @params[:fiat_currency].blank?
  end

  def validate_fiat_currency
    return if @params[:fiat_currency].blank?

    unless SUPPORTED_CURRENCIES.include?(@params[:fiat_currency])
      @errors << "fiat_currency must be one of: #{SUPPORTED_CURRENCIES.join(', ')}"
    end
  end
end
