/*
-- ========== Advance Quering ==========
*/

-- 1. Customer retention rate: Percent of customers who repeat purchase after their first invoice
WITH first_purchase AS (
	SELECT customer_id, MIN(invoice_date) first_purchase_date
	FROM invoice
	GROUP BY customer_id
)

SELECT (COUNT(DISTINCT I.customer_id) / (SELECT COUNT(customer_id) FROM first_purchase) * 100) AS retation_rate
FROM invoice AS I
	INNER JOIN first_purchase AS F ON F.customer_id = I.customer_id AND I.invoice_date > first_purchase_date;

-- 2. Customer RFM (Recency, Frequency, Monetary) segmentation:
-- Recency: How long ago was the customer's last purchase?
-- Frequency: How often does the customer purchase? 
-- Monetary: How much has the customer spend in total?
WITH rfm_seg AS (
	SELECT C.customer_id, 
		EXTRACT(DAY FROM NOW() - MAX(I.invoice_date)) AS recency,
		COUNT(I.invoice_id) AS frequency,
		SUM(I.total) AS monetary
	FROM invoice AS I
		INNER JOIN customer AS C ON C.customer_id = I.customer_id
	WHERE I.invoice_date <= NOW()
	GROUP BY C.customer_id
),

-- Divide each score into 4 buckets, where 4 is the best score
rfm_scores AS (
	SELECT customer_id, recency, frequency, monetary,
		5 - NTILE(4) OVER (ORDER BY recency ASC) AS recency_score,
		NTILE(4) OVER (ORDER BY frequency ASC) AS frequency_score,
		NTILE(4) OVER (ORDER BY monetary ASC) AS monetary_score
	FROM rfm_seg
), 

rfm_concat_scores AS (
	SELECT customer_id,
		recency_score,
		frequency_score,
		monetary_score,
		(recency_score::TEXT || frequency_score:: TEXT || monetary_score::TEXT) AS rfm_score
	FROM rfm_scores
)

SELECT customer_id,
		recency_score,
		frequency_score,
		monetary_score,
		rfm_score,
		CASE 
			WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Champions'
			WHEN recency_score >= 3 AND frequency_score <= 2 AND monetary_score <= 2 THEN 'At Risk'
			WHEN recency_score = 4  AND (frequency_score >= 3 OR monetary_score >=3 ) THEN 'Loyal'
			WHEN recency_score <= 2 AND frequency_score >= 3 THEN 'Potencial'
			ELSE 'Other'
		END AS segment
FROM rfm_concat_scores;

-- 3. Quartely revenue evolution per artist over the last year.
WITH artist_tracks AS (
	SELECT A.name AS artist_name, T.track_id 
	FROM track AS T 
		INNER JOIN album AS AL ON AL.album_id = T.album_id
		INNER JOIN artist AS A ON A.artist_id = AL.artist_id
	GROUP BY A.name, T.track_id 
), 

quarters AS (
	SELECT
		ART.artist_name,
		EXTRACT (YEAR FROM I.invoice_date) AS invoice_year, 
		EXTRACT ('quarter' FROM I.invoice_date) AS invoice_quarter,
		I.total
	FROM invoice AS I
		INNER JOIN invoice_line AS IL ON IL.invoice_id = I.invoice_id
		INNER JOIN artist_tracks AS ART ON ART.track_id = IL.track_id
	WHERE I.invoice_date BETWEEN '2023-01-31'::DATE AND '2024-12-31'::DATE
)

SELECT artist_name,
	SUM(CASE WHEN invoice_year = 2023 AND invoice_quarter = 1 THEN total ELSE 0 END) AS "Q2023_1",
	SUM(CASE WHEN invoice_year = 2023 AND invoice_quarter = 2 THEN total ELSE 0 END) AS "Q2023_2",
	SUM(CASE WHEN invoice_year = 2023 AND invoice_quarter = 3 THEN total ELSE 0 END) AS "Q2023_3",
	SUM(CASE WHEN invoice_year = 2023 AND invoice_quarter = 4 THEN total ELSE 0 END) AS "Q2023_4",
	SUM(CASE WHEN invoice_year = 2024 AND invoice_quarter = 1 THEN total ELSE 0 END) AS "Q2024_1",
	SUM(CASE WHEN invoice_year = 2024 AND invoice_quarter = 2 THEN total ELSE 0 END) AS "Q2024_2",
	SUM(CASE WHEN invoice_year = 2024 AND invoice_quarter = 3 THEN total ELSE 0 END) AS "Q2024_3",
	SUM(CASE WHEN invoice_year = 2024 AND invoice_quarter = 4 THEN total ELSE 0 END) AS "Q2024_4"
FROM quarters
GROUP BY artist_name
ORDER BY artist_name ASC;


-- 4. Profitability analysis per employee: revenue generated vs. number of assigned clients.
SELECT E.first_name || ' ' || E.last_name AS employee_name,
	SUM(I.total) AS revenue_generated,
	COUNT(C.customer_id) AS assigned_clients,
	ROUND(SUM(I.total) / COUNT(C.customer_id), 2) revenue_per_client
FROM invoice AS I
	INNER JOIN customer AS C ON C.customer_id = I.customer_id
	INNER JOIN employee AS E ON E.employee_id = C.support_rep_id
GROUP BY employee_name
ORDER BY revenue_generated DESC, assigned_clients DESC
LIMIT 1;

-- 5. Churn analysis: What percentage of customers didn't purchase again after 6 months.
WITH customer_last_purchase AS (
	SELECT C.customer_id, MAX(I.invoice_date) AS last_purchase
	FROM invoice AS I
		INNER JOIN customer AS C ON C.customer_id = I.customer_id
	WHERE I.invoice_date < (NOW() + INTERVAL '1 day')
	GROUP BY C.customer_id
)

SELECT (COUNT(customer_id)::DECIMAL::DECIMAL/(SELECT COUNT(DISTINCT customer_id) FROM invoice)::DECIMAL) * 100 AS percent_churn
FROM customer_last_purchase
WHERE EXTRACT(YEARS FROM AGE(NOW(), last_purchase)) > 0
	OR EXTRACT(MONTHS FROM AGE(NOW(), last_purchase)) >= 6;

-- 6. Outliers detection in invoice amounts over Q3 + 1.5×IQR
SELECT COUNT(invoice_id) AS total_outliers
FROM invoice 
WHERE total > get_top_limit();

-- 7. Customers with thew highest  year-over-year spending growth
CREATE EXTENSION IF NOT EXISTS tablefunc;

WITH customer_spending_year AS (
	SELECT * FROM crosstab(
		'SELECT C.customer_id, 
			EXTRACT(YEAR FROM I.invoice_date) AS invoice_year,
			SUM(I.total) AS total_year
		FROM invoice AS I
			INNER JOIN customer AS C ON C.customer_id = I.customer_id
		WHERE EXTRACT(YEAR FROM I.invoice_date) <> EXTRACT(YEAR FROM NOW())
		GROUP BY C.customer_id, invoice_year
		ORDER BY 1',
		'SELECT DISTINCT EXTRACT(YEAR FROM invoice_date) AS invoice_year
		FROM invoice
		WHERE EXTRACT(YEAR FROM invoice_date) <> EXTRACT(YEAR FROM NOW())
		ORDER BY 1'
	) AS CT (
		customer_id INT,
		total_2021 NUMERIC,
		total_2022 NUMERIC,
		total_2023 NUMERIC,
		total_2024 NUMERIC
	)
)

SELECT customer_id,
	ROUND(((COALESCE(total_2022, 0) - COALESCE(total_2021, 0)) / COALESCE(total_2021, 1)) * 100, 2) AS first_year,
	ROUND(((COALESCE(total_2023, 0) - COALESCE(total_2022, 0)) / COALESCE(total_2022, 1)) * 100, 2) AS second_year,
	ROUND(((COALESCE(total_2024, 0) - COALESCE(total_2023, 0)) / COALESCE(total_2023, 1)) * 100, 2) AS third_year,
	ROUND(((COALESCE(total_2021, 0) - COALESCE(total_2024, 0)) / COALESCE(total_2021, 1)) * 100, 2) AS overall_growth
FROM customer_spending_year;

-- 8. Market basket analysis: Tracks which usually sell together (pairwise)
WITH track_pairs AS (
	SELECT IL.invoice_id, IL.track_id AS track_id1, IL2.track_id AS  track_id2
	FROM invoice_line AS IL
		INNER JOIN invoice_line AS IL2 ON IL2.invoice_id = IL.invoice_id
			AND IL.track_id < IL2.track_id
	ORDER BY IL.invoice_id, IL.track_id, IL2.track_id
)

SELECT track_id1, track_id2, COUNT(invoice_id) AS times_bought_together
FROM track_pairs
GROUP BY track_id1, track_id2
ORDER BY times_bought_together DESC
LIMIT 10;