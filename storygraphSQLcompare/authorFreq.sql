SET search_path = storygraph;
WITH user_data_cte AS(
	SELECT
	"User" AS username,
	"Title" AS title,
	STRING_TO_ARRAY("Authors",', ') AS authors,
	STRING_TO_ARRAY("Contributors",', ') AS contributors,
	"Format" AS format,
	"Read Status" AS status,
	"Date Added" AS dateAdded,
	"Last Date Read" AS lastRead,
	"Dates Read" AS readOn,
	"Read Count" AS readCount,
	STRING_TO_ARRAY("Moods",', ') AS moods,
	"Pace" AS pace,
	"Star Rating",
	"Review"
FROM user_data
)
SELECT 
	DISTINCT(username),
	authors,
	count(authors) OVER(PARTITION BY authors,username) AS count_test
FROM user_data_cte
ORDER BY count_test DESC

