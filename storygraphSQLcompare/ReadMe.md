# Queries and Examples

In this file I have snipped some of the queries and the sort of outputs they give. In cases with lots of inputs I have trimmed the table. The example outputs are based on the example data to help make it repeatable/provide a better example

The outputs will be in lowercase to help homogenize the data as when testing some editions of the same book had different capitlisation which led to some instances not being counted as expected 

These were all written and tested with pgAdmin4 of PostgreSQL

---

## Setting Up

First I created a schema called "storygraph"

~~~SQL

CREATE SCHEMA storygraph;

~~~

To set up our main table I first exported storygraph data from my own profile and used a friends profile (I have used users 1 and 2 to represent this). I simply added a first column titled "User" and then made sure the name matched for each row (can be easily handled by just dragging corner of cell in excel)

<details>
<summary>This can then be imported into our schema with this query (populateTable.sql)</summary>

~~~SQL

SET search_path = storygraph;

DROP TABLE IF EXISTS user_data;
CREATE TABLE user_data(
	"User" varchar,
	"Title" varchar,
	"Authors" varchar,
	"Contributors" varchar,
	"ISBN/UID" varchar,
	"Format" varchar,
	"Read Status" varchar,
	"Date Added" DATE,
	"Last Date Read" DATE,
	"Dates Read" varchar,
	"Read Count" int,
	"Moods" varchar,
	"Pace" varchar,
	"Character- or Plot-Driven?" varchar,
	"Strong Character Development?" varchar,
	"Loveable Characters?" varchar,
	"Diverse Characters?" varchar,
	"Flawed Characters?" varchar,
	"Star Rating" float,
	"Review" varchar,
	"Content Warnings" varchar,
	"Content Warning Description" varchar,
	"Tags" varchar,
	"Owned?" varchar
	);
COPY user_data(
	"User",
	"Title",
	"Authors",
	"Contributors",
	"ISBN/UID",
	"Format",
	"Read Status",
	"Date Added",
	"Last Date Read",
	"Dates Read",
	"Read Count",
	"Moods",
	"Pace",
	"Character- or Plot-Driven?",
	"Strong Character Development?",
	"Loveable Characters?",
	"Diverse Characters?",
	"Flawed Characters?",
	"Star Rating",
	"Review",
	"Content Warnings",
	"Content Warning Description",
	"Tags",
	"Owned?"
)
FROM 'path to combined data here'
DELIMITER ','
CSV HEADER;




~~~

</details>

(Make sure to replace the path with the path to your data)

## Example Queries (queries.sql)

In the other .sql file found in this repository there are a few different queries that can be uncommented but this goes over each and every one. 

<details>
<summary>The start of this file contains alot of common table expressions to setup/combine the user data</summary>

~~~SQL

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

~~~

</details>

### author freq

This query describes the author frequency for all users. It returns the books *read* by that author by all users. The same book won't be counted multiple times. It'll also list all the users that have read that author

~~~SQL

-- author freq --
SELECT 
	DISTINCT(authors),
	STRING_AGG(DISTINCT username,', ') AS readers,
	SUM(DISTINCT author_occurences) AS total_reads
FROM user_data_cte
WHERE status = 'read'
GROUP BY authors
ORDER BY total_reads DESC

~~~

OUTPUT:

|authors|	readers	|total_reads|
|-------|-------------|-------|
|{"brandon sanderson"}|	1|	25|
|{"sarah j. maas"}	|1, 2|	23|
|{"terry pratchett"}|1, 2|	20|
|{"susanne valenti","caroline peckham"}|	2|	18|
|{"derek landy"}|1|	11|


### tbr match

This will return a list of books where it is more than 1 users TBR list. The length can be adjusted to find books with everyone on them for cases with more users

~~~SQL

-- tbr match --
SELECT
	title,
	people
FROM tbr_cte
WHERE array_length(peopleArray,1) > 1;

~~~

Output:

|title	|people|
|-|-|
|red rising	|1, 2|
|lady's knight	|1, 2|
|you weren't meant to be human	|1, 2|
|katabasis	|1, 2|
|death among the stars	|1, 2|

### read match

Returns a list books based on how much users agree (limits to books only more than 1 users has read). (based on standard deviation of ratings)

~~~SQL

-- read match--
SELECT 
	title,
	ARRAY_TO_STRING(authors,', ') AS authors,
	people AS readers,
	rating AS avg_rating,
	rating_deviation
FROM read_cte 
WHERE array_length(peopleArray,1) > 1
ORDER BY rating_deviation,rating DESC
~~~

Output:

|title	|authors	|readers	|avg_rating	|rating_deviation|
|------|------------|-----------|-----------|----------------|
|bury our bones in the midnight soil|	v.e. schwab	|1, 2|	5	|0.00|
|the invisible life of addie larue	|v.e. schwab	|1, 2|	5	|0.00|
|legends & lattes |travis baldree|	1, 2	|4.5	|0.00|
|the final strife	|saara el-arifi|	1, 2	|4	|0.00|
|the isle in the silver sea|	tasha suri|	1, 2	|4.625	|0.18|



### read dev

Returns books read by users. If an item is read by multiple users it won't be counted and instead counted in a combination list

~~~SQL

-- read dev --
SELECT 
	DISTINCT(people),
	COUNT(people)
FROM read_cte
GROUP BY people

~~~

Output:

|people|	count|
|-|-|
|1|	91|
|1, 2|	13|
|2|	210|

### tbr/read match

Returns books that one user has read that exist on a different users TBR. Returns the average time to read and rating. Great for giving/getting reccomendations on what to read next without growing your TBR

~~~SQL

-- tbr/read match -- 
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

~~~

Output:

|title	|tbrs|	readers|	rating|	time_to_read|
|-------|---|----------|----------|-------------|
|the song of achilles|2	|1	|5	|7.0|
|piranesi|2|	1|	4.75	|5.0|
|hammajang luck	|2	|1	|4.5	|11.0|
|black sun|2|1|	4.25	|20.0|
|six of crows|	2|	1|	4.25	|9.0|
|a darker shade of magic|2|	1	|4	|4.0|


### format

Returns count of most popular format. This requries users to be good at entering the correct editions/formats for it to be accurate

~~~SQL

-- format --
SELECT 
	DISTINCT(format),
	username,
	COUNT(*) OVER(PARTITION BY format,username) AS occurences
FROM user_data_cte
WHERE status = 'read'
ORDER BY username,occurences DESC

~~~

Output:

|format	|username|occurences|
|--------|------|---------|
|paperback	|1	|63|
|hardcover	|1	|38|
|audio	|1	|4|
|digital	|1	|1|
|audio	|2	|164|
|digital	|2	|49|
|hardcover	|2	|5|
|paperback	|2	|5|
