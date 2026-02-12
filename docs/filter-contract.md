# Filter-kontrakt (Flutter ↔ .NET)

Backend bruger et fælles JSON-format kaldet `ListingFilterCriteria`. Flutter kan bygge objektet og sende det som JSON.

## POST søgning (anbefalet til 40+ filtre)

`POST /api/listings/search`

Body:

```json
{
  "page": 1,
  "pageSize": 20,
  "criteria": {
    "q": "model 3",
    "makes": ["Tesla"],
    "models": ["Model 3"],
    "fuelTypes": ["el"],
    "transmissions": ["automat"],
    "priceMin": 150000,
    "priceMax": 350000,
    "yearMin": 2019,
    "mileageMax": 120000,
    "rangeMin": 350,
    "requiredFeatures": ["navigation", "adaptiv_fartpilot"],
    "centerLat": 55.6761,
    "centerLng": 12.5683,
    "radiusKm": 25,
    "extra": {
      "isFirstOwner": true,
      "accidentFree": true,
      "dealerType": ["private", "dealer"],
      "chargingSpeedKw": 170
    }
  }
}
```

## GET søgning (til simple filtre)

`GET /api/listings?...`

GET-varianten er stadig understøttet for simple query-parametre (make/model/fuel/price/range osv.), men POST anbefales til et stort filter-objekt.

## Saved searches

`CriteriaJson` i saved searches skal være JSON i samme format som `criteria`-feltet ovenfor (altså et `ListingFilterCriteria`-objekt). Backend normaliserer JSON’en ved oprettelse/opdatering.

Alternativ (anbefalet fra Flutter):

`POST /api/saved-searches/from-criteria`

Body:

```json
{
  "name": "Tesla under 350k",
  "criteria": {
    "makes": ["Tesla"],
    "priceMax": 350000
  }
}
```
