# Sales Reports API

## Endpoint

```
GET /api/reports/sales
```

## Authentication

Requires authenticated user (Bearer token).

## Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `start_date` | string (YYYY-MM-DD) | No | Filter orders from this date |
| `end_date` | string (YYYY-MM-DD) | No | Filter orders until this date |
| `dealer_id` | integer | No | Filter by specific dealer/user |
| `product_id` | integer | No | Filter by specific product |
| `format` | string | No | Response format: `json` (default) or `csv` |

## Response Formats

### JSON Response

```json
{
  "success": true,
  "data": {
    "summary": {
      "total_revenue_cents": 350000,
      "total_revenue_formatted": "$3,500.00",
      "total_quantity": 25,
      "orders_count": 10
    },
    "breakdown": [
      {
        "product_id": 1,
        "product_title": "Premium Widget",
        "product_sku": "WIDGET-001",
        "revenue_cents": 200000,
        "revenue_formatted": "$2,000.00",
        "quantity": 15,
        "orders_count": 7,
        "avg_price_cents": 13333,
        "avg_price_formatted": "$133.33"
      },
      {
        "product_id": 2,
        "product_title": "Standard Gadget",
        "product_sku": "GADGET-002",
        "revenue_cents": 150000,
        "revenue_formatted": "$1,500.00",
        "quantity": 10,
        "orders_count": 5,
        "avg_price_cents": 15000,
        "avg_price_formatted": "$150.00"
      }
    ],
    "filters_applied": {
      "start_date": "2025-10-01",
      "end_date": "2025-10-10",
      "dealer_id": null,
      "product_id": null
    },
    "generated_at": "2025-10-10T12:30:00Z"
  },
  "meta": {
    "total_products": 2,
    "currency": "USD"
  }
}
```

### CSV Response

When `format=csv` is specified, returns a downloadable CSV file with headers:

```csv
Product ID,Product Title,SKU,Quantity Sold,Revenue (cents),Revenue (formatted),Orders Count,Avg Price (cents),Avg Price (formatted)
1,Premium Widget,WIDGET-001,15,200000,$2000.00,7,13333,$133.33
2,Standard Gadget,GADGET-002,10,150000,$1500.00,5,15000,$150.00

TOTAL,,,25,350000,$3500.00,10,,
```

The CSV file will be downloaded with filename: `sales_report_YYYYMMDD.csv`

## Examples

### Get all sales (JSON)
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "https://api.example.com/api/reports/sales"
```

### Filter by date range (JSON)
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "https://api.example.com/api/reports/sales?start_date=2025-10-01&end_date=2025-10-10"
```

### Filter by dealer
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "https://api.example.com/api/reports/sales?dealer_id=123"
```

### Download CSV report
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "https://api.example.com/api/reports/sales?format=csv" \
  -o sales_report.csv
```

### Combined filters with CSV
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "https://api.example.com/api/reports/sales?start_date=2025-10-01&end_date=2025-10-10&dealer_id=123&format=csv" \
  -o sales_report_filtered.csv
```

## Error Responses

### Invalid Date Format
```json
{
  "error": "Invalid start_date format. Use YYYY-MM-DD"
}
```
Status: 400 Bad Request

### Invalid Date Range
```json
{
  "error": "start_date cannot be after end_date"
}
```
Status: 400 Bad Request

### Unauthorized
```json
{
  "error": "You need to sign in or sign up before continuing."
}
```
Status: 401 Unauthorized

## Performance Notes

### Indexes
The following indexes are used to optimize report queries:
- `index_orders_on_status_and_created_at` - For filtering orders by status and date
- `index_order_items_on_order_and_product` - For aggregating order items
- `index_orders_on_user_status_date` - For dealer-specific reports

### Materialized Views (Future Optimization)

For very large datasets with frequent report queries, consider implementing a materialized view:

```sql
CREATE MATERIALIZED VIEW sales_summary AS
SELECT 
  DATE(orders.created_at) as sale_date,
  products.id as product_id,
  products.title as product_title,
  products.sku as product_sku,
  SUM(order_items.total_cents) as revenue_cents,
  SUM(order_items.quantity) as quantity,
  COUNT(DISTINCT orders.id) as orders_count,
  AVG(order_items.price_cents) as avg_price_cents
FROM orders
JOIN order_items ON order_items.order_id = orders.id
JOIN products ON products.id = order_items.product_id
WHERE orders.status IN ('paid', 'shipped')
GROUP BY DATE(orders.created_at), products.id, products.title, products.sku;

CREATE INDEX ON sales_summary (sale_date);
CREATE INDEX ON sales_summary (product_id);
```

Refresh the view periodically (e.g., nightly via cron job):
```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY sales_summary;
```

Benefits:
- Pre-aggregated data for instant report generation
- Reduces load on production tables
- Concurrent refresh allows queries during refresh
- Can be scheduled during low-traffic periods

## Business Logic

- Only includes orders with status `paid` or `shipped`
- Revenue is calculated from `order_items.total_cents`
- Quantity is sum of `order_items.quantity`
- Orders count is distinct order IDs
- Average price is calculated per product across all orders
- All monetary values are in cents, with formatted versions provided
- Currency is currently fixed to USD (configurable for multi-currency support)

## Data Retention

- Real-time data (queries live tables)
- Historical data available based on database retention policy
- For archival reports, consider exporting to data warehouse
