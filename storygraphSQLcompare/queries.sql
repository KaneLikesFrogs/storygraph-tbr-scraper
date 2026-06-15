SET search_path = storygraph;
WITH user_data_cte AS(
	SELECT
		"User" AS username,
		LOWER("Title") AS title,
		STRING_TO_ARRAY(LOWER("Authors"),', ') AS authors,
		COUNT("Authors") OVER(PARTITION BY "User","Authors","Read Status") AS author_occurences,
		ROUND(AVG("Star Rating") OVER(PARTITION BY "User","Authors","Read Status") :: numeric,2) AS avg_author_rating,
		STRING_TO_ARRAY("Contributors",', ') AS contributors,
		"Format" AS format,
		"Read Status" AS status,
		"Date Added" AS dateAdded,
		"Last Date Read" AS lastRead,
		"Dates Read" AS readOn,
		CASE 
			WHEN POSITION(', 'IN "Dates Read") = 0 
				THEN 
					CASE WHEN ((STRING_TO_ARRAY("Dates Read",'-'))[2] :: date ) -
						((STRING_TO_ARRAY("Dates Read",'-'))[1] :: date ) = 0
					THEN 1
					ELSE  ((STRING_TO_ARRAY("Dates Read",'-'))[2] :: date ) -
						((STRING_TO_ARRAY("Dates Read",'-'))[1] :: date )	
					END
			WHEN POSITION(', ' IN "Dates Read") != 0
				THEN  ((STRING_TO_ARRAY(LEFT("Dates Read",POSITION(', ' IN "Dates Read")),'-'))[2] :: date ) -
						((STRING_TO_ARRAY(LEFT("Dates Read",POSITION(', ' IN "Dates Read")),'-'))[1] :: date )	
			ELSE null
		END AS dtr,
		CASE 
			WHEN POSITION(', 'IN "Dates Read") = 0 
				THEN ((STRING_TO_ARRAY("Dates Read",'-'))[2] :: date )
			WHEN POSITION(', ' IN "Dates Read") != 0
				THEN (STRING_TO_ARRAY(LEFT("Dates Read",POSITION(', ' IN "Dates Read")),'-'))[2] :: date
			ELSE null
		END AS completedDate,
		"Read Count" AS readCount,
		STRING_TO_ARRAY("Moods",', ') AS moods,
		"Pace" AS pace,
		"Star Rating" AS rating,
		"Review"
	FROM user_data
),
read_cte AS(
	SELECT 
		DISTINCT(title),
		STRING_AGG(DISTINCT username,', ') AS people,
		STRING_TO_ARRAY(STRING_AGG(DISTINCT username,', '),', ') AS peopleArray,
		authors,
		COUNT(username) AS readerCount,
		AVG(rating) AS rating,
		ROUND(AVG(dtr),1) AS dtr,
		ROUND(STDDEV(rating) :: numeric,2) AS rating_deviation,
		ROUND(STDDEV(dtr) :: numeric,2) AS dtr_dev
	FROM user_data_cte
	WHERE status = 'read' 
	GROUP BY title,authors
),
tbr_cte AS(
	SELECT 
		DISTINCT(title),
		STRING_AGG(DISTINCT username,', ') AS people,
		STRING_TO_ARRAY(STRING_AGG(DISTINCT username,', '),', ') AS peopleArray,
		authors,
		COUNT(username) AS userCount
	FROM user_data_cte
	WHERE status = 'to-read'
	GROUP BY title,authors
),
combined_cte AS (
SELECT 
	tbr_cte.title,
	tbr_cte.people AS tbrs,
	tbr_cte.peopleArray AS tbr_array,
	read_cte.people AS readers,
	read_cte.peopleArray AS readers_array,
	read_cte.rating AS rating,
	dtr
FROM tbr_cte 
INNER JOIN read_cte ON read_cte.title = tbr_cte.title

)
-- author freq --
/*
SELECT 
	DISTINCT(authors),
	STRING_AGG(DISTINCT username,', ') AS readers,
	SUM(DISTINCT author_occurences) AS total_reads
FROM user_data_cte
WHERE status = 'read'
GROUP BY authors
ORDER BY total_reads DESC
*/
/*
-- tbr match --
SELECT
	title,
	people
FROM tbr_cte
WHERE array_length(peopleArray,1) > 1;
*/
/*
-- read match --
SELECT 
	title,
	ARRAY_TO_STRING(authors,', ') AS authors,
	people AS readers,
	rating AS avg_rating,
	rating_deviation
FROM read_cte 
WHERE array_length(peopleArray,1) > 1
ORDER BY rating_deviation,rating DESC
*/
/*
-- read dev --
SELECT 
	DISTINCT(people),
	COUNT(people)
FROM read_cte
GROUP BY people
*/
-- tbr/read match -- 
/*
SELECT 
	title,
	tbrs,
	readers,
	rating,
	dtr AS time_to_read
FROM combined_cte 
WHERE tbrs != ALL(readers_array)
OR readers != ALL(tbr_array)
ORDER BY tbrs,rating DESC
*/
-- format --
SELECT 
	DISTINCT(format),
	username,
	COUNT(*) OVER(PARTITION BY format,username) AS occurences
FROM user_data_cte
WHERE status = 'read'
AND username = '2'
ORDER BY username,occurences DESC
