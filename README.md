# Portfolio Balance API

A Ruby on Rails API for calculating cryptocurrency portfolio values using real-time market prices from Buda.com.

## Overview

This API accepts a cryptocurrency portfolio (assets and quantities) along with a target fiat currency, and returns the total portfolio value and detailed breakdown using current market prices.

## Quick Start

### Prerequisites

- Ruby 3.3+
- Rails 8.0+
- Internet connection (for Buda.com API)

### Setup

```bash
git clone git@github.com:ignaciodiazb/portfolio-balance.git
cd portfolio-balance
bundle install
bin/rails server
```

API available at: `http://localhost:3000`

### Basic Usage

```bash
curl -X POST http://localhost:3000/api/v1/portfolios/balance \
  -H "Content-Type: application/json" \
  -d '{
    "portfolio": {
      "BTC": 0.5,
      "ETH": 2.0,
      "USDT": 1000
    },
    "fiat_currency": "CLP"
  }'
```

## API Endpoint

### POST /api/v1/portfolios/balance

Calculate total portfolio value in specified fiat currency.

**Request Body:**

```json
{
  "portfolio": {
    "BTC": 0.5,
    "ETH": 2.0
  },
  "fiat_currency": "CLP"
}
```

**Success Response (200):**

```json
{
  "total_value": 25000000.0,
  "currency": "CLP",
  "calculated_at": "2025-09-30T10:30:00Z",
  "breakdown": [
    {
      "currency": "BTC",
      "quantity": 0.5,
      "price": 40000000.0,
      "value": 20000000.0
    },
    {
      "currency": "ETH",
      "quantity": 2.0,
      "price": 2500000.0,
      "value": 5000000.0
    }
  ]
}
```

**Error Response (400):**

```json
{
  "errors": [
    "portfolio parameter is required",
    "fiat_currency must be one of: CLP, PEN, COP"
  ]
}
```

## Key Assumptions

### Business Logic

- **Empty portfolios are valid** - Returns zero balance, useful for API testing
- **Missing market data is non-fatal** - Individual assets without prices show errors but calculation continues
- **Zero quantities included** - All requested assets appear in breakdown for transparency
- **Current prices only** - No caching, always uses live Buda.com data

### Technical Constraints

- **Supported currencies**: CLP, PEN, COP (Buda.com availability)
- **Market format**: Uses Buda.com market IDs (e.g., \"BTC-CLP\")
- **Price format**: Buda.com returns `["price_string", "currency"]`
- **Parameter validation**: Both `portfolio` and `fiat_currency` required

## Testing

```bash
# Run all tests
bin/rails test

# Run specific test suites
bin/rails test test/controllers/
bin/rails test test/services/
```

**Test Coverage:**

- Controller integration tests
- Service unit tests with mocked external API
- Validator unit tests
- Error handling scenarios

## Architecture

- **Controller**: Handles HTTP requests, parameter validation
- **Validator**: Request parameter validation logic
- **Service**: Business logic for balance calculations
- **Client**: Buda.com API integration

## Deployment

Configured for deployment with Kamal. See `config/deploy.yml`.

## Error Codes

- `200` - Successful calculation
- `400` - Bad request (validation errors)
- `503` - Service unavailable (external API errors)"
