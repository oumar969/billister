-- Adds demo images to listings that have none.
-- Safe to run multiple times (inserts only when a listing has 0 images).
--
-- Run (example):
--   sqlite3 Billister/billister.db ".read Billister/dev-seed-images.sql"

INSERT INTO CarImages (Id, ListingId, Url, SortOrder, Width, Height)
SELECT
  lower(hex(randomblob(4))) || '-' ||
  lower(hex(randomblob(2))) || '-' ||
  lower(hex(randomblob(2))) || '-' ||
  lower(hex(randomblob(2))) || '-' ||
  lower(hex(randomblob(6))) AS Id,
  l.Id AS ListingId,
  'https://placehold.co/800x600?text=' ||
    replace(replace(coalesce(l.Make, 'Car') || '+' || coalesce(l.Model, ''), ' ', '+'), '%', '') AS Url,
  0 AS SortOrder,
  800 AS Width,
  600 AS Height
FROM CarListings l
WHERE NOT EXISTS (
  SELECT 1 FROM CarImages i WHERE i.ListingId = l.Id
);
