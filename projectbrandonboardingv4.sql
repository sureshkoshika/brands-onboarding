 --total brands/asin enrolled
 
 SELECT  COUNT(DISTINCT(a.brand_name)) AS Total_Brands
       , COUNT(a.asin) AS Total_ASINs
 FROM onboarded_asins a;

-- No. of ASINS/ Brands enrolled week on week (last 10 weeks only)

SELECT   COUNT(asin) AS ASINs_Published
       , COUNT(DISTINCT(brand_name)) AS Brands_enrolled
       , extract(week from(published_date)) AS week_number
       , extract(year from(published_date)) as year
FROM onboarded_asins
where TRUNC(DATE_PART('day', CURRENT_DATE::timestamp - (published_date)::timestamp)/7) <=10
GROUP BY extract(week from(published_date)), extract(year from(published_date))
ORDER BY 4;

 
 
 --  asin level FEEDBACK STATUS percentage
 
SELECT  brand_feedback
     , COUNT(asin) AS ASINs_enrolled
     , CONCAT(COUNT(brand_feedback)*100/
       (SELECT 
		COUNT(b1.asin) 
		FROM onboarded_asins b1),'%') AS ASIN_feedback_Percentage
FROM onboarded_asins
GROUP BY brand_feedback
ORDER BY brand_feedback;

-- region wise brands enrolled

select brand_region
     , COUNT(DISTINCT(brand_name)) Region_wise_brands_enrolment
from onboarded_asins 
GROUP BY brand_region;

 -- brand level feedback status
 
SELECT  brand_feedback
     , COUNT(distinct(brand_name)) AS Brands_onboarded
     , CONCAT(COUNT(distinct(brand_name))*100/
        (SELECT
		 COUNT(distinct(brand_name))
		 FROM onboarded_asins b1),'%') AS brand_feedback_Percentage
FROM onboarded_asins
GROUP BY brand_feedback
ORDER BY brand_feedback;
 
 
 -- last five weeks data - Brand/ASIN wise breakdown as per feedback status from respective brands:

WITH 
	 approved (week_number,approved_asins) as
	 (
	 SELECT DATE_PART('week',(a.published_date)) as week_number
		 , count(a.asin) approved_asins
		 , count(distinct(a.brand_name)) approved_brands
		 , extract(year from(a.published_date)) as year
     FROM onboarded_asins a
     WHERE a.brand_feedback ILIKE 'Approved'
     AND
     TRUNC(DATE_PART('day', CURRENT_DATE::timestamp - (a.published_date)::timestamp)/7) <=5 
     GROUP BY  week_number, year
	 Order by year
	 )
	 , rejected (week_number,rejected_asins) as
	 (
	 SELECT DATE_PART('week',(b.published_date)) as week_number
		 , count(b.asin) as rejected_asins
		 , count(distinct(b.brand_name)) rejected_brands
		 , extract(year from(b.published_date)) as year
     FROM onboarded_asins b
     WHERE b.brand_feedback ILIKE 'Rejected'
     AND
      TRUNC(DATE_PART('day', CURRENT_DATE::timestamp - (b.published_date)::timestamp)/7) <=5 
      GROUP BY  week_number, year
	  Order by year
	 )
	 , Require_modification (week_number,modification_requested_asins) as
	 (
	 SELECT  DATE_PART('week',(c.published_date)) as week_number
		 , count(c.asin) as modification_requested_asins
		 , count(distinct(c.brand_name)) modification_requested_brands
		 , extract(year from(c.published_date)) as year
     FROM onboarded_asins c
     WHERE brand_feedback ILIKE '%modification%'
     AND
     TRUNC(DATE_PART('day', CURRENT_DATE::timestamp - (published_date)::timestamp)/7) <=5 
     GROUP BY  week_number, year
     Order by year
	 )
	 , Under_brand_review (week_number,under_brand_review_asins) as
	 (
	  SELECT  DATE_PART('week',(d.published_date)) as week_number
		 , count(d.asin)  as under_brand_review_asins
		 , count(distinct(d.brand_name)) under_brand_review_brands
		 , extract(year from(d.published_date)) as year
      FROM onboarded_asins d
     WHERE brand_feedback ILIKE '%review%'
      AND
      TRUNC(DATE_PART('day', CURRENT_DATE::timestamp - (d.published_date)::timestamp)/7) <=5 
      GROUP BY  week_number, year
	  Order by year
	 )
  , total_onboarded (onboarded_asins,Onboarded_brands,week_number,year) as
 ( select  COUNT(asin) as onboarded_asins
	   , count(distinct(brand_name)) as Onboarded_brands
       , DATE_PART('week',(published_date)) week_number
	   , extract(year from(published_date)) as year
   from onboarded_asins 
   WHERE TRUNC(DATE_PART('day', CURRENT_DATE::timestamp - (published_date)::timestamp)/7) <=5 
   GROUP BY week_number,year
   order by year)
		 
select 
 ('Week' || t.week_number) as Week_number
  , t.onboarded_asins
  , t.onboarded_brands
  , COALESCE(a.approved_asins,0) as Approved_asins
  , COALESCE(a.approved_brands,0) as Approved_brands
  , COALESCE(r.rejected_asins,0) as Rejected_asins
  , COALESCE(r.rejected_brands,0) as Rejected_brands
  , COALESCE(rm.modification_requested_asins,0) as Modification_requested_asins
  , COALESCE(rm.modification_requested_brands,0) as Modification_requested_brands
  , COALESCE(ur.under_brand_review_asins,0) as Under_brand_review_asins
  , COALESCE(ur.under_brand_review_brands,0) as Under_brand_review_brands
	 from total_onboarded t
     left join approved a
	 on t.week_number=a.week_number
	 full outer join rejected r
	 on t.week_number=r.week_number
	 full outer join Require_modification rm
	 on t.week_number=rm.week_number
     full outer join Under_brand_review ur
	 on t.week_number=ur.week_number
	 ORDER BY t.week_number;
 


-- modification table. here, first row consists of total data till date.

(WITH 
image(week_number,image_modification,year) as
  (select 
  DATE_PART('week',(published_date)) as week_number
  , count(image_modification) image_modification
  , extract(year from(published_date)) as year
  from onboarded_asins
  where image_modification = 'Yes'
  and   TRUNC(DATE_PART('day', CURRENT_DATE::timestamp - (published_date)::timestamp)/7) <=5
  and image_status ILIKE 'Published'
  GROUP BY  week_number, year
  order by year) 
, text(week_number,text_modification,year) as
  (select 
  DATE_PART('week',(published_date)) as week_number
  , count(text_modification) text_modification
  , extract(year from(published_date)) as year
  from onboarded_asins
  where text_modification = 'Yes'
  and   TRUNC(DATE_PART('day', CURRENT_DATE::timestamp - (published_date)::timestamp)/7) <=5 
  and text_status ILIKE 'Published'
  GROUP BY  week_number, year
  order by year) 
, video (week_number,video_modification,year) as
  (select 
  DATE_PART('week',(published_date)) as week_number
  , count(video_modification) video_modification
  , extract(year from(published_date)) as year
  from onboarded_asins
  where video_modification = 'Yes'
  and   TRUNC(DATE_PART('day', CURRENT_DATE::timestamp - (published_date)::timestamp)/7) <=5
  and video_upload_status ILIKE 'Published'
  GROUP BY  week_number, year
  order by year) 
, promotion (week_number,promotion_modification,year) as
  (select 
  DATE_PART('week',(published_date)) as week_number
  , count(promotion_modification) promotion_modification
  , extract(year from(published_date)) as year
  from onboarded_asins
  where promotion_modification = 'Yes'
  AND   TRUNC(DATE_PART('day', CURRENT_DATE::timestamp - (published_date)::timestamp)/7) <=5
  AND  promotion_status ILIKE 'Published'
  GROUP BY  week_number, year
   order by year) 
, tot_required_modification (week_number,total_Require_modification,year) as
	(
   select 
   DATE_PART('week',(published_date)) as week_number
  , COUNT(brand_feedback) total_Require_modification
  , extract(year from(published_date)) as year
  from onboarded_asins
  where brand_feedback ILIKE '%Modification%'
  and   TRUNC(DATE_PART('day', CURRENT_DATE::timestamp - (published_date)::timestamp)/7) <=5
  and image_status ILIKE 'Published'
  and text_status ILIKE 'Published'
  and video_upload_status ILIKE 'Published'
  and promotion_status ILIKE 'Published'
  GROUP BY  week_number, year
  order by year)
, total_onboarded (onboarded_asins,week_number,year) as
(
SELECT 
        COUNT(asin) as onboarded_asins
       , DATE_PART('week',(published_date)) week_number
	   , extract(year from(published_date)) as year
   from onboarded_asins 
   WHERE TRUNC(DATE_PART('day', CURRENT_DATE::timestamp - (published_date)::timestamp)/7) <=5 
   GROUP BY week_number,year
   order by year
)

select 
     ('Week' || o.week_number) as T4weeks
	 , o.onboarded_asins
	 , COALESCE(tr.total_Require_modification,0) total_Require_modification
	 , COALESCE(i.image_modification,0) image_modification
	 , COALESCE(t.text_modification,0) text_modification
	 , COALESCE(v.video_modification,0) video_modification
	 , COALESCE(p.promotion_modification,0) promotion_modification
from total_onboarded o
left join image i
on o.week_number=i.week_number
full outer join text t
on o.week_number=t.week_number
full outer join video v
on o.week_number=v.week_number
full outer join promotion p
on o.week_number=p.week_number
full outer join tot_required_modification tr
on o.week_number=tr.week_number
order by o.year
) 
UNION
(
WITH 
Total_Image_Modification (total,Total_Image_Modification_requested) as
   (
    SELECT  1 as total
    , Count(image_modification) Total_Image_Modification_requested
	from onboarded_asins
	where image_modification ILIKE 'Yes'
	) 
, Total_text_Modification (total,Total_text_Modification_requested) as
   (
    SELECT  1 as total
    , Count(text_modification) Total_text_Modification_requested
	from onboarded_asins
	where text_modification ILIKE 'Yes'
	)
, Total_Video_Modification (total,Total_Video_Modification_requested) as
   (
    SELECT  1 as total
    , Count(video_modification) Total_Video_Modification_requested
	from onboarded_asins
	where video_modification ILIKE 'Yes'
	)
, Total_Promotion_Modification (total,Total_Promotion_Modification_requested) as
   (
    SELECT  1 as total
    , Count(promotion_modification) Total_Promotion_Modification_requested
	from onboarded_asins
	where promotion_modification ILIKE 'Yes'
	)
, Total_Modification (total,Total_Modification_requested_asins) as
	(
	SELECT 1 AS total
      , Count(brand_feedback) Total_Modification_requested_asins
	from onboarded_asins
	where brand_feedback ILIKE '%Modification%'
	)
, Total_onboarded_asin (total,Total_onboarded_asins) as
	(
	SELECT 1 AS total
      , Count(asin) Total_onboarded_asins
	from onboarded_asins
	)
SELECT 
     CAST(a.total AS varchar ) as total
	, f.Total_onboarded_asins
	, e.Total_Modification_requested_asins
	, a.Total_Image_Modification_requested
	, b.Total_text_Modification_requested
	, c.Total_Video_Modification_requested
	, d.Total_Promotion_Modification_requested
FROM  Total_Image_Modification a
join  Total_text_Modification b
on a.total = b.total
join  Total_Video_Modification c
on b.total = c.total
join  Total_Promotion_Modification d
on c.total = d.total
join  Total_Modification e
on d.total = e.total
join  Total_onboarded_asin f
on e.total = f.total
)
ORDER BY 1;
 
-- under review table. here, first row consists of total data till date.
 
(	
WITH 
    img_under_review (week_number,year,images_under_review) as
      (SELECT
	  DATE_PART('week',(published_date)) as week_number
	  , extract(year from(published_date)) as year
	  , ((select COUNT(image_modification)
        from onboarded_asins
         where image_modification ILIKE 'No'
		  AND TRUNC(DATE_PART('day', CURRENT_DATE::timestamp - (published_date)::timestamp)/7) <=5 
		 )
		 +
		 SUM(CASE 
            WHEN image_modification IS NULL THEN 1
		     ELSE 0 END)) images_under_review
      FROM onboarded_asins
      WHERE (brand_feedback ILIKE '%review%' OR   brand_feedback ILIKE '%modification%')
      AND image_status ilike 'Published'
      AND TRUNC(DATE_PART('day', CURRENT_DATE::timestamp - (published_date)::timestamp)/7) <=5 
      GROUP BY week_number, year
      ORDER BY year,week_number
	  )
   , txt_under_review (week_number,year,text_under_review) as
       (
	  SELECT
	  DATE_PART('week',(published_date)) as week_number
	  , extract(year from(published_date)) as year
	  ,  ((select COUNT(text_modification)
        from onboarded_asins
         where text_modification ILIKE 'No'
		  AND TRUNC(DATE_PART('day', CURRENT_DATE::timestamp - (published_date)::timestamp)/7) <=5 
		 )
		 +
		SUM(CASE WHEN text_modification IS NULL THEN 1 
		     ELSE 0 END)) AS text_under_review
      FROM onboarded_asins
      WHERE (brand_feedback ILIKE '%review%' OR   brand_feedback ILIKE '%modification%')
      AND text_status ilike 'Published'
      AND TRUNC(DATE_PART('day', CURRENT_DATE::timestamp - (published_date)::timestamp)/7) <=5 
      GROUP BY week_number, year
      ORDER BY year,week_number
		 )
	,  Vid_under_review (week_number,year,video_under_review) as
       (SELECT
	  DATE_PART('week',(published_date)) as week_number
	  , extract(year from(published_date)) as year
	  , 
		((select COUNT(video_modification)
        from onboarded_asins
         where video_modification ILIKE 'No'
		  AND TRUNC(DATE_PART('day', CURRENT_DATE::timestamp - (published_date)::timestamp)/7) <=5 
		 )
		 +
		SUM(CASE WHEN video_modification IS NULL THEN 1 
		     ELSE 0 END)) AS video_under_review
      FROM onboarded_asins
      WHERE (brand_feedback ILIKE '%review%' OR   brand_feedback ILIKE '%modification%')
      AND video_upload_status ilike 'Published'
      AND TRUNC(DATE_PART('day', CURRENT_DATE::timestamp - (published_date)::timestamp)/7) <=5 
      GROUP BY week_number, year
      ORDER BY year,week_number
	   )
	,  promo_under_review (week_number,year,promotion_under_review) as
       (SELECT
	  DATE_PART('week',(published_date)) as week_number
	  , extract(year from(published_date)) as year
	  , 
		((select COUNT(promotion_modification)
        from onboarded_asins
         where promotion_modification ILIKE 'No'
		  AND TRUNC(DATE_PART('day', CURRENT_DATE::timestamp - (published_date)::timestamp)/7) <=5 
		 )
		 +
		SUM(CASE WHEN promotion_modification IS NULL THEN 1 
		     ELSE 0 END)) AS promotion_under_review
      FROM onboarded_asins
      WHERE (brand_feedback ILIKE '%review%'  OR   brand_feedback ILIKE '%modification%')
      AND promotion_status ilike 'Published'
      AND TRUNC(DATE_PART('day', CURRENT_DATE::timestamp - (published_date)::timestamp)/7) <=5 
      GROUP BY week_number, year
      ORDER BY year,week_number
	   )
	,  Total_onboarded_asins (onboarded_asins,week_number,year) as 
	  (select  
         COUNT(asin) as onboarded_asins
       , DATE_PART('week',(published_date)) week_number
	   , extract(year from(published_date)) as year
        from onboarded_asins 
        WHERE TRUNC(DATE_PART('day', CURRENT_DATE::timestamp - (published_date)::timestamp)/7) <=5 
        GROUP BY week_number,year
       order by year,week_number)
    , tot_under_review_asins (total_under_review_asins,week_number,year) as
	 (
	  select  
         COUNT(brand_feedback) as total_under_review_asins
       , DATE_PART('week',(published_date)) week_number
	   , extract(year from(published_date)) as year
        from onboarded_asins 
        WHERE brand_feedback ILIKE '%review'
	    AND TRUNC(DATE_PART('day', CURRENT_DATE::timestamp - (published_date)::timestamp)/7) <=5 
        GROUP BY week_number,year
       order by year,week_number
	 )
	  
SELECT 
       ('Week'|| e.week_number ) as week_number
	  , e.onboarded_asins
	  , f.total_under_review_asins
	  , a.images_under_review
	  , b.text_under_review
	  , c.video_under_review
	  , d.promotion_under_review
FROM Total_onboarded_asins e
LEFT JOIN tot_under_review_asins f
ON e.week_number = f.week_number
full outer join img_under_review a
ON e.week_number = a.week_number
full outer join txt_under_review b
ON e.week_number = b.week_number
full outer join Vid_under_review c
ON e.week_number = c.week_number
full outer join promo_under_review d
ON e.week_number = d.week_number
)
UNION
(
WITH
 tot_onboarded_asins (total,Total_onboarded_asins) as
	   (
	   SELECT 1 AS total
        , Count(asin) Total_onboarded_asins
	   from onboarded_asins
	   )
, tot_img_under_review (total,total_images_under_review) as
      (SELECT
	   1 AS total
	  ,((select COUNT(image_modification)
        from onboarded_asins
         where image_modification ILIKE 'No' )
		 +
		 SUM(CASE 
            WHEN image_modification IS NULL THEN 1
		     ELSE 0 END)) AS total_images_under_review
       FROM onboarded_asins
       WHERE (brand_feedback ILIKE '%review%'  OR   brand_feedback ILIKE '%modification%')
      AND image_status ilike 'Published'
       )
 , tot_txt_under_review (total,total_text_under_review) as
      (SELECT
	   1 AS total
	  , ((select COUNT(text_modification)
        from onboarded_asins
         where text_modification ILIKE 'No' )
		 +
		 SUM(CASE 
            WHEN text_modification IS NULL THEN 1
		     ELSE 0 END)) AS text_under_review
       FROM onboarded_asins
       WHERE (brand_feedback ILIKE '%review%'  OR   brand_feedback ILIKE '%modification%')
      AND text_status ilike 'Published'
       )
, tot_vid_under_review (total,total_video_under_review) as
      (SELECT
	   1 AS total
	  , ((select COUNT(video_modification)
        from onboarded_asins
         where video_modification ILIKE 'No' )
		 +
		 SUM(CASE 
            WHEN video_modification IS NULL THEN 1
		     ELSE 0 END)) AS text_under_review
       FROM onboarded_asins
       WHERE (brand_feedback ILIKE '%review%'  OR   brand_feedback ILIKE '%modification%')
      AND text_status ilike 'Published'
       )
, tot_promo_under_review (total,total_promotion_under_review) as
      (
		SELECT
	   1 AS total
	  , ((select COUNT(promotion_modification)
        from onboarded_asins
         where promotion_modification ILIKE 'No' )
		 +
		 SUM(CASE 
            WHEN promotion_modification IS NULL THEN 1
		     ELSE 0 END)) AS text_under_review
       FROM onboarded_asins
       WHERE (brand_feedback ILIKE '%review%'  OR   brand_feedback ILIKE '%modification%')
      AND text_status ilike 'Published'
       )
 , tot_under_review_asins (total,total_under_review_asins) as
	 (
	  SELECT  
		  1 AS total
         , COUNT(brand_feedback) as total_under_review_asins
        from onboarded_asins 
        WHERE brand_feedback ILIKE '%review%'
	 )
	  
SELECT 
    CAST(a.total as VARCHAR) as total
	, a.total_onboarded_asins
	, f.total_under_review_asins
	, b.total_images_under_review
	, c.total_text_under_review
	, d.total_video_under_review
	, e.total_promotion_under_review
from tot_onboarded_asins a
JOIN tot_under_review_asins f
ON a.total=f.total	
JOIN tot_img_under_review b
ON a.total=b.total
JOIN tot_txt_under_review c
ON b.total=c.total
JOIN tot_vid_under_review d
ON c.total=d.total
JOIN tot_promo_under_review e
ON d.total=e.total
)
ORDER BY 1;

-- Region wise ASINs breakdown as per feedback status from respective brands

WITH 
 cn_region (brand_feedback,CN_region_asins) as
   (
	select 
       brand_feedback
     , COUNT(asin) AS CN_region_asins  
    from onboarded_asins
    WHERE brand_region ILIKE 'CN'
    group by brand_feedback)
, us_region (brand_feedback,US_region_asins) as
   (
	select 
       brand_feedback
     , COUNT(asin) as US_region_asins 
    from onboarded_asins
    WHERE brand_region ILIKE 'US'
    group by brand_feedback)

SELECT 
      a.brand_feedback
	, a.CN_region_asins
	, COALESCE(b.US_region_asins,0) US_region_asins
FROM cn_region a
LEFT JOIN us_region b
ON a.brand_feedback=b.brand_feedback
ORDER BY brand_feedback;

	  
-- Region wise BRANDS breakdown as per feedback status from respective brands

WITH 
 cn_region (brand_feedback,CN_region_brands) as
   (
	select 
       brand_feedback
     , COUNT(DISTINCT(brand_name)) AS CN_region_brands  
    from onboarded_asins
    WHERE brand_region ILIKE 'CN'
    group by brand_feedback)
, us_region (brand_feedback,US_region_brands) as
   (
	select 
       brand_feedback
     ,  COUNT(DISTINCT(brand_name)) AS US_region_brands 
    from onboarded_asins
    WHERE brand_region ILIKE 'US'
    group by brand_feedback)

SELECT 
      a.brand_feedback
	, a.CN_region_brands
	, COALESCE(b.US_region_brands,0) US_region_brands
FROM cn_region a
LEFT JOIN us_region b
ON a.brand_feedback=b.brand_feedback
ORDER BY brand_feedback;

	  
	

--part two 

-- top 5 asin swith most scans
select   a.asin
	   , a.scans
	   , ( case
		 when b.marketplace_id = 1 then 'US'
		 when b.marketplace_id = 3 then 'UK'
		 when b.marketplace_id = 7 then 'CA'
		 ELSE 'Not found'END ) AS marketplace
	   ,  COALESCE(c.t_code,'-')  AS T_code
from scan_metrics a
left join onboarded_asins b
on a.asin=b.asin
left join t_codes c
on a.asin=c.asin
ORDER BY a.scans DESC NULLS LAST
limit 5;

-- top 5 asin swith most promotion clicks

select a.asin
	   , a.promotion_clicks
	   , ( case
		 when b.marketplace_id = 1 then 'US'
		 when b.marketplace_id = 3 then 'UK'
		 when b.marketplace_id = 7 then 'CA'
		 ELSE 'Not found'END ) AS marketplace
	   ,  COALESCE(c.t_code,'-')  AS T_code
from scan_metrics a
left join onboarded_asins b
on a.asin=b.asin
left join t_codes c
on a.asin=c.asin
ORDER BY a.promotion_clicks DESC NULLS LAST
limit 5;

-- top 5 asin swith most social media shares
select a.asin
	   , a.social_media_shares
	   , ( case
		 when b.marketplace_id = 1 then 'US'
		 when b.marketplace_id = 3 then 'UK'
		 when b.marketplace_id = 7 then 'CA'
		 ELSE 'Not found'END ) AS marketplace
	   ,  COALESCE(c.t_code,'-')  AS T_code
from scan_metrics a
left join onboarded_asins b
on a.asin=b.asin
left join t_codes c
on a.asin=c.asin
ORDER BY a.social_media_shares DESC NULLS LAST
limit 5;

-- top 5 asin swith most customer_feedback_count
select a.asin
	   , a.customer_feedback_count
	   , ( case
		 when b.marketplace_id = 1 then 'US'
		 when b.marketplace_id = 3 then 'UK'
		 when b.marketplace_id = 7 then 'CA'
		 ELSE 'Not found'END ) AS marketplace
	   , COALESCE(c.t_code,'-')  AS T_code
from scan_metrics a
left join onboarded_asins b
on a.asin=b.asin
left join t_codes c
on a.asin=c.asin
ORDER BY a.customer_feedback_count DESC NULLS LAST
limit 5;


-- top 5 asin swith most avg_time_on_page_in_secs
select a.asin
	   , a.avg_time_on_page_in_secs
	   , ( case
		 when b.marketplace_id = 1 then 'US'
		 when b.marketplace_id = 3 then 'UK'
		 when b.marketplace_id = 7 then 'CA'
		 ELSE 'Not found'END ) AS marketplace
	   , COALESCE(c.t_code,'-') AS T_code
from scan_metrics a
left join onboarded_asins b
on a.asin=b.asin
left join t_codes c
on a.asin=c.asin
ORDER BY a.avg_time_on_page_in_secs DESC NULLS LAST
limit 5;

-- UNITS DELIVERED VS UNITS SCANNED
select units_delivered
       , COALESCE(units_scanned,0) AS units_scanned
	   , COALESCE(scans,0) as number_of_scans
from scan_metrics
where (units_delivered is not null and units_delivered !=0)
ORDER BY units_delivered DESC;

-- avg time spent on t page, vs avg video play percentage
select   avg_time_on_page_in_secs
       , coalesce(avg_video_play_percent,0) avg_video_play_percent
	   , coalesce(avg_video_play_time_in_secs,0) avg_video_play_time_in_secs
from scan_metrics
where (avg_time_on_page_in_secs is not null and avg_time_on_page_in_secs !=0)
ORDER BY avg_time_on_page_in_secs DESC ;
