/*About this Database
You are looking at data from an e-commerce website. The site is very simple and has 
just 4 pages:
a) The first page is the home page. When you come to the site for the first time, 
you can only land on the home page as a first page.
b) From the home page, the user can perform a search and land on the search page.
c) From the search page, if the user clicks on a product, she will get to the payment 
page, where she is asked to provide payment information in order to buy that product.
d) If she does decide to buy, she ends up on the confirmation page

The company CEO isn't very happy with the volume of sales and, especially, of sales 
coming from new users. Therefore, she asked you to investigate whether there is 
something wrong in the conversion funnel or, in general, if you could suggest how 
conversion rate can be improved.
*/

-- How many users visited the website
SELECT COUNT(DISTINCT user_id)
FROM user_table;
-- 90400 distinct users. The datasets consists of one time users only!

-- The website has a desktop and mobile versions
SELECT COUNT(CASE WHEN device='Desktop' THEN 1 ELSE NULL END) as 'Desktop',
       COUNT(CASE WHEN device='Mobile' THEN 1 ELSE NULL END) as 'Mobile'
FROM user_table;
-- 60200 users (66.6%) visited the desktop version,  
-- the rest, namely 30200 (33.4%), used the mobile version

-- Distribution by gender
SELECT COUNT(CASE WHEN sex='Female' THEN 1 ELSE NULL END) as 'Female',
       COUNT(CASE WHEN sex='Male' THEN 1 ELSE NULL END) as 'Male',
	   ROUND(100.*COUNT(CASE WHEN sex='Female' THEN 1 ELSE NULL END)/COUNT(*),2) as pct_female,
	   ROUND(100.*COUNT(CASE WHEN sex='Male' THEN 1 ELSE NULL END)/COUNT(*),2) as pct_male
FROM user_table;
-- 45075 users (49.9%) were female, 45325 (50.1%) were male.

-- Let's count visits of the search, payment and confirmation pages
SELECT COUNT(DISTINCT user_id)
FROM search_page_table;
--search: 45200

SELECT COUNT(DISTINCT user_id)
FROM payment_page_table;
--payment: 6030

SELECT COUNT(DISTINCT user_id)
FROM payment_confirmation_table;
--confirmation: 452

--The data was collected during four months from 2015-01-01 to 2015-04-30

-- What are the daily user counts?
SELECT date, COUNT(DISTINCT user_id) as 'Users'
FROM user_table
GROUP BY 1;
-- The daily visitor counts change with time (see figure 'daily_visitor_counts.png'. 
-- It seems, however, that in February, the website was daily visited more often
-- than in other months. Let's check it by computing the mean daily visits for each month.

WITH tmp
AS	(
	SELECT date, COUNT(DISTINCT user_id) as 'Users'
	FROM user_table
	GROUP BY 1
)
SELECT strftime('%m', date) as 'month', AVG(users)
FROM tmp
GROUP BY 1
ORDER BY 1;
-- Yes, indeed, on average 807 users per day in Feb, 729 in Jan and March 
-- and 753 in April 

-- What about the total numbers of visits per months? 
SELECT CASE
	WHEN strftime('%m', date) = '01' THEN 'Jan'
	WHEN strftime('%m', date) = '02' THEN 'Feb'
	WHEN strftime('%m', date) = '03' THEN 'Mar'
	WHEN strftime('%m', date) = '04' THEN 'Apr'
	END as 'month', COUNT(DISTINCT user_id)
FROM user_table
GROUP BY 1;
-- Hmm... allthough the mean daily visits vary with month, the total monthly visits 
-- remain exactly the same for all months: 22600. Suspicious!  The high daily visits
-- in February are compencated by the small number of days.

-- Any dependences on gender and device of the total monthly visitor counts? 
SELECT CASE
	WHEN strftime('%m', date) = '01' THEN '01.Jan'
	WHEN strftime('%m', date) = '02' THEN '02.Feb'
	WHEN strftime('%m', date) = '03' THEN '03.Mar'
	WHEN strftime('%m', date) = '04' THEN '04.Apr'
	END as 'month', 
	COUNT(CASE WHEN sex = 'Female' THEN 1 ELSE NULL END) as 'Female',
	COUNT(CASE WHEN sex = 'Male' THEN 1 ELSE NULL END) as 'Male'
FROM user_table
GROUP BY 1 ; 
-- the numbers of female and male visitors almost remain the same

SELECT CASE
	WHEN strftime('%m', date) = '01' THEN '01.Jan'
	WHEN strftime('%m', date) = '02' THEN '02.Feb'
	WHEN strftime('%m', date) = '03' THEN '03.Mar'
	WHEN strftime('%m', date) = '04' THEN '04.Apr'
	END as 'month', 
	COUNT(CASE WHEN device = 'Desktop' THEN 1 ELSE NULL END) as 'PC',
	COUNT(CASE WHEN device = 'Mobile' THEN 1 ELSE NULL END) as 'Mobile'
FROM user_table
GROUP BY 1 ; 
-- The monthly visitor counts of the desktop and mobile versions of the website 
-- did not change with time: 15500 vs 7550 

-- Let's now compute the conversion rates: 
-- from home to search: pct_h_to_s 
-- from search to payment: pct_s_to_p
-- from payment to confirmation: pct_p_to_c 
WITH tmp 
AS	(
	SELECT u.user_id, u.date, u.device, u.sex, 
		h.page IS NOT NULL as 'home_page', s.page IS NOT NULL as 'search_page', 
		p.page IS NOT NULL as 'payment_page', c.page IS NOT NULL as 'confirmation_page'
	FROM user_table as 'u'
		LEFT JOIN home_page_table as 'h' ON u.user_id = h.user_id  
		LEFT JOIN search_page_table as 's' ON h.user_id = s.user_id
		LEFT JOIN payment_page_table as 'p' ON s.user_id = p.user_id
		LEFT JOIN payment_confirmation_table as 'c' ON p.user_id = c.user_id
	)
SELECT date, SUM(home_page) as 'num_home', SUM(search_page) as 'num_search',
	SUM(payment_page) as 'num_payment', SUM(confirmation_page) as 'num_confirmation',
	100*SUM(search_page)/SUM(home_page) as 'pct_h_to_s', 
	100*SUM(payment_page)/SUM(search_page) as 'pct_s_to_p',
	100*SUM(confirmation_page)/SUM(payment_page) as 'pct_p_to_c'
FROM tmp
GROUP BY date; 
/*
as seen from figure 'funnel_over_time.png' the conversion rate h_to_s
felt down dramatically after February 28th (from ~60% to ~39%);
the conversion rate s_to_p shows a similar trend (a drop from ~18% to 8%);
the p_to_c rate did not change considerably (perhaps, rose in April).
As a result, due to severe problems with h_to_s and s_to_p transitions, 
the number of customers who completed the journey towards the purchase sharply
reduced in March and April compared to January and February  
*/ 

-- the computed monthly conversion rates (figure 'funnels_monthly.png') support the above observation
WITH tmp 
AS	(
	SELECT u.user_id, u.date, u.device, u.sex, 
		h.page IS NOT NULL as 'home_page', s.page IS NOT NULL as 'search_page', 
		p.page IS NOT NULL as 'payment_page', c.page IS NOT NULL as 'confirmation_page'
	FROM user_table as 'u'
		LEFT JOIN home_page_table as 'h' ON u.user_id = h.user_id  
		LEFT JOIN search_page_table as 's' ON h.user_id = s.user_id
		LEFT JOIN payment_page_table as 'p' ON s.user_id = p.user_id
		LEFT JOIN payment_confirmation_table as 'c' ON p.user_id = c.user_id
	),
tmp2 
AS	(
	SELECT date, 
		100*SUM(search_page)/SUM(home_page) as 'pct_h_to_s', 
		100*SUM(payment_page)/SUM(search_page) as 'pct_s_to_p',
		100*SUM(confirmation_page)/SUM(payment_page) as 'pct_p_to_c'
	FROM tmp
	GROUP BY date
	)
SELECT CASE
	WHEN strftime('%m', date) = '01' THEN '01.Jan'
	WHEN strftime('%m', date) = '02' THEN '02.Feb'
	WHEN strftime('%m', date) = '03' THEN '03.Mar'
	WHEN strftime('%m', date) = '04' THEN '04.Apr'
	END as 'month',	
	AVG(pct_h_to_s) as 'avg_pct_h_to_s', AVG(pct_s_to_p) as 'avg_pct_s_to_p', AVG(pct_p_to_c) as 'avg_pct_p_to_c'
FROM tmp2
GROUP BY 1
ORDER BY 1; 

-- The patterns are not significantly different for the female and male visitors (not shown) 
-- suggesting that the different conversion rates and their time dependence are sooner
-- driven by the website appearance rather than by the visitors' gender.

-- Let's examine whether the conversion rates have any dependence on the website version
-- The following two queries give us the monthly mean conversion rates for the
-- desktop and mobile versions (figures: 'funnels_monthly_desktop.png' and 'funnels_monthly_mobile.png')
WITH tmp 
AS	(
	SELECT u.user_id, u.date, u.sex, 
		h.page IS NOT NULL as 'home_page', s.page IS NOT NULL as 'search_page', 
		p.page IS NOT NULL as 'payment_page', c.page IS NOT NULL as 'confirmation_page'
	FROM user_table as 'u'
		LEFT JOIN home_page_table as 'h' ON u.user_id = h.user_id  
		LEFT JOIN search_page_table as 's' ON h.user_id = s.user_id
		LEFT JOIN payment_page_table as 'p' ON s.user_id = p.user_id
		LEFT JOIN payment_confirmation_table as 'c' ON p.user_id = c.user_id
	WHERE device = 'Desktop'
	),
tmp2 
AS	(
	SELECT date, 
		100*SUM(search_page)/SUM(home_page) as 'pct_h_to_s', 
		100*SUM(payment_page)/SUM(search_page) as 'pct_s_to_p',
		100*SUM(confirmation_page)/SUM(payment_page) as 'pct_p_to_c'
	FROM tmp
	GROUP BY date
	)
SELECT CASE
	WHEN strftime('%m', date) = '01' THEN '01.Jan'
	WHEN strftime('%m', date) = '02' THEN '02.Feb'
	WHEN strftime('%m', date) = '03' THEN '03.Mar'
	WHEN strftime('%m', date) = '04' THEN '04.Apr'
	END as 'month',	
	AVG(pct_h_to_s) as 'avg_pct_h_to_s', AVG(pct_s_to_p) as 'avg_pct_s_to_p', AVG(pct_p_to_c) as 'avg_pct_p_to_c'
FROM tmp2
GROUP BY 1
ORDER BY 1;

WITH tmp 
AS	(
	SELECT u.user_id, u.date, u.sex, 
		h.page IS NOT NULL as 'home_page', s.page IS NOT NULL as 'search_page', 
		p.page IS NOT NULL as 'payment_page', c.page IS NOT NULL as 'confirmation_page'
	FROM user_table as 'u'
		LEFT JOIN home_page_table as 'h' ON u.user_id = h.user_id  
		LEFT JOIN search_page_table as 's' ON h.user_id = s.user_id
		LEFT JOIN payment_page_table as 'p' ON s.user_id = p.user_id
		LEFT JOIN payment_confirmation_table as 'c' ON p.user_id = c.user_id
	WHERE device = 'Mobile'
	),
tmp2 
AS	(
	SELECT date, 
		100*SUM(search_page)/SUM(home_page) as 'pct_h_to_s', 
		100*SUM(payment_page)/SUM(search_page) as 'pct_s_to_p',
		100*SUM(confirmation_page)/SUM(payment_page) as 'pct_p_to_c'
	FROM tmp
	GROUP BY date
	)
SELECT CASE
	WHEN strftime('%m', date) = '01' THEN '01.Jan'
	WHEN strftime('%m', date) = '02' THEN '02.Feb'
	WHEN strftime('%m', date) = '03' THEN '03.Mar'
	WHEN strftime('%m', date) = '04' THEN '04.Apr'
	END as 'month',	
	AVG(pct_h_to_s) as 'avg_pct_h_to_s', AVG(pct_s_to_p) as 'avg_pct_s_to_p', AVG(pct_p_to_c) as 'avg_pct_p_to_c'
FROM tmp2
GROUP BY 1
ORDER BY 1;
/* By looking at the monthly conversion rates for the desktop and mobile versions 
as well as the sum thereof, one can make the following conclusions:

1. The peculiar behavior of the h_to_s conversion rate with time, in particular
its dramatic drop in Marth and April bears its origin from the mobile version.
The h_to_s conversion rate in the desktop version exhibits only a slight dependence 
on time being appr. 50% for each month, while in the mobile version it dropped 
from 79% to 20% in March. The search bottom in the mobile version likely stopped 
working or started working improperly in March.  

2. The s_to_p conversion rate is also specific. Its peculiar behavior with time is
attributed to the desktop version (in the mobile version this conversion rate remains 
the same over time ~20%). This could be due to a problem with adding a selected product 
to the cart which was created in the desktop version in March.

3. The p_to_c conversion rates show only a slight dependence on month in all figures
   
*/
