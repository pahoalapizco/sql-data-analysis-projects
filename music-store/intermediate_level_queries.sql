/*
-- ========== Intermediate Quering ==========
*/

-- 1. Which artist generated the most total revenue from song sales?
WITH revenue_by_track AS (
	SELECT T.album_id, SUM(I.total) AS total_by_track
	FROM invoice AS I
		INNER JOIN invoice_line AS IL ON IL.invoice_id = I.invoice_id
		INNER JOIN track AS T ON T.track_id = IL.track_id
	GROUP BY T.album_id
)

SELECT A.name, SUM(R.total_by_track) AS total_revenue
FROM artist AS A
	INNER JOIN album AS AL ON AL.artist_id = A.artist_id
	INNER JOIN revenue_by_track AS R ON R.album_id = AL.album_id
GROUP BY A.name
ORDER BY total_revenue DESC
LIMIT 1;

-- 2. What is the best-selling almbum (by number of tracks sold)?
WITH total_track_sales AS (
	SELECT T.album_id, COUNT(IL.track_id) AS total_track_sales
	FROM invoice_line AS IL 
		INNER JOIN track AS T ON T.track_id = IL.track_id
	GROUP BY T.album_id
)

SELECT A.title, T.total_track_sales
	FROM album AS A
	INNER JOIN total_track_sales AS T ON T.album_id = A.album_id
ORDER BY total_track_sales DESC
LIMIT 1;

-- 3. Which individual song had the highest sales volume?
SELECT T.name, COUNT(IL.track_id) AS total_track_sales
FROM invoice_line AS IL 
	INNER JOIN track AS T ON T.track_id = IL.track_id
GROUP BY T.name
ORDER BY total_track_sales DESC

-- 4. Total income by musical genre:
WITH revenue_by_genre AS (
	SELECT T.genre_id, SUM(I.total) AS total_by_genre
	FROM invoice AS I
		INNER JOIN invoice_line AS IL ON IL.invoice_id = I.invoice_id
		INNER JOIN track AS T ON T.track_id = IL.track_id
	GROUP BY T.genre_id
)

SELECT *
FROM genre AS G
	INNER JOIN revenue_by_genre AS R ON R.genre_id = G.genre_id
ORDER BY total_by_genre DESC;

-- 5. Top 5 customer who have spent the most.
SELECT C.first_name || ' ' || C.last_name AS name, 
	SUM(I.total) AS total_spent,
	COUNT(I.invoice_id) AS total_invoices
FROM invoice AS I
	INNER JOIN customer AS C ON C.customer_id = I.customer_id
GROUP BY C.first_name, C.last_name
ORDER BY total_spent DESC
LIMIT 5;

-- 6. Average song per album by artist.
WITH tracks_by_album AS (
	SELECT A.artist_id, A.name, AL.title, COUNT(T.track_id) AS total_tracks_by_album
	FROM track AS T 
		INNER JOIN album AS AL ON AL.album_id = T.album_id
		INNER JOIN artist AS A ON A.artist_id = AL.artist_id
	GROUP BY A.artist_id, A.name, AL.title
	ORDER BY A.name ASC
)

SELECT name, ROUND(AVG(total_tracks_by_album), 2) AS avg_tracks_by_artist
FROM tracks_by_album
GROUP BY name
ORDER BY avg_tracks_by_artist;

-- 7. Montly sales  (total number of invoices) in the last year
SELECT DATE_PART('YEAR', invoice_date), DATE_PART('MONTH', invoice_date) AS invoice_month, SUM(total) AS montly_total
FROM invoice
WHERE DATE_PART('YEAR', invoice_date) = (DATE_PART('YEAR', NOW()) - 1)
GROUP BY invoice_month, DATE_PART('YEAR', invoice_date)
ORDER BY invoice_month ASC;

-- 8. Wich employee generated the most sales?
SELECT E.first_name || ' ' || E.last_name AS employee_name,
	SUM(I.total) AS total_sales
FROM invoice AS I
	INNER JOIN customer AS C ON C.customer_id = I.customer_id
	INNER JOIN employee AS E ON E.employee_id = C.support_rep_id
GROUP BY employee_name
ORDER BY total_sales DESC
LIMIT 1;

-- 9. Which is the average songs price by metia type?
SELECT MT.name, ROUND(AVG(IL.unit_price), 2) avg_price
FROM invoice_line AS IL
	INNER JOIN track AS T ON T.track_id = IL.track_id
	INNER JOIN media_type AS MT ON MT.media_type_id = T.media_type_id
GROUP BY MT.name;