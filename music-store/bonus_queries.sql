/*
-- ========== More Queries ==========
*/

-- 1. Top 5 albums with the most songs sold
SELECT A.name AS artist, AL.title, SUM(IL.quantity) AS total_tracks_sold
FROM invoice_line AS IL
	INNER JOIN track AS T ON T.track_id = IL.track_id
	INNER JOIN album AS AL ON AL.album_id = T.album_id
	INNER JOIN artist AS A ON A.artist_id = AL.artist_id
GROUP BY A.name, AL.title
ORDER BY total_tracks_sold DESC
LIMIT 5;

-- 2. Top 5 albums with the most revenue
SELECT A.name AS artist, AL.title, SUM(IL.quantity*IL.unit_price) AS total_tracks_sold
FROM invoice_line AS IL
	INNER JOIN track AS T ON T.track_id = IL.track_id
	INNER JOIN album AS AL ON AL.album_id = T.album_id
	INNER JOIN artist AS A ON A.artist_id = AL.artist_id
GROUP BY A.name, AL.title
ORDER BY total_tracks_sold DESC
LIMIT 5;

-- 3. Top 5 artist with the most songs released
SELECT A.name, COUNT(T.track_id) AS released_songs
FROM track AS T
	INNER JOIN album AS AL ON AL.album_id = T.album_id
	INNER JOIN artist AS A ON A.artist_id = AL.artist_id
GROUP BY A.name
ORDER BY released_songs DESC
LIMIT 5;

-- 4. Best-selling Media Type
SELECT MT.name, COUNT(IL.track_id) AS total_sales
FROM invoice_line AS IL
	INNER JOIN track AS T ON T.track_id = IL.track_id
	INNER JOIN media_type AS MT ON MT.media_type_id = T.media_type_id
GROUP BY MT.name
ORDER BY total_sales DESC
LIMIT 1;

-- 5. What has been the maximum number of songs purchased by the same customer on the same invoice?
WITH customer_purchase_by_invoice AS (
	SELECT C.customer_id, 
		I.invoice_id, 
		COUNT(IL.track_id) AS purchased_songs,
		RANK() OVER(PARTITION BY C.customer_id ORDER BY COUNT(IL.track_id) DESC) AS ranking
	FROM invoice_line AS IL
		INNER JOIN invoice AS I ON I.invoice_id = IL.invoice_id
		INNER JOIN customer AS C ON C.customer_id = I.customer_id
	GROUP BY C.customer_id, I.invoice_id
)

SELECT MAX(purchased_songs) AS maximun_sonsg
FROM customer_purchase_by_invoice
WHERE ranking = 1;

-- 6. Composer with the most songs written
WITH composer_list AS (
	SELECT TRIM(UNNEST(STRING_TO_ARRAY(composer, ','))) AS composer_name
	FROM track
	WHERE composer IS NOT NULL
)

SELECT composer_name, COUNT(composer_name) AS total_songs_written
FROM composer_list
GROUP BY composer_name
ORDER BY total_songs_written DESC
LIMIT 1;
