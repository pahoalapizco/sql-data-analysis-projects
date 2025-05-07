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
FROM rfm_concat_scores

