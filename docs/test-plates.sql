-- Test data for license plate lookups
-- Run this in your SQLite database to add test vehicles

INSERT INTO LicensePlateLookupCaches 
(Id, LicensePlate, Make, Model, Year, FuelType, Transmission, Kilometers, Color, Co2Emissions, CreatedAtUtc, LastAccessedAtUtc, AccessCount)
VALUES
('test-plate-1', 'AB12345', 'Toyota', 'Yaris', 2020, 'Benzin', 'Manual', 45000, 'Rød', 110, datetime('now'), datetime('now'), 0),
('test-plate-2', 'CD67890', 'Honda', 'Civic', 2019, 'Diesel', 'Automat', 62000, 'Sort', 95, datetime('now'), datetime('now'), 0),
('test-plate-3', 'EF34567', 'Volkswagen', 'Golf', 2021, 'Hybrid', 'Manual', 28000, 'Hvid', 85, datetime('now'), datetime('now'), 0),
('test-plate-4', 'GH89012', 'BMW', '320i', 2018, 'Benzin', 'Automat', 78000, 'Grå', 125, datetime('now'), datetime('now'), 0);
