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


