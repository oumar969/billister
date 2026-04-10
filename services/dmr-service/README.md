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

Service will start on `http://localhost:5001`

## Configuration

### Environment Variables

Create a `.env` file (or set environment variables):

```env
# API Key Authentication
DMR_API_KEY=your-secret-api-key-min-32-chars-recommended
DMR_REQUIRE_AUTH=true

# Flask
FLASK_ENV=development
FLASK_DEBUG=False
```

**Development Mode:** Set `DMR_REQUIRE_AUTH=false` to disable authentication.

**Production Mode:** Always set a strong API key:

```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

## API Authentication

All endpoints (except `/health` and `/api/info`) require an API key header:

```
X-API-Key: your-secret-api-key
```

If missing or invalid, you'll receive:

```json
{
  "error": "Unauthorized",
  "message": "X-API-Key header required"
}
```

## API Endpoints

### Health Check

```
GET /health
```

Returns service status (no auth required).

### Lookup Vehicle

```
GET /api/vehicles/plate/{plate}
X-API-Key: your-secret-api-key
```

Example:

```bash
curl -H "X-API-Key: your-secret-api-key" \
  http://localhost:5001/api/vehicles/plate/CW87553
```

**Response:** (200 OK)

```json
{
  "data": {
    "make": "Citroën",
    "model": "C3",
    "year": 2020,
    "fuelType": "diesel",
    "transmission": "automat",
    "kilometers": 150000,
    "color": "Sort",
    "co2Emissions": 125
  },
  "plate": "CW87553",
  "make": "Citroën",
  "model": "C3"
}
```

**Errors:**

- 400: Invalid plate format
- 401: Missing or invalid API key
- 404: Vehicle not found
- 503: Service unavailable

### Validate Plate

```
GET /api/vehicles/validate/{plate}
X-API-Key: your-secret-api-key
```

Validates license plate format.

### Service Info

```
GET /api/info
```

Returns service information (no auth required).

## Important Notes

⏱️ **Response Time:** 3-4 seconds per lookup (due to skat.dk database)

💾 **Caching:** The .NET backend caches results in its database to avoid repeated lookups

🔧 **Maintenance:** If XPath changes break the scraper, see `dmr.py` GitHub for updates

## Integration with .NET Backend

The .NET backend (Billister) calls this service with automatic API key authentication:

1. Client requests vehicle lookup → Billister API
2. Billister checks DB cache first
3. If cache miss, calls this Python service (includes `X-API-Key` header)
4. Results cached in DB for future requests
5. Response returned to client

### Backend Configuration

The .NET backend automatically includes the API key from `appsettings.json`:

```json
{
  "DmrService": {
    "ApiKey": "your-production-key"
  }
}
```

Ensure the backend API key matches the Flask service's `DMR_API_KEY`.

## Deployment

### Development

```bash
# Create .env file
cp .env.example .env
# Edit .env with a test API key

python app.py
```

### Production

Generate a strong API key:

```bash
python -c "import secrets; print('DMR_API_KEY=' + secrets.token_urlsafe(32))" >> .env
```

Run with gunicorn:

```bash
gunicorn --bind 0.0.0.0:5001 --workers 4 app:app
```

Or use Docker:

```bash
docker build -t dmr-service .
docker run -p 5001:5001 \
  -e DMR_API_KEY="your-production-key" \
  dmr-service
```

**Security:** Always use environment variables for API keys, never commit them to git.

## Docker Compose (Full Stack)

For local development or production, use docker-compose to run both the .NET backend and Python DMR service together:

### Setup

1. Create a `.env` file in the project root:

```bash
# Project root/.env
DMR_API_KEY=your-secret-api-key-here
```

2. Build and run:

```bash
cd /path/to/billister
docker-compose up --build
```

### Services

- **billister-api**: .NET backend on `http://localhost:5012`
- **dmr-service**: Python service on `http://localhost:5001` (internal network only)

### Network Communication

Services communicate via internal Docker network (`billister-network`):

- Backend → DMR: `http://dmr-service:5001`
- Both receive the same `DMR_API_KEY` from `.env`

### Development with Compose

```bash
# Start services
docker-compose up

# Stop services
docker-compose down

# Rebuild after code changes
docker-compose up --build

# View logs
docker-compose logs -f dmr-service
docker-compose logs -f billister-api
```

## Troubleshooting

**"dmr.py not installed"**

```bash
pip install dmr.py
```

**"401 Unauthorized - X-API-Key header required"**

- Missing API key header in request
- Verify you're including `X-API-Key: your-key` in the request
- Check `DMR_REQUIRE_AUTH=true` in `.env`

**"Invalid API key"**

- Verify the API key matches `DMR_API_KEY` in `.env`
- Ensure the .NET backend has the same key configured in `appsettings.json`
- Generate a new key if changed: `python -c "import secrets; print(secrets.token_urlsafe(32))"`

**"Connection refused" to Flask server**

- Verify service is running on correct port (default: 5001)
- Check network/firewall settings
- Test health endpoint: `curl http://localhost:5001/health`
- If using Docker Compose: Use `http://dmr-service:5001` from other containers

**Slow lookups**

- This is normal - skat.dk is slow
- Caching in Billister DB is essential

**XPath errors**

- DMR website may have changed
- Check https://github.com/j4asper/dmr.py for XPath updates

## Documentation

- **dmr.py**: https://github.com/j4asper/dmr.py
- **Danish Motor Registry**: https://motorregister.skat.dk/
