# Billister

Billister er en platform til bilannoncer med backend-API, mobilapp og en separat service til nummerpladeopslag.

## Hvad projektet indeholder
- Oprettelse og visning af bilannoncer
- Brugerlogin og autentificering
- Favoritter, chat og notifikationer
- Betalinger via Stripe
- Nummerpladeopslag via DMR-service

## Hvad vi bruger
- **Backend:** ASP.NET Core (.NET 7), Entity Framework Core, SQLite, JWT, SignalR, Swagger
- **Mobilapp:** Flutter (Dart)
- **Ekstern service:** Python/Flask til DMR-opslag
- **Infrastruktur:** Docker og docker-compose
