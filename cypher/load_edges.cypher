LOAD CSV WITH HEADERS FROM 'file:///races.csv' AS row
MATCH (r:Race {raceId: toInteger(row.raceId)})
MATCH (c:Circuit {circuitId: toInteger(row.circuitId)})
MERGE (r)-[:HELD_AT]->(c);

MATCH (r:Race) MATCH (s:Season {year: r.year})
MERGE (r)-[:IN_SEASON]->(s);

MATCH (res:Result) MATCH (d:Driver {driverId: res.driverId})
MERGE (d)-[:HAS_RESULT]->(res);

MATCH (res:Result) MATCH (r:Race {raceId: res.raceId})
MERGE (res)-[:IN_RACE]->(r);

MATCH (res:Result) MATCH (c:Constructor {constructorId: res.constructorId})
MERGE (res)-[:FOR_CONSTRUCTOR]->(c);

MATCH (res:Result) MATCH (st:Status {statusId: res.statusId})
MERGE (res)-[:HAS_STATUS]->(st);

MATCH (d:Driver)-[:HAS_RESULT]->(res:Result)-[:FOR_CONSTRUCTOR]->(c:Constructor)
WITH d, c, count(res) AS races_count
MERGE (d)-[r:DROVE_FOR]->(c)
SET r.races = races_count;

MATCH (d:Driver)-[:HAS_RESULT]->(res:Result)-[:FOR_CONSTRUCTOR]->(c:Constructor),
      (res)-[:IN_RACE]->(:Race)-[:IN_SEASON]->(s:Season)
WITH DISTINCT d, c, s
WITH c, s, collect(d) AS ds
UNWIND ds AS d1 UNWIND ds AS d2
WITH d1, d2 WHERE id(d1) < id(d2)
WITH d1, d2, count(*) AS number_of_seasons
MERGE (d1)-[t:TEAMMATE]->(d2) SET t.seasons = number_of_seasons;

MATCH (d:Driver)-[:HAS_RESULT]->(res:Result {positionOrder:1})-[:IN_RACE]->(r:Race)
MERGE (d)-[:WON]->(r);

LOAD CSV WITH HEADERS FROM 'file:///pit_stops.csv' AS row
MATCH (res:Result {raceId: toInteger(row.raceId), driverId: toInteger(row.driverId)})
CREATE (res)-[:HAS_PITSTOP]->(:PitStop {
  stop: toInteger(row.stop), lap: toInteger(row.lap),
  ms: toInteger(row.milliseconds), duration: row.duration});