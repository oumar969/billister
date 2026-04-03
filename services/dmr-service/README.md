# Danish Motor Registry (DMR) Lookup Service

REST API service for looking up Danish vehicle information from license plates.

Uses **dmr.py** to scrape motorregister.skat.dk directly.

## Setup

### Prerequisites

- Python 3.8+
- pip

### Installation

```bash
cd services/dmr-service
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### Run

```bash
python app.py
```

Service will start on `http://localhost:5000`

## API Endpoints

### Health Check

```
GET /health
```

Returns service status and DMR availability.

### Lookup Vehicle

```
POST /api/vehicles/lookup
Content-Type: application/json

{
  "plate": "AB12345"
}
```

**Response:** (200 OK)

```json
{
  "success": true,
  "data": {
    "make": "Toyota",
    "model": "Yaris",
    "year": 2018,
    "fuel_type": "Benzin",
    "transmission": "Manuel",
    "kilometers": 87000,
    "engine_size": "1200cc",
    "co2_emissions": 120,
    "euro_standard": "Euro 6b",
    "color": "Sort",
    ...
  },
  "lookup_time_ms": 3200,
  "cached": false,
  "plate": "AB12345",
  "timestamp": "2026-04-03T10:30:45.123456"
}
```

**Errors:**

- 400: Invalid plate format
- 404: Vehicle not found
- 503: DMR service unavailable

### Validate Plate

```
POST /api/vehicles/validate-plate
Content-Type: application/json

{
  "plate": "AB12345"
}
```

Validates format only (no lookup).

### Test Data

```
GET /api/test-data
```

Returns example license plates for testing.

## Important Notes

⏱️ **Response Time:** 3-4 seconds per lookup (due to skat.dk database)

💾 **Caching:** The .NET backend caches results in its database to avoid repeated lookups

🔧 **Maintenance:** If XPath changes break the scraper, see `dmr.py` GitHub for updates

## Integration with .NET Backend

The .NET backend (Billister) calls this service:

1. Client requests vehicle lookup → Billister API
2. Billister checks DB cache first
3. If cache miss, calls this Python service
4. Results cached in DB for future requests
5. Response returned to client

## Deployment

### Development

```bash
python app.py
```

### Production

```bash
gunicorn --bind 0.0.0.0:5000 --workers 4 app:app
```

Or use Docker:

```bash
docker build -t dmr-service .
docker run -p 5000:5000 dmr-service
```

## Troubleshooting

**"dmr.py not installed"**

```bash
pip install dmr.py
```

**Slow lookups**

- This is normal - skat.dk is slow
- Caching in Billister DB is essential

**XPath errors**

- DMR website may have changed
- Check https://github.com/j4asper/dmr.py for XPath updates

**Connection refused**

- Ensure DMR service is running on port 5000
- Check firewall settings

## Documentation

- **dmr.py**: https://github.com/j4asper/dmr.py
- **Danish Motor Registry**: https://motorregister.skat.dk/
