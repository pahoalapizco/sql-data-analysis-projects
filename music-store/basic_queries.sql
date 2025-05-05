/*
=========== BASIC QUERYING ===========
*/

-- 1. How many different artists are registered?
SELECT COUNT(DISTINCT name) FROM artist;

-- 2. How many albums are there in total?
SELECT COUNT(*) FROM album;

-- 3. What is the average lenght (in minutes) of the songs?
SELECT ROUND(AVG(milliseconds)/60000, 2) AS min_avg_lenght FROM track;

-- 4. How many customers per country are there?
SELECT country, COUNT(customer_id) AS total_customers
FROM customer 
GROUP BY country
ORDER BY total_customers DESC;

-- 5. Which employee servers the most customers (support)?
SELECT E.first_name  || ' ' || E.last_name AS employee, COUNT(C.support_rep_id) AS total_customers_supported
FROM employee AS E
	INNER JOIN customer AS C ON C.support_rep_id = E.employee_id
GROUP BY E.first_name, E.last_name
ORDER BY total_customers_supported DESC
LIMIT 1;

-- 6. How many invoices were issued in total?
SELECT COUNT(invoice_id)AS total_invoices FROM invoice;

-- 7. What is the average amount of an invoice?
SELECT ROUND(AVG(total), 2) AS avg_amount FROM invoice;

-- 8. How many different musical genres are there?
SELECT COUNT(name) AS genres FROM genre;

-- 9. How many Rock's songs are there?
SELECT COUNT(track_id) AS rock_songs
FROM track AS T
	INNER JOIN genre AS G ON G.genre_id = T.genre_id
WHERE G.name = 'Rock';

-- 10. How many playlist are there?
SELECT COUNT(playlist_id) AS total_playlists FROM playlist;