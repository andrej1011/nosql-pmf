LOAD CSV WITH HEADERS FROM 'file:///seasons.csv' AS row
CREATE (:Season {year: toInteger(row.year)});

LOAD CSV WITH HEADERS FROM 'file:///circuits.csv' AS row
CREATE (:Circuit {
  circuitId: toInteger(row.circuitId), 
  ref: row.circuitRef,
  name: row.name, 
  location: row.location, 
  country: row.country,
  lat: toFloat(row.lat), lng: toFloat(row.lng)
 });

LOAD CSV WITH HEADERS FROM 'file:///status.csv' AS row
CREATE (:Status {statusId: toInteger(row.statusId), status: row.status});

LOAD CSV WITH HEADERS FROM 'file:///drivers.csv' AS row
CREATE (:Driver {
  driverId: toInteger(row.driverId), 
  ref: row.driverRef,
  code:   CASE row.code   WHEN '\N' THEN null ELSE row.code END,
  number: CASE row.number WHEN '\N' THEN null ELSE toInteger(row.number) END,
  forename: row.forename, 
  surname: row.surname,
  dob: CASE row.dob WHEN '\N' THEN null ELSE date(row.dob) END,
  nationality: row.nationality
  });

LOAD CSV WITH HEADERS FROM 'file:///constructors.csv' AS row
CREATE (:Constructor {
  constructorId: toInteger(row.constructorId),
  ref: row.constructorRef, 
  name: row.name, 
  nationality: row.nationality
 });

LOAD CSV WITH HEADERS FROM 'file:///races.csv' AS row
CREATE (:Race {
  raceId: toInteger(row.raceId), 
  year: toInteger(row.year),
  round: toInteger(row.round), 
  name: row.name,
  date: CASE row.date WHEN '\N' THEN null ELSE date(row.date) END
 });

LOAD CSV WITH HEADERS FROM 'file:///results.csv' AS row
CREATE (:Result {
  resultId: toInteger(row.resultId),
  raceId: toInteger(row.raceId), 
  driverId: toInteger(row.driverId),
  constructorId: toInteger(row.constructorId), 
  statusId: toInteger(row.statusId),
  grid: toInteger(row.grid),
  position: CASE row.position WHEN '\N' THEN null ELSE toInteger(row.position) END,
  positionOrder: toInteger(row.positionOrder),
  points: toFloat(row.points), 
  laps: toInteger(row.laps)
  
 });
 
 LOAD CSV WITH HEADERS FROM 'file:///results.csv' AS row
MATCH (res:Result {resultId: toInteger(row.resultId)})
SET res.number          = CASE row.number          WHEN '\N' THEN null ELSE toInteger(row.number) END,
    res.fastestLap      = CASE row.fastestLap      WHEN '\N' THEN null ELSE toInteger(row.fastestLap) END,
    res.rank            = CASE row.rank            WHEN '\N' THEN null ELSE toInteger(row.rank) END,
    res.fastestLapTime  = CASE row.fastestLapTime  WHEN '\N' THEN null ELSE row.fastestLapTime END,
    res.fastestLapSpeed = CASE row.fastestLapSpeed WHEN '\N' THEN null ELSE toFloat(row.fastestLapSpeed) END;