//1. Koliko se Formula1 ubrzala tokom godina (prosek najbrzeg kruga (km/h) po sezoni)
MATCH (res:Result)-[:IN_RACE]->(:Race)-[:IN_SEASON]->(s:Season)
WHERE res.fastestLapSpeed IS NOT NULL
RETURN s.year, round(avg(res.fastestLapSpeed),2) AS avg_kmh, count(*) AS samples
ORDER BY s.year;

//2. Procenat pobeda vozaca (Koliko trka na kojima je ucestvovao je vozac pobedio)
MATCH (d:Driver)-[:HAS_RESULT]->(res:Result)
WITH d, count(res) AS starts,
sum(CASE WHEN res.positionOrder = 1 THEN 1 ELSE 0 END) AS wins
WHERE starts >= 50
RETURN d.forename,d.surname, starts, wins, round(100.0*wins/starts, 1) AS percentage
ORDER BY percentage DESC LIMIT 10;

//3. Najbolja staza vozaca   
MATCH (d:Driver {ref:'alonso'})-[:HAS_RESULT]->(res:Result)-[:IN_RACE]->(:Race)-[:HELD_AT]->(c:Circuit)
WHERE res.positionOrder IS NOT NULL
WITH c, avg(res.positionOrder) AS avg_poz, count(*) AS broj_trka
WHERE broj_trka >= 3
RETURN c.ref, c.country, round(avg_poz) AS prosecna_pozicija, broj_trka
ORDER BY prosecna_pozicija ASC LIMIT 10;

//4. Prosecna brzina PitStop-a po timovima 
MATCH (ra:Race)<-[:IN_RACE]-(res:Result)-[:HAS_PITSTOP]->(p:PitStop),
      (res)-[:FOR_CONSTRUCTOR]->(c:Constructor)
WHERE ra.year >= 2026 AND p.duration_ms < 60000
RETURN c.name, round(avg(p.duration_ms)/1000.0, 2) AS avg_sec, count(*) AS total_pitstops
ORDER BY avg_sec DESC;