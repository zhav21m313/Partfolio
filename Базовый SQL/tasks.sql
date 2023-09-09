---

SELECT COUNT(status)
FROM company
WHERE status='closed'

---

SELECT funding_total
FROM company
WHERE category_code='news' AND country_code='USA'
ORDER BY funding_total DESC

---

SELECT SUM(price_amount)
FROM acquisition 
WHERE EXTRACT(YEAR FROM CAST(acquired_at AS date)) BETWEEN '2011' AND '2013'AND term_code='cash'

---

SELECT p.first_name,
        p.last_name,
        p.twitter_username
FROM people AS p
WHERE  CAST(p.twitter_username AS varchar) LIKE 'Silver%'

---

SELECT *
FROM people 
WHERE CAST(twitter_username AS varchar) LIKE '%money%'
      AND CAST(last_name AS varchar) LIKE 'K%'
---

SELECT country_code,
       SUM(funding_total)
FROM company
GROUP BY country_code
ORDER BY SUM(funding_total) DESC

---

SELECT funded_at,
        MIN(raised_amount ),
        MAX(raised_amount )
FROM funding_round
GROUP BY funded_at
HAVING (MIN(raised_amount)!=0)
       AND (MIN(raised_amount )!= MAX(raised_amount ))
---

SELECT *,
    CASE 
        WHEN invested_companies>=100 THEN 'high_activity'
        WHEN invested_companies>=20 AND invested_companies<100 THEN 'middle_activity'
        WHEN invested_companies<20 THEN 'low_activity'
  END
FROM fund

---

SELECT    
       CASE
           WHEN invested_companies>=100 THEN 'high_activity'
           WHEN invested_companies>=20 THEN 'middle_activity'
           ELSE 'low_activity'
       END AS activity ,
       ROUND(AVG(investment_rounds))
FROM fund
GROUP BY activity
ORDER BY ROUND(AVG(CAST(investment_rounds AS INTEGER))) 

---

SELECT country_code,
        MAX(invested_companies ),
        MIN(invested_companies ),
        AVG(invested_companies )
FROM fund
WHERE 
EXTRACT(YEAR FROM CAST(founded_at  AS date)) BETWEEN '2010' AND '2012'
GROUP BY country_code
HAVING MIN(invested_companies)!=0
ORDER BY AVG(invested_companies) DESC,
    country_code 
limit 10

---

SELECT p.first_name,
        p.last_name,
        e.instituition
FROM people as p
LEFT JOIN education AS e ON p.id=e.person_id

---

SELECT c.name,
   COUNT(DISTINCT e.instituition)
FROM company AS c
 JOIN people AS  p ON c.id=p.company_id
 JOIN education AS e ON p.id=e.person_id
GROUP BY c.name
ORDER BY COUNT(DISTINCT e.instituition) DESC
LIMIT 5

---

SELECT DISTINCT name
FROM company  
WHERE status LIKE 'closed'
    AND id in ( SELECT company_id
               FROM funding_round
               WHERE is_first_round=1
               AND is_last_round=1)
---

SELECT p.id 
FROM company AS c
JOIN funding_round AS f ON c.id=f.company_id
JOIN people AS p ON c.id=p.company_id
WHERE c.status = 'closed'and
f.is_first_round='1'
AND f.is_last_round= '1'
GROUP BY p.id 

---

SELECT p.id,
e.instituition
FROM people AS p
LEFT JOIN education AS e ON p.id = e.person_id
WHERE p.company_id IN
(SELECT c.id
FROM company AS c
JOIN funding_round AS fr ON c.id = fr.company_id
WHERE STATUS ='closed'
AND is_first_round = 1
AND is_last_round = 1
GROUP BY c.id)
GROUP BY p.id, e.instituition
HAVING instituition IS NOT NULL;

---

 SELECT p.id ,
COUNT(e.instituition)
FROM people AS p
LEFT JOIN education AS e ON p.id = e.person_id
WHERE p.company_id IN
        (SELECT c.id
        FROM company AS c
        JOIN funding_round AS fr ON c.id = fr.company_id
        WHERE STATUS ='closed'
                    AND is_first_round = 1
                    AND is_last_round = 1
        GROUP BY c.id)
GROUP BY p.id
HAVING COUNT(DISTINCT e.instituition)>0

---

WITH

a AS (SELECT p.id,
COUNT(e.instituition) 
FROM people AS p
LEFT JOIN education AS e ON p.id = e.person_id
WHERE p.company_id IN
        (SELECT c.id
        FROM company AS c
        JOIN funding_round AS fr ON c.id = fr.company_id
        WHERE STATUS ='closed'
                    AND is_first_round = 1
                    AND is_last_round = 1
        GROUP BY c.id)
        GROUP BY p.id
HAVING COUNT(DISTINCT e.instituition)>0)

SELECT AVG(COUNT)
FROM a

---

SELECT f.name AS name_of_fund,
c.name AS name_of_company,
fr.raised_amount AS amount
FROM investment AS i
LEFT JOIN company AS c ON c.id = i.company_id
LEFT JOIN fund AS f ON i.fund_id = f.id
INNER JOIN 
(SELECT*
FROM funding_round
WHERE funded_at BETWEEN '2012-01-01' AND '2013-12-31')
AS fr ON fr.id = i.funding_round_id
WHERE c.milestones > 6;

---


WITH acquiring AS
(SELECT c.name AS buyer,
a.price_amount AS price,
a.id AS KEY
FROM acquisition AS a
LEFT JOIN company AS c ON a.acquiring_company_id = c.id
WHERE a.price_amount > 0),
acquired AS
(SELECT c.name AS acquisition,
c.funding_total AS investment,
a.id AS KEY
FROM acquisition AS a
LEFT JOIN company AS c ON a.acquired_company_id = c.id
WHERE c.funding_total > 0)
SELECT acqn.buyer,
acqn.price,
acqd.acquisition,
acqd.investment,
ROUND(acqn.price / acqd.investment) AS uplift
FROM acquiring AS acqn
JOIN acquired AS acqd ON acqn.KEY = acqd.KEY
ORDER BY price DESC, acquisition
LIMIT 10;

---

SELECT  c.name AS social_co,
EXTRACT (MONTH FROM fr.funded_at) AS funding_month
FROM company AS c
LEFT JOIN funding_round AS fr ON c.id = fr.company_id
WHERE c.category_code = 'social'
AND fr.funded_at BETWEEN '2010-01-01' AND '2013-12-31'
AND fr.raised_amount <> 0;

---

WITH fundings AS
(SELECT EXTRACT(MONTH FROM CAST(fr.funded_at AS DATE)) AS funding_month,
COUNT(DISTINCT f.id) AS us_funds
FROM fund AS f
LEFT JOIN investment AS i ON f.id = i.fund_id
LEFT JOIN funding_round AS fr ON i.funding_round_id = fr.id
WHERE f.country_code = 'USA'
AND EXTRACT(YEAR FROM CAST(fr.funded_at AS DATE)) BETWEEN 2010 AND 2013
GROUP BY funding_month),
acquisitions AS
(SELECT EXTRACT(MONTH FROM CAST(acquired_at AS DATE)) AS funding_month,
COUNT(acquired_company_id) AS bought_co,
SUM(price_amount) AS sum_total
FROM acquisition
WHERE EXTRACT(YEAR FROM CAST(acquired_at AS DATE)) BETWEEN 2010 AND 2013
GROUP BY funding_month)
SELECT fnd.funding_month, fnd.us_funds, acq.bought_co, acq.sum_total
FROM fundings AS fnd
LEFT JOIN acquisitions AS acq ON fnd.funding_month = acq.funding_month;

---

WITH y_11 AS
(SELECT country_code AS country,
AVG(funding_total) AS y_2011
FROM company
WHERE EXTRACT(YEAR FROM founded_at::DATE) IN(2011, 2012, 2013)
GROUP BY country, EXTRACT(YEAR FROM founded_at)
HAVING EXTRACT(YEAR FROM founded_at) = '2011'),
y_12 AS
(SELECT country_code AS country,
AVG(funding_total) AS y_2012
FROM company
WHERE EXTRACT(YEAR FROM founded_at::DATE) IN(2011, 2012, 2013)
GROUP BY country, EXTRACT(YEAR FROM founded_at)
HAVING EXTRACT(YEAR FROM founded_at) = '2012'),
y_13 AS
(SELECT country_code AS country,
AVG(funding_total) AS y_2013
FROM company
WHERE EXTRACT(YEAR FROM founded_at::DATE) IN(2011, 2012, 2013)
GROUP BY country, EXTRACT(YEAR FROM founded_at)
HAVING EXTRACT(YEAR FROM founded_at) = '2013')
SELECT y_11.country, y_2011, y_2012, y_2013
FROM y_11
JOIN y_12 ON y_11.country = y_12.country
JOIN y_13 ON y_12.country = y_13.country
ORDER BY y_2011 DESC;
