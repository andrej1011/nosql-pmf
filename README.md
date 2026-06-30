# NoSQL Projekat
## F1 dataset 

Kaggle F1 set (Ergast.com, 1950–danas). 
https://www.kaggle.com/datasets/jtrotman/formula-1-race-data

## Čvorovi

- `:Driver` (vozač)
- `:Constructor` (tim)
- `:Circuit` (staza)
- `:Race` (trka)
- `:Result` (rezultat trke)
- `:Season` (sezona)
- `:PitStop` (pauza u toku trke)

### Properties Čvorovi
| čvor             | properties                                                                                     |
| ---------------- | ---------------------------------------------------------------------------------------------- |
| **:Season**      | year                                                                                           |
| **:Circuit**     | circuitId, ref, name, location, country, lat, lng                                              |
| **:Constructor** | constructorId, ref, name, nationality                                                          |
| **:Driver**      | driverId, ref, code, number, forename, surname, dob, nationality                               |
| **:Race**        | raceId, year, round, name, date                                                                |
| **:Result**      | resultId, grid, laps, points, positionOrder, fastestLap, rank, fastestLapTime, fastestLapSpeed |
| **:PitStop**     | stop, lap, duration_ms                                                                         |

Import čvorove: `import_nodes.cypher` 
Import veze: `import_egdes.cypher`
Takodje: `import_constraints.cypher`

Napomena: Dataset je modifikovan u odnosu na [originalni dataset sa Kaggle-a](https://www.kaggle.com/datasets/jtrotman/formula-1-race-data).
Neka polja su obrisana: Season.url (vodi ka wikipedia stranici), PitStop.duration je normalizovan u milisekunde i preimenovan u duration_ms, Result.position je obrisan i treba da se koristi positionOrder.
## Simple Queries

### 1. Sve staze u zemlji
 
```
MATCH (c:Circuit {country:'Italy'})
RETURN c.name, c.location ORDER BY c.name;
```

### 2. Pronadji vozača
```
MATCH (d:Driver {ref:'verstappen'})
RETURN d.forename, d.surname, d.dob, d.nationality;
```

### 3. Broj trka po sezoni
```
MATCH (s:Season)<-[:IN_SEASON]-(r:Race)
RETURN s.year, count(r) AS count ORDER BY s.year;
```

###  4. Top 10 vozača po pobedama
```
MATCH (d:Driver)-[:WON]->(:Race)
RETURN d.forename +' '+ d.surname AS vozac, count(*) AS broj_pobeda
ORDER BY broj_pobeda DESC LIMIT 10;
```
### 5. Timovi po nacionalnosti
```
MATCH (c:Constructor)
RETURN c.nationality as nationality, count(*) as team_count 
ORDER BY team_count DESC;
```

### 6. Sve trke odrzane na stazi
```
MATCH (r:Race)-[:HELD_AT]->(:Circuit {ref:'silverstone'})
RETURN r.year,r.date ORDER BY r.year;
```

### 7. Vozači rodjeni posle 2000.
```
MATCH (d:Driver) WHERE d.dob >= date('2000-01-01')
RETURN d.forename, d.surname, d.dob ORDER BY d.dob DESC;
```

### 8. Za koliko timova je vozač vozio
```
MATCH (d:Driver)-[:DROVE_FOR]->(c:Constructor)
RETURN d.forename+' '+d.surname as driver, count(c) AS teams 
ORDER BY teams DESC LIMIT 20;
```

### 9. Ukupno poena jednog vozaca
```
MATCH (d:Driver {ref:'hamilton'})-[:HAS_RESULT]->(res:Result)
RETURN d.forename+' '+d.surname as driver, sum(res.points) AS total_points;
```

## Complex Queries

### 1. Koliko se Formula1 ubrzala tokom godina
    prosek najbržeg kruga (km/h) po sezoni
    
```
MATCH (res:Result)-[:IN_RACE]->(:Race)-[:IN_SEASON]->(s:Season)
WHERE res.fastestLapSpeed IS NOT NULL
RETURN s.year, round(avg(res.fastestLapSpeed),2) AS avg_kmh, count(*) AS samples
ORDER BY s.year;
```

### 2. Procenat pobeda vozača
	Koliko trka na kojima je učestvovao je vozač pobedio

```
MATCH (d:Driver)-[:HAS_RESULT]->(res:Result)
WITH d, count(res) AS starts,
sum(CASE WHEN res.positionOrder = 1 THEN 1 ELSE 0 END) AS wins
WHERE starts >= 50
RETURN d.forename,d.surname, starts, wins, round(100.0*wins/starts, 1) AS percentage
ORDER BY percentage DESC LIMIT 10;
```

### 3. Najbolja staza vozača

```
MATCH (d:Driver {ref:'alonso'})-[:HAS_RESULT]->(res:Result)-[:IN_RACE]->(:Race)-[:HELD_AT]->(c:Circuit)
WHERE res.positionOrder IS NOT NULL
WITH c, avg(res.positionOrder) AS avg_poz, count(*) AS broj_trka
WHERE broj_trka >= 3
RETURN c.ref, c.country, round(avg_poz) AS prosecna_pozicija, broj_trka
ORDER BY prosecna_pozicija ASC LIMIT 10;
```

### 4. Prosečna brzina PitStop-a po timovima

```
MATCH (ra:Race)<-[:IN_RACE]-(res:Result)-[:HAS_PITSTOP]->(p:PitStop),
(res)-[:FOR_CONSTRUCTOR]->(c:Constructor)
WHERE ra.year >= 2026 AND p.duration_ms < 60000
RETURN c.name, round(avg(p.duration_ms)/1000.0, 2) AS avg_sec, count(*) AS total_pitstops
ORDER BY avg_sec DESC;
```

## GDS Queries
### GDS 1 
PageRank: najdominantniji vozač

- `project` → napravi graf iz LOST_TO.
- `pageRank.stream` → rang.

PageRank demo poenta: težina = koliko puta pobedio. Skor visok kad te pobeđuju JAKI → pobeda nad jakim vredi više.

#### Dodavanje grane :LOST_TO
```cypher
MATCH (race:Race)<-[:IN_RACE]-(w:Result)<-[:HAS_RESULT]-(winner:Driver),(race:Race)<-[:IN_RACE]-(l:Result)<-[:HAS_RESULT]-(loser:Driver)
WHERE w.positionOrder < l.positionOrder
WITH loser, winner, count(*) AS times
MERGE (loser)-[r:LOST_TO]->(winner) SET r.times = times;
```

#### PageRank Algoritam
```cypher
CALL { CALL gds.graph.drop('dominant_driver', false) YIELD graphName RETURN count(*) AS _ }
CALL gds.graph.project('dominant_driver','Driver',{LOST_TO:{properties:'times'}}) YIELD relationshipCount
CALL gds.pageRank.stream('dominant_driver',{relationshipWeightProperty:'times',dampingFactor:0.85,maxIterations:10000}) YIELD nodeId, score
RETURN gds.util.asNode(nodeId).forename + ' ' + gds.util.asNode(nodeId).surname AS driver, round(score,4) AS pagerank_score
ORDER BY pagerank_score DESC LIMIT 20;
```

### GDS 2
Leiden algoritam
Ere vozaca, preko grane `:TEAMMATES`
Leiden algoritam gleda koji vozac je sa kim vezan i tako pravi unutrasnje grupacije.
Za razliku od Louvain algoritma, pre nego sto odradi agregaciju, Leiden proveri jos jednom da li je most cvor idalje u grupi gde treba da bude. 

```cypher
CALL { CALL gds.graph.drop('era', false) YIELD graphName RETURN count(*) AS _ }
CALL gds.graph.project('era','Driver',{TEAMMATE:{orientation:'UNDIRECTED',properties:'seasons'}}) YIELD relationshipCount
CALL gds.leiden.stream('era',{relationshipWeightProperty:'seasons',gamma:1,randomSeed:42,concurrency:2}) YIELD nodeId, communityId
WITH communityId, collect(gds.util.asNode(nodeId).surname) AS vozaci, count(*) AS n
WHERE n >= 4
RETURN communityId, n AS velicina_grupe, vozaci[..20] AS vozaci
ORDER BY velicina_grupe DESC;
```


### GDS3
NodeSimilarity algoritam
Poredjenje slicnosti staza.
Preko rezultata koje su vozaci osvojili na njima. (Nemamo podatke o samoj stazi, ovako imamo podatke koje staze su prijale kakvom stilu voznje kod vozaca)

```cypher
CALL { CALL gds.graph.drop('staze', false) YIELD graphName RETURN count(*) AS _ }
CALL gds.graph.project.cypher('staze',
  'MATCH (c:Circuit) RETURN id(c) AS id UNION MATCH (d:Driver) RETURN id(d) AS id',
  'MATCH (c:Circuit)<-[:HELD_AT]-(:Race)<-[:IN_RACE]-(res:Result)<-[:HAS_RESULT]-(d:Driver)
   WHERE res.positionOrder <= 3
   RETURN id(c) AS source, id(d) AS target, count(*) AS weight'
) YIELD relationshipCount
CALL gds.nodeSimilarity.stream('staze',{relationshipWeightProperty:'weight',topK:5}) YIELD node1, node2, similarity
WITH gds.util.asNode(node1) AS c1, gds.util.asNode(node2) AS c2, similarity
WHERE node1 < node2
RETURN c1.name AS staza1, c2.name AS staza2, round(similarity,3) AS slicnost
ORDER BY slicnost DESC LIMIT 25;
```

**težinski Jaccard**:
- za svakog zajedničkog vozača doprinos = `min(bodovi_stazaA, bodovi_stazaB)`, imenilac = `sum(max)`.
- vozač jak na **obe** staze → veliki `min` → veliki doprinos.
- jak na jednoj, slab na drugoj → `min` mali → mali doprinos.
- staze slične samo ako isti vozači imaju **sličan nivo** na obe.

### GDS 4
Sakrij-pa-pogodi. 
Predikcija sezone 2024 iz PageRank dominacije od zadnje 3 godine pre toga.

```cypher
CALL { CALL gds.graph.drop('pred', false) YIELD graphName RETURN count(*) AS _ }
CALL gds.graph.project.cypher('pred',
  'MATCH (d:Driver) RETURN id(d) AS id',
  'MATCH (race:Race) WHERE race.year >= 2024 - 3 AND race.year < 2024
   MATCH (race)<-[:IN_RACE]-(w:Result)<-[:HAS_RESULT]-(winner:Driver),
         (race)<-[:IN_RACE]-(l:Result)<-[:HAS_RESULT]-(loser:Driver)
   WHERE w.positionOrder < l.positionOrder
   WITH id(loser) AS source, id(winner) AS target, count(*) AS weight
   RETURN source, target, weight'
) YIELD relationshipCount

CALL gds.pageRank.stream('pred',{relationshipWeightProperty:'weight',maxIterations:50}) YIELD nodeId, score
WITH gds.util.asNode(nodeId) AS d, score ORDER BY score DESC LIMIT 5
WITH collect(d) AS predvidjeni
MATCH (dr:Driver)-[:HAS_RESULT]->(res:Result)-[:IN_RACE]->(:Race {year:2022})
WITH predvidjeni, dr, sum(res.points) AS bod ORDER BY bod DESC LIMIT 5
WITH predvidjeni, collect(dr) AS stvarni
WITH predvidjeni, stvarni, [d IN predvidjeni WHERE d IN stvarni] AS pogodjeni
RETURN [d IN predvidjeni | d.surname] AS predvidjeno_top5,
       [d IN stvarni    | d.surname] AS stvarno_top5,
       size(pogodjeni) AS pogodaka,
       round(toFloat(size(pogodjeni))/5,2) AS preciznost;
```

## Pitanje na odbrani projekta

Prikaži sve vozače koji su u 2010. godini pobedili trku.
```cypher
MATCH (d:Driver)-[:WON]->(r:Race)
WHERE r.year=2010
RETURN d.forename +' '+ d.surname, count(*)
ORDER BY count(*) DESC;
```

Mozda cak i `simple_queries` i `complex_queries` nisu potrebni da se rade.
