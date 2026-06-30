CREATE INDEX result_race_driver IF NOT EXISTS FOR (r:Result) ON (r.raceId, r.driverId);
CREATE INDEX result_position IF NOT EXISTS FOR (r:Result) ON (r.position);
CREATE INDEX race_year IF NOT EXISTS FOR (r:Race) ON (r.year);
CREATE INDEX driver_surname IF NOT EXISTS FOR (d:Driver) ON (d.surname);
CREATE INDEX circuit_ref IF NOT EXISTS FOR (c:Circuit) ON (c.ref);
CREATE INDEX circuit_country IF NOT EXISTS FOR (c:Circuit) ON (c.country);
CREATE INDEX constructor_name IF NOT EXISTS FOR (c:Constructor) ON (c.name);