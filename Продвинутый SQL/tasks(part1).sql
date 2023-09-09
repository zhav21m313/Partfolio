---
SELECT COUNT(id)
FROM stackoverflow.posts 
WHERE post_type_id=1 AND(score>300 OR favorites_count>=100)

---

WITH p AS (
SELECT COUNT(title) AS sd,
DATE_TRUNC('DAY',creation_date::date)
FROM stackoverflow.posts 
WHERE CAST(creation_date AS date) BETWEEN '01-11-2008' AND '18-11-2008'
GROUP BY DATE_TRUNC('DAY',creation_date::date))

SELECT ROUND(AVG(sd))
FROM p

---

SELECT COUNT(DISTINCT b.user_id)
FROM stackoverflow.badges AS b
JOIN stackoverflow.users AS u ON u.id=b.user_id
WHERE u.creation_date::date = b.creation_date::date

---

WITH sp AS (
SELECT ps.id AS sd
      FROM stackoverflow.posts AS ps
      JOIN stackoverflow.votes AS v ON ps.id=v.post_id
      JOIN stackoverflow.users AS u ON ps.user_id=u.id
      WHERE u.display_name LIKE 'Joel Coehoorn' AND v.id > 0
      GROUP BY ps.id)
      
SELECT COUNT(sd)
FROM sp

---

SELECT * ,
ROW_NUMBER() OVER (ORDER BY id DESC) AS rank
FROM stackoverflow.vote_types
ORDER BY 

---

WITH pop AS(
SELECT v.user_id ,
COUNT(t.id)  AS ksd      
FROM stackoverflow.votes AS v
JOIN stackoverflow.vote_types AS t ON v.vote_type_id=t.id
WHERE t.name LIKE 'Close'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10)

SELECT *
FROM pop
ORDER BY pop.ksd DESC, pop.user_id DESC

---

SELECT *,
      DENSE_RANK() OVER (ORDER BY b.b_cnt DESC) AS rating
FROM (SELECT user_id,
             COUNT(id) AS b_cnt
      FROM stackoverflow.badges
      WHERE creation_date::date BETWEEN '2008-11-15' AND '2008-12-15' 
      GROUP BY user_id
      ORDER BY b_cnt DESC, user_id LIMIT 10) as b;

---

WITH asd
AS(
SELECT title,
user_id,
score,
AVG(score) OVER(PARTITION BY user_id) AS pip
FROM stackoverflow.posts
WHERE title NOT LIKE ''
    AND score!=0)
    
    SELECT title,
user_id,
score,
ROUND(pip)
FROM asd

---

SELECT
p.title
FROM stackoverflow.posts AS p
JOIN stackoverflow.users AS u ON p.user_id=u.id
JOIN stackoverflow.badges AS b ON u.id=b.user_id
WHERE p.title NOT LIKE ''
GROUP BY p.title
HAVING COUNT(b.id)>1000

---

SELECT id,
       views,
       CASE
          WHEN views >= 350 THEN 1
          WHEN views < 100 THEN 3
          ELSE 2
       END 
FROM stackoverflow.users
WHERE location LIKE '%United States%' AND views > 0;

---

WITH grp AS (SELECT g.id,
                    g.views,
                    g.group,
                    MAX(g.views) OVER (PARTITION BY g.group) AS max     
             FROM (SELECT id,
                          views,
                          CASE
                             WHEN views >= 350 THEN 1
                             WHEN views < 100 THEN 3
                             ELSE 2
                          END AS group
                   FROM stackoverflow.users
                   WHERE location LIKE '%United States%' AND views > 0) as g
              )
  
SELECT grp.id, 
       grp.views,  
       grp.group
FROM grp
WHERE grp.views = grp.max
ORDER BY grp.views DESC, grp.id;

---

WITH pip AS

(
SELECT 
EXTRACT(DAY FROM creation_date::date) AS days,
COUNT(id) AS ids
FROM stackoverflow.users AS u
WHERE u.creation_date::date  BETWEEN '01-11-2008' AND '30-11-2008'
GROUP BY 1)

SELECT *,
SUM(p.ids) OVER(ORDER BY p.days)
FROM pip AS p

---

WITH dt AS (SELECT DISTINCT user_id,
                            MIN(creation_date) OVER (PARTITION BY user_id) AS min_dt      
            FROM stackoverflow.posts)

SELECT dt.user_id,
       (dt.min_dt - u.creation_date) AS diff
FROM stackoverflow.users AS u 
JOIN dt ON  u.id = dt.user_id;

---

