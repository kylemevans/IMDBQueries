--Some of these queries are rather complex and may take a while to load on a standard computer; they were originally performed on the Microsoft Azure Cloud.

--What are the first and last names of all the actors who played in the movie 'Officer 444'?

SELECT fname, lname
FROM ACTOR, MOVIE, CASTS
WHERE MOVIE.name='Officer 444' AND CASTS.mid=MOVIE.id AND CASTS.pid=ACTOR.id;

--Who are all the directors who directed a 'Film-Noir' movie in a leap year?

SELECT DIRECTORS.fname, DIRECTORS.lname
FROM DIRECTORS, GENRE, MOVIE, MOVIE_DIRECTORS
WHERE GENRE.genre='Film-Noir' AND GENRE.mid=MOVIE.id AND (MOVIE.YEAR % 4) = 0 AND MOVIE.id=MOVIE_DIRECTORS.mid AND DIRECTORS.id=MOVIE_DIRECTORS.did;

--Who are all the actors who acted in a film before 1900 and also in a film after 2000? (This is primarily historical figures 'playing themselves' in documentaries and such.)

SELECT DISTINCT ACTOR.fname, ACTOR.lname 
FROM ACTOR, MOVIE movie1, MOVIE movie2, CASTS cast1, CASTS cast2
WHERE movie1.year > 2000 AND movie2.year < 1900 AND ACTOR.id = cast1.pid AND ACTOR.id = cast2.pid AND cast1.mid = movie1.id AND cast2.mid = movie2.id;

--Who are the directors who directed 500 movies or more, given in descending order of the number of movies they directed?

SELECT DIRECTORS.fname, DIRECTORS.lname, count(*)
FROM DIRECTORS, MOVIE_DIRECTORS
WHERE MOVIE_DIRECTORS.did=DIRECTORS.id
GROUP BY DIRECTORS.fname, DIRECTORS.lname
HAVING count(*) > 500
ORDER BY count(*) DESC;

--Who are the actors that played five or more distinct roles in the same movie in the year 2010?

SELECT ACTOR.fname, ACTOR.lname, MOVIE.name, count(DISTINCT CASTS.role)
FROM ACTOR, MOVIE, CASTS
WHERE MOVIE.year=2010 AND ACTOR.id=CASTS.pid AND MOVIE.id=CASTS.mid 
GROUP BY ACTOR.fname, ACTOR.lname, MOVIE.id
HAVING count(DISTINCT CASTS.role) >= 5;

--What were the roles of the actors that had five ore more distinct roles in the same movie in the year 2010?

SELECT ACTOR.fname, ACTOR.lname, MOVIE.name, CASTS.role
FROM (SELECT CASTS.pid, CASTS.mid
      FROM MOVIE, CASTS
      GROUP BY CASTS.pid, CASTS.mid
      HAVING count(DISTINCT role) >= 5) SelectedCasts, ACTOR, MOVIE, CASTS
WHERE MOVIE.year = 2010 AND MOVIE.id = SelectedCasts.mid AND SelectedCasts.mid = CASTS.mid AND SelectedCasts.pid = CASTS.pid AND SelectedCasts.pid = ACTOR.id;

--For each year that IMDB has data, how many movies in that year had only female actors?

SELECT MOVIE.year, count(*)
FROM MOVIE
WHERE NOT EXISTS (SELECT * 
				  FROM ACTOR, CASTS
                  WHERE ACTOR.id = CASTS.pid AND ACTOR.gender = 'M' AND CASTS.mid = MOVIE.id)
GROUP BY MOVIE.year;

--For each year that IMDB has data, what is the percentage of movies with only female actors made that year, and how many total movies were made that year?

SELECT MOVIE.year, count(*) * 100 / TotalMovies, TotalMovies
FROM MOVIE
INNER JOIN (SELECT MOVIE.year, count(*) AS TotalMovies 
			FROM MOVIE 
			GROUP BY MOVIE.year) TotalMoviesRelation 
ON TotalMoviesRelation.year = MOVIE.year
WHERE NOT EXISTS (SELECT * 
				  FROM ACTOR, CASTS
                  WHERE ACTOR.id = CASTS.pid AND ACTOR.gender = 'M' AND CASTS.mid = MOVIE.id)
GROUP BY MOVIE.year, TotalMovies;
 
--What film(s) had the largest number of distinct actors that played in that movie, and how many distinct actors made up that cast?
 
SELECT *
FROM (SELECT Movie.name AS MovieName, count(DISTINCT Casts.pid) AS CastsCount
      FROM Movie, Casts
      WHERE Casts.mid=Movie.id
      GROUP BY Casts.mid, Movie.name) MoviesCasts
WHERE MoviesCasts.CastsCount = (SELECT MAX(CastsCount) 
								FROM (SELECT Movie.name AS MovieName, count(DISTINCT Casts.pid) AS CastsCount
									  FROM Movie, Casts
									  WHERE Casts.mid=Movie.id
									  GROUP BY Casts.mid, Movie.name) MoviesCasts);

--What decade had the largest number of films? (A decade is a sequence of 10 consecutive years. For example 1965, 1966, ..., 1974 is a decade, and so is 1967, 1968, ..., 1976.)

SELECT TOP 1 currentYear, count(MOVIE.id) AS numFilms
FROM (SELECT DISTINCT MOVIE.year AS currentYear
	  FROM MOVIE) yeartable, MOVIE
WHERE MOVIE.year >= yeartable.currentYear AND MOVIE.year < yeartable.currentYear + 10 
GROUP BY currentYear
ORDER BY numFilms DESC;

--The Bacon number of an actor is the length of the shortest path between the actor and Kevin Bacon in the "co-acting" graph. That is, Kevin Bacon has Bacon number 0; all actors who acted in the same film as KB have Bacon number 1; all actors who acted in the same film as some actor with Bacon number 1 (but not with Bacon himself) have Bacon number 2, etc. How many actors have a Bacon number of 2?

SELECT count(*)
FROM ACTOR
WHERE ACTOR.id IN (SELECT z.pid
				   FROM ACTOR, CASTS w, CASTS x, CASTS y, CASTS z
			       WHERE ACTOR.fname = 'Kevin' AND ACTOR.lname = 'Bacon' AND ACTOR.id = w.pid
						AND w.mid = x.mid AND x.pid = y.pid AND y.mid = z.mid
						AND z.pid NOT IN (SELECT DISTINCT y.pid
										   FROM ACTOR, CASTS x, CASTS y
										   WHERE ACTOR.fname = 'Kevin' AND ACTOR.lname = 'Bacon' AND ACTOR.id = x.pid AND x.mid = y.mid)
				  );