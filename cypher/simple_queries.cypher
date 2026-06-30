//1. Sve staze u zemlji
MATCH (c:Circuit {country:'Italy'})
RETURN c.name, c.location ORDER BY c.name;

//2. Pronadji vozaca
MATCH (d:Driver {surname:'Verstappen'})
RETURN d.forename, d.surname, d.dob, d.nationality;

//3. Broj trka po sezoni
MATCH (s:Season)<-[:IN_SEASON]-(r:Race)
RETURN s.year, count(r) AS count ORDER BY s.year;

//4. Top 10 vozaca po pobedama
MATCH (d:Driver)-[:WON]->(:Race)
RETURN d.forename +' '+ d.surname AS vozac, count(*) AS broj_pobeda
ORDER BY broj_pobeda DESC LIMIT 10;

//5. Timovi po nacionalnosti
MATCH (c:Constructor)
RETURN c.nationality as nationality, count(*) as team_count 
ORDER BY team_count DESC;

//6. Sve trke na stazi
MATCH (r:Race)-[:HELD_AT]->(:Circuit {ref:'silverstone'})
RETURN r.year,r.date ORDER BY r.year;

//7. Vozaci rodjeni posle 2000.
MATCH (d:Driver) WHERE d.dob >= date('2000-01-01')
RETURN d.forename, d.surname, d.dob ORDER BY d.dob DESC;

//8. Za koliko timova je vozac vozio
MATCH (d:Driver)-[:DROVE_FOR]->(c:Constructor)
RETURN d.forename+' '+d.surname as driver, count(c) AS teams 
ORDER BY teams DESC LIMIT 20;

//9. Ukupno poena jednog vozaca
MATCH (d:Driver {ref:'hamilton'})-[:HAS_RESULT]->(res:Result)
RETURN d.forename+' '+d.surname as driver, sum(res.points) AS total_points;
