# API Documentation

## Portfolio Balance Endpoint

### POST /api/v1/portfolios/balance

Calculate the total value of a cryptocurrency portfolio using real-time market prices.

## Request Format

### Headers

```
Content-Type: application/json
```

### Body Parameters

| Parameter       | Type   | Required | Description                          |
| --------------- | ------ | -------- | ------------------------------------ |
| `portfolio`     | Object | Yes      | Cryptocurrency assets and quantities |
| `fiat_currency` | String | Yes      | Target currency (CLP, PEN, or COP)   |

### Portfolio Object Format

The portfolio object contains cryptocurrency symbols as keys and quantities as values:

```json
{
  "portfolio": {
    "BTC": 0.5,
    "ETH": 2.0,
    "USDT": 1000,
    "ADA": 500
  },
  "fiat_currency": "CLP"
}
```

**Important Notes:**

- Portfolio can be empty `{}` (returns zero balance)
- Quantities must be positive numbers
- Asset symbols should match Buda.com supported assets
- Zero quantities are accepted and included in breakdown

## Response Format

### Success Response (HTTP 200)

```json
{
  "total_value": 45000000.0,
  "currency": "CLP",
  "calculated_at": "2025-09-30T10:30:15Z",
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
    },
    {
      "currency": "USDT",
      "quantity": 1000,
      "price": 1000.0,
      "value": 1000000.0
    },
    {
      "currency": "ADA",
      "quantity": 500,
      "error": "No market data available for ADA-CLP",
      "price": null,
      "value": null
    }
  ]
}
```

### Error Response (HTTP 400)

```json
{
  "errors": [
    "portfolio parameter is required",
    "fiat_currency parameter is required"
  ]
}
```

### Service Error Response (HTTP 503)

```json
{
  "error": "Unable to fetch market data",
  "details": "Connection timeout to Buda.com API"
}
```

## Example Requests

### 1. Standard Portfolio

**Request:**

```bash
curl -X POST http://localhost:3000/api/v1/portfolios/balance \
  -H "Content-Type: application/json" \
  -d '{
    "portfolio": {
      "BTC": 0.5,
      "ETH": 2.0
    },
    "fiat_currency": "CLP"
  }'
```

**Response:**

```json
{
  "total_value": 25000000.0,
  "currency": "CLP",
  "calculated_at": "2025-09-30T10:30:15Z",
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

### 2. Empty Portfolio

**Request:**

```bash
curl -X POST http://localhost:3000/api/v1/portfolios/balance \
  -H "Content-Type: application/json" \
  -d '{
    "portfolio": {},
    "fiat_currency": "PEN"
  }'
```

**Response:**

```json
{
  "total_value": 0.0,
  "currency": "PEN",
  "calculated_at": "2025-09-30T10:30:15Z",
  "breakdown": []
}
```

### 3. Missing Parameters

**Request:**

```bash
curl -X POST http://localhost:3000/api/v1/portfolios/balance \
  -H "Content-Type: application/json" \
  -d '{
    "fiat_currency": "CLP"
  }'
```

**Response:**

```json
{
  "errors": ["portfolio parameter is required"]
}
```

### 4. Invalid Currency

**Request:**

```bash
curl -X POST http://localhost:3000/api/v1/portfolios/balance \
  -H "Content-Type: application/json" \
  -d '{
    "portfolio": {"BTC": 1.0},
    "fiat_currency": "USD"
  }'
```

**Response:**

```json
{
  "errors": ["fiat_currency must be one of: CLP, PEN, COP"]
}
```

## Supported Currencies

Currently supported fiat currencies based on Buda.com market availability:

- **CLP** - Chilean Peso
- **PEN** - Peruvian Sol
- **COP** - Colombian Peso

## Error Handling

The API handles various error scenarios gracefully:

1. **Missing market data** - Individual assets show error, calculation continues
2. **External API failure** - Returns 503 with error details
3. **Invalid parameters** - Returns 400 with validation errors
4. **Network timeouts** - Returns 503 with timeout message

## Implementation Notes

- Built with Rails 8.0 API mode
- Uses Minitest for testing with external API mocking
- Follows Rails conventions for JSON APIs
- Parameter wrapping disabled to avoid nested parameter issues
- Comprehensive test coverage for all scenarios
