--[Reactive metrics]
--Brand Enrollment Metrics - Customer Engagement

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

 Query
select * from
(With 
 lastweek AS

    (SELECT   y.sales_team
           , count(distinct(x.brand_id)) as Previous_week_submitted
    FROM table1 x
    left join table2 y
    on x.account_id = y.account_id
    group by y.sales_team
    Order by y.sales_team
    ) 
, one_week_ago_cumulative AS
    (SELECT   y.sales_team
           , count(distinct(x.brand_id)) as a_week_ago_submitted
    FROM table1 x
    left join table2 y
    on x.account_id = y.account_id
    where x.first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '1 week')) OR
    x.first_content_publish_date is null
    group by y.sales_team
    Order by y.sales_team
    )
, two_week_ago_cumulative AS
    (SELECT   y.sales_team
           , count(distinct(x.brand_id)) as two_weeks_ago_submitted
    FROM table1 x
    left join table2 y
    on x.account_id = y.account_id
    where x.first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '2 week')) OR
    x.first_content_publish_date is null
    group by y.sales_team
    Order by y.sales_team
    )
, three_week_ago_cumulative AS
    (SELECT   y.sales_team
           , count(distinct(x.brand_id)) as three_weeks_ago_submitted
    FROM table1 x
    left join table2 y
    on x.account_id = y.account_id
    where x.first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '3 week')) OR
    x.first_content_publish_date is null
    group by y.sales_team
    Order by y.sales_team
    )
, wow_new_brands_enrollment AS
   (SELECT   y.sales_team
        , COALESCE(count(distinct(x.brand_id)),0) as wow_brands_submitted
    FROM table1 x
    left join table2 y
    on x.account_id = y.account_id
    WHERE  (brand_id not in (
                       SELECT 
                               distinct(brand_id ) brands
                       FROM table1
                       where uploaded_date  < (date_trunc('week', GETDATE() - INTERVAL '1 week'))
                          ))
     AND (first_content_publish_date BETWEEN
         GETDATE()::DATE-EXTRACT(DOW FROM GETDATE())::INTEGER-7 AND GETDATE()::DATE-EXTRACT(DOW from GETDATE())::INTEGER)
     -- change 14 to 7 inorder to get lastweek's data
     group by y.sales_team
     Order by y.sales_team
   ) 
   
SELECT  a.sales_team
      , e.three_weeks_ago_submitted
      , b.two_weeks_ago_submitted
      , c.a_week_ago_submitted
      , a.Previous_week_submitted
      , COALESCE(d.wow_brands_submitted,0) wow_brands_submitted
from lastweek a
left join three_week_ago_cumulative e
ON a.sales_team=e.sales_team OR (a.sales_team is null and e.sales_team is null)
left join two_week_ago_cumulative b
ON a.sales_team=b.sales_team OR (a.sales_team is null and b.sales_team is null)
left join one_week_ago_cumulative c
ON a.sales_team=c.sales_team OR (a.sales_team is null and c.sales_team is null)
LEFT JOIN wow_new_brands_enrollment d
on a.sales_team=d.sales_team OR (a.sales_team is null and d.sales_team is null)
ORDER BY a.sales_team)
union all
(WITH 
 tot_lastweek as
      (SELECT 1 as total
           , count(distinct(brand_id )) previous_week_submitted_total
       FROM table1)
, a_week_ago as
      (SELECT 1 as total
            , count(distinct(brand_id )) one_week_ago_submitted_total
       FROM table1
       where first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '1 week')) OR
    first_content_publish_date is null)  
, two_week_ago as
      (SELECT 1 as total
            , count(distinct(brand_id )) two_week_ago_submitted_total
       FROM table1
       where first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '2 week')) OR
    first_content_publish_date is null) 
, three_week_ago as
      (SELECT 1 as total
            , count(distinct(brand_id )) three_weeks_ago_submitted_total
       FROM table1
       where first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '3 week')) OR
    first_content_publish_date is null) 
, wow_new_brands_enrollment AS
      (SELECT 1 as total
           , COALESCE(count(distinct(brand_id)),0) as wow_submitted_total
       FROM table1 
       WHERE  (brand_id not in (
                       SELECT 
                               distinct(brand_id ) brands
                       FROM table1
                       where uploaded_date  < (date_trunc('week', GETDATE() - INTERVAL '1 week'))
                          ))
        AND (first_content_publish_date BETWEEN
          GETDATE()::DATE-EXTRACT(DOW FROM GETDATE())::INTEGER-7 AND GETDATE()::DATE-EXTRACT(DOW from GETDATE())::INTEGER)
         -- change 14 to 7 inorder to get lastweek's data
     )
SELECT  (case when a.total = 1 then 'AAA_Total' end) Total
      , e.three_weeks_ago_submitted_total
      , b.two_week_ago_submitted_total
      , c.one_week_ago_submitted_total
      , a.previous_week_submitted_total
      , COALESCE(d.wow_submitted_total,0) wow_submitted_total
from tot_lastweek a
left join three_week_ago e
ON a.total=e.total 
left join two_week_ago b
ON a.total=b.total 
left join a_week_ago c
ON a.total=c.total 
LEFT JOIN wow_new_brands_enrollment d
on a.total=d.total)
order by 1

/*3A.2-onboarded brands cumulative*/



---Query

select * from
(With 
 lastweek AS

    (SELECT   y.sales_team
           , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN x.brand_id else null end))) as Previous_week_onboarded
    FROM table1 x
    left join table2 y
    on x.account_id = y.account_id
    
    group by y.sales_team
    Order by y.sales_team
    ) 
, one_week_ago_cumulative AS
    (SELECT   y.sales_team
           , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN x.brand_id else null end))) as a_week_ago_onboarded
    FROM table1 x
    left join table2 y
    on x.account_id = y.account_id
    where x.first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '1 week')) OR
    x.first_content_publish_date is null
    group by y.sales_team
    Order by y.sales_team
    )
, two_week_ago_cumulative AS
    (SELECT   y.sales_team
           , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN x.brand_id else null end))) as two_weeks_ago_onboarded
    FROM table1 x
    left join table2 y
    on x.account_id = y.account_id
    where x.first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '2 week')) OR
    x.first_content_publish_date is null
    group by y.sales_team
    Order by y.sales_team
    )
, three_weeks_ago_cumulative AS
    (SELECT   y.sales_team
           , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN x.brand_id else null end))) as three_weeks_ago_onboarded
    FROM table1 x
    left join table2 y
    on x.account_id = y.account_id
    where x.first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '3 week')) OR
    x.first_content_publish_date is null
    group by y.sales_team
    Order by y.sales_team
    )    
, wow_new_brands_enrollment AS
   (SELECT   y.sales_team
        , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN x.brand_id else null end))) as wow_onboarded
    FROM table1 x
    left join table2 y
    on x.account_id = y.account_id
    WHERE  (brand_id not in (
                       SELECT 
                               distinct(brand_id ) brands
                       FROM table1
                       where uploaded_date  < (date_trunc('week', GETDATE() - INTERVAL '1 week'))
                          ))
     AND (first_content_publish_date BETWEEN
         GETDATE()::DATE-EXTRACT(DOW FROM GETDATE())::INTEGER-7 AND GETDATE()::DATE-EXTRACT(DOW from GETDATE())::INTEGER)
     -- change 14 to 7 inorder to get lastweek's data
     group by y.sales_team
     Order by y.sales_team
   ) 
   
SELECT  a.sales_team
      , e.three_weeks_ago_onboarded
      , b.two_weeks_ago_onboarded
      , c.a_week_ago_onboarded
      , a.Previous_week_onboarded
      , COALESCE(d.wow_onboarded,0) wow_onboarded_brands
from lastweek a
left join three_weeks_ago_cumulative e
ON a.sales_team=e.sales_team OR (a.sales_team is null and e.sales_team is null)
left join two_week_ago_cumulative b
ON a.sales_team=b.sales_team OR (a.sales_team is null and b.sales_team is null)
left join one_week_ago_cumulative c
ON a.sales_team=c.sales_team OR (a.sales_team is null and c.sales_team is null)
LEFT JOIN wow_new_brands_enrollment d
on a.sales_team=d.sales_team OR (a.sales_team is null and d.sales_team is null)
ORDER BY a.sales_team)
union all
(WITH 
 tot_lastweek as
      (SELECT 1 as total
           ,count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN brand_id else null end))) previous_week_total_onboarded
       FROM table1)
, a_week_ago as
      (SELECT 1 as total
            , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN brand_id else null end))) a_week_ago_total_onboarded
       FROM table1
       where first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '1 week')) OR
    first_content_publish_date is null)   
, two_week_ago as
      (SELECT 1 as total
            , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN brand_id else null end))) two_weeks_ago_total_onboarded
       FROM table1
       where first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '2 week')) OR
    first_content_publish_date is null)  
, three_weeks_ago as
      (SELECT 1 as total
            , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN brand_id else null end))) three_weeks_ago_total_onboarded
       FROM table1
       where first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '3 week')) OR
    first_content_publish_date is null)
, wow_new_brands_enrollment AS
      (SELECT 1 as total
           , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN brand_id else null end))) as wow_total_onboarded
       FROM table1 
       WHERE  (brand_id not in (
                       SELECT 
                               distinct(brand_id ) brands
                       FROM table1
                       where uploaded_date  < (date_trunc('week', GETDATE() - INTERVAL '1 week'))
                          ))
        AND (first_content_publish_date BETWEEN
          GETDATE()::DATE-EXTRACT(DOW FROM GETDATE())::INTEGER-7 AND GETDATE()::DATE-EXTRACT(DOW from GETDATE())::INTEGER)
         -- change 14 to 7 inorder to get lastweek's data
     )
SELECT  (case when a.total = 1 then 'AAA_Total' end) Total
      , e.three_weeks_ago_total_onboarded
      , b.two_weeks_ago_total_onboarded
      , c.a_week_ago_total_onboarded
      , a.previous_week_total_onboarded
      , COALESCE(d.wow_total_onboarded,0) wow_total_onboarded
from tot_lastweek a
left join three_weeks_ago e
ON a.total=e.total 
left join two_week_ago b
ON a.total=b.total 
left join a_week_ago c
ON a.total=c.total 
LEFT JOIN wow_new_brands_enrollment d
on a.total=d.total)
order by 1

--Table 3B - Total ASINs enrolled by region:
--	3B.1 ASINS submitted cumulative


---Query
select * from
(With 
 lastweek AS

    (SELECT   y.sales_team
           , count(distinct(x.asin)) as Previous_week_CUM_submitted
    FROM table1 x
    left join table2 y
    on x.account_id = y.account_id
    group by y.sales_team
    Order by y.sales_team
    ) 
, one_week_ago_cumulative AS
    (SELECT   y.sales_team
           , count(distinct(x.asin)) as a_week_ago_CUM_submitted
    FROM table1 x
    left join table2 y
    on x.account_id = y.account_id
    where x.first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '1 week')) OR
    x.first_content_publish_date is null
    group by y.sales_team
    Order by y.sales_team
    )
, two_week_ago_cumulative AS
    (SELECT   y.sales_team
           , count(distinct(x.asin)) as two_weeks_ago_CUM_submitted
    FROM table1 x
    left join table2 y
    on x.account_id = y.account_id
    where x.first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '2 week')) OR
    x.first_content_publish_date is null
    group by y.sales_team
    Order by y.sales_team
    )
, three_weeks_ago_cumulative AS
    (SELECT   y.sales_team
           , count(distinct(x.asin)) as three_weeks_ago_CUM_submitted
    FROM table1 x
    left join table2 y
    on x.account_id = y.account_id
    where x.first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '3 week')) OR
    x.first_content_publish_date is null
    group by y.sales_team
    Order by y.sales_team
    )
, wow_new_asins_enrollment AS
   (SELECT   y.sales_team
        , COALESCE(count(distinct(x.asin)),0) as wow_asins_submitted
    FROM table1 x
    left join table2 y
    on x.account_id = y.account_id
    WHERE  (asin not in (
                       SELECT 
                               distinct(asin ) brands
                       FROM table1
                       where uploaded_date  < (date_trunc('week', GETDATE() - INTERVAL '1 week'))
                          ))
     AND (first_content_publish_date BETWEEN
         GETDATE()::DATE-EXTRACT(DOW FROM GETDATE())::INTEGER-7 AND GETDATE()::DATE-EXTRACT(DOW from GETDATE())::INTEGER)
     -- change 14 to 7 inorder to get lastweek's data
     group by y.sales_team
     Order by y.sales_team
   ) 
   
SELECT  a.sales_team
      , e.three_weeks_ago_CUM_submitted
      , b.two_weeks_ago_CUM_submitted
      , c.a_week_ago_CUM_submitted
      , a.Previous_week_CUM_submitted
      , COALESCE(d.wow_asins_submitted,0) wow_asins_submitted
from lastweek a
left join three_weeks_ago_cumulative e
ON a.sales_team=e.sales_team OR (a.sales_team is null and e.sales_team is null)
left join two_week_ago_cumulative b
ON a.sales_team=b.sales_team OR (a.sales_team is null and b.sales_team is null)
left join one_week_ago_cumulative c
ON a.sales_team=c.sales_team OR (a.sales_team is null and c.sales_team is null)
LEFT JOIN wow_new_asins_enrollment d
on a.sales_team=d.sales_team OR (a.sales_team is null and d.sales_team is null)
ORDER BY a.sales_team)
union all
(WITH 
 tot_lastweek as
      (SELECT 1 as total
           , count(distinct(asin )) previous_week_total_submitted_asins
       FROM table1)
, a_week_ago as
      (SELECT 1 as total
            , count(distinct(asin )) a_week_total_submitted_asins
       FROM table1
       where first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '1 week')) OR
    first_content_publish_date is null)  
, two_week_ago as
      (SELECT 1 as total
            , count(distinct(asin )) two_weeks_total_submitted_asins
       FROM table1
       where first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '2 week')) OR
    first_content_publish_date is null) 
, three_week_ago as
      (SELECT 1 as total
            , count(distinct(asin )) three_weeks_total_submitted_asins
       FROM table1
       where first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '3 week')) OR
    first_content_publish_date is null) 
, wow_new_asins_enrollment AS
      (SELECT 1 as total
           , COALESCE(count(distinct(asin)),0) as wow_total_asins_submitted
       FROM table1 
       WHERE  (asin not in (
                       SELECT 
                               distinct(asin ) brands
                       FROM table1
                       where uploaded_date  < (date_trunc('week', GETDATE() - INTERVAL '1 week'))
                          ))
        AND (first_content_publish_date BETWEEN
          GETDATE()::DATE-EXTRACT(DOW FROM GETDATE())::INTEGER-7 AND GETDATE()::DATE-EXTRACT(DOW from GETDATE())::INTEGER)
         -- change 14 to 7 inorder to get lastweek's data
     )
SELECT  (case when a.total = 1 then 'AAA_Total' end) Total
      , e.three_weeks_total_submitted_asins
      , b.two_weeks_total_submitted_asins
      , c.a_week_total_submitted_asins
      , a.previous_week_total_submitted_asins
      , COALESCE(d.wow_total_asins_submitted,0) wow_total_asins_submitted
from tot_lastweek a
left join three_week_ago e
ON a.total=e.total 
left join two_week_ago b
ON a.total=b.total 
left join a_week_ago c
ON a.total=c.total 
LEFT JOIN wow_new_asins_enrollment d
on a.total=d.total)
order by 1


--	3B.2 ASINS onboarded cumulative



--- query
select * from
(With 
 lastweek AS

    (SELECT   y.sales_team
           , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN x.asin else null end))) as Previous_week_CUM_onboarded_asins
    FROM table1 x
    left join table2 y
    on x.account_id = y.account_id
    
    group by y.sales_team
    Order by y.sales_team
    ) 
, one_week_ago_cumulative AS
    (SELECT   y.sales_team
           , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN x.asin else null end))) as a_week_ago_CUM_onboarded_asins
    FROM table1 x
    left join table2 y
    on x.account_id = y.account_id
    where x.first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '1 week')) OR
    x.first_content_publish_date is null
    group by y.sales_team
    Order by y.sales_team
    )
, two_week_ago_cumulative AS
    (SELECT   y.sales_team
           , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN x.asin else null end))) as two_weeks_ago_CUM_onboarded_asins
    FROM table1 x
    left join table2 y
    on x.account_id = y.account_id
    where x.first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '2 week')) OR
    x.first_content_publish_date is null
    group by y.sales_team
    Order by y.sales_team
    )
, three_week_ago_cumulative AS
    (SELECT   y.sales_team
           , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN x.asin else null end))) as three_weeks_ago_CUM_onboarded_asins
    FROM table1 x
    left join table2 y
    on x.account_id = y.account_id
    where x.first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '3 week')) OR
    x.first_content_publish_date is null
    group by y.sales_team
    Order by y.sales_team
    )
, wow_new_asins_enrollment AS
   (SELECT   y.sales_team
        , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN x.asin else null end))) as wow_asins_Onboarded
    FROM table1 x
    left join table2 y
    on x.account_id = y.account_id
    WHERE  (asin not in (
                       SELECT 
                               distinct(asin ) brands
                       FROM table1
                       where uploaded_date  < (date_trunc('week', GETDATE() - INTERVAL '1 week'))
                          ))
     AND (first_content_publish_date BETWEEN
         GETDATE()::DATE-EXTRACT(DOW FROM GETDATE())::INTEGER-7 AND GETDATE()::DATE-EXTRACT(DOW from GETDATE())::INTEGER)
     -- change 14 to 7 inorder to get lastweek's data
     group by y.sales_team
     Order by y.sales_team
   ) 
   
SELECT  a.sales_team
      , e.three_weeks_ago_CUM_onboarded_asins
      , b.two_weeks_ago_CUM_onboarded_asins
      , c.a_week_ago_CUM_onboarded_asins
      , a.Previous_week_CUM_onboarded_asins
      , COALESCE(d.wow_asins_Onboarded,0) wow_asins_Onboarded
from lastweek a
left join three_week_ago_cumulative e
ON a.sales_team=e.sales_team OR (a.sales_team is null and e.sales_team is null)
left join two_week_ago_cumulative b
ON a.sales_team=b.sales_team OR (a.sales_team is null and b.sales_team is null)
left join one_week_ago_cumulative c
ON a.sales_team=c.sales_team OR (a.sales_team is null and c.sales_team is null)
LEFT JOIN wow_new_asins_enrollment d
on a.sales_team=d.sales_team OR (a.sales_team is null and d.sales_team is null)
ORDER BY a.sales_team)
union all
(WITH 
 tot_lastweek as
      (SELECT 1 as total
           ,count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN asin else null end))) Previous_week_CUM_total_onboarded_asins
       FROM table1)
, a_week_ago as
      (SELECT 1 as total
            , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN asin else null end))) a_week_ago_CUM_total_onboarded_asins
       FROM table1
       where first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '1 week')) OR
    first_content_publish_date is null) 
, two_week_ago as
      (SELECT 1 as total
            , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN asin else null end))) two_weeks_ago_CUM_total_onboarded_asins
       FROM table1
       where first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '2 week')) OR
    first_content_publish_date is null) 
, three_weeks_ago as
      (SELECT 1 as total
            , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN asin else null end))) three_weeks_ago_CUM_total_onboarded_asins
       FROM table1
       where first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '3 week')) OR
    first_content_publish_date is null) 
, wow_new_asins_enrollment AS
      (SELECT 1 as total
           , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN asin else null end))) as wow_asins_onboarded_total
       FROM table1 
       WHERE  (asin not in (
                       SELECT 
                               distinct(asin ) asins
                       FROM table1
                       where uploaded_date  < (date_trunc('week', GETDATE() - INTERVAL '1 week'))
                          ))
        AND (first_content_publish_date BETWEEN
          GETDATE()::DATE-EXTRACT(DOW FROM GETDATE())::INTEGER-7 AND GETDATE()::DATE-EXTRACT(DOW from GETDATE())::INTEGER)
         -- change 14 to 7 inorder to get lastweek's data
     )
SELECT  (case when a.total = 1 then 'AAA_Total' end) Total
      , e.three_weeks_ago_CUM_total_onboarded_asins
      , b.two_weeks_ago_CUM_total_onboarded_asins
      , c.a_week_ago_CUM_total_onboarded_asins
      , a.Previous_week_CUM_total_onboarded_asins
      , COALESCE(d.wow_asins_onboarded_total,0) wow_asins_onboarded_total
from tot_lastweek a
left join three_weeks_ago e
ON a.total=e.total 
left join two_week_ago b
ON a.total=b.total 
left join a_week_ago c
ON a.total=c.total 
LEFT JOIN wow_new_asins_enrollment d
on a.total=d.total)
order by 1

--Table 2 - CE adoption by feature:
--2.1 (proactive details yet to code, since there is an issue with EDX)
--2.2 Reactive CE adoption by feature
-- 2.2.1 CE adoption by feature Cumulative - Brands


---query
SELECT * FROM
(With 
lastweek_Ce_feature_adoptation as
   (select   1 as brand_slash_asin
       , count(distinct(case when image_status ilike 'Published' then brand_id else null end)) as image
       , count(distinct(case when text_status ilike 'Published' then brand_id else null end)) as text
       , count(distinct(case when video_upload_status ilike 'Published' then brand_id else null end)) as Video
       , count(distinct(case when promotions ilike 'Published' then brand_id else null end)) as promotions
       , count(distinct(case when (image_status ilike 'published' 
                                  or text_status ilike 'published' 
                                  or video_upload_status ilike 'published' 
                                  or promotions ilike 'published')
                             then brand_id else null 
                        end)) as Any_feature
     from table1)
, a_week_ago_Ce_feature_adoptation as
   (select   1 as brand_slash_asin
       , count(distinct(case when image_status ilike 'Published' then brand_id else null end)) as image
       , count(distinct(case when text_status ilike 'Published' then brand_id else null end)) as text
       , count(distinct(case when video_upload_status ilike 'Published' then brand_id else null end)) as Video
       , count(distinct(case when promotions ilike 'Published' then brand_id else null end)) as promotions
       , count(distinct(case when (image_status ilike 'published' 
                                  or text_status ilike 'published' 
                                  or video_upload_status ilike 'published' 
                                  or promotions ilike 'published')
                             then brand_id else null 
                        end)) as Any_feature
     from table1
     where first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '1 week')) OR
    first_content_publish_date is null)
, Two_week_ago_Ce_feature_adoptation as
   (select   1 as brand_slash_asin
       , count(distinct(case when image_status ilike 'Published' then brand_id else null end)) as image
       , count(distinct(case when text_status ilike 'Published' then brand_id else null end)) as text
       , count(distinct(case when video_upload_status ilike 'Published' then brand_id else null end)) as Video
       , count(distinct(case when promotions ilike 'Published' then brand_id else null end)) as promotions
       , count(distinct(case when (image_status ilike 'published' 
                                  or text_status ilike 'published' 
                                  or video_upload_status ilike 'published' 
                                  or promotions ilike 'published')
                             then brand_id else null 
                        end)) as Any_feature
     from table1
     where first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '2 week')) OR
    first_content_publish_date is null)
, Three_weeks_ago_Ce_feature_adoptation as
   (select   1 as brand_slash_asin
       , count(distinct(case when image_status ilike 'Published' then brand_id else null end)) as image
       , count(distinct(case when text_status ilike 'Published' then brand_id else null end)) as text
       , count(distinct(case when video_upload_status ilike 'Published' then brand_id else null end)) as Video
       , count(distinct(case when promotions ilike 'Published' then brand_id else null end)) as promotions
       , count(distinct(case when (image_status ilike 'published' 
                                  or text_status ilike 'published' 
                                  or video_upload_status ilike 'published' 
                                  or promotions ilike 'published')
                             then brand_id else null 
                        end)) as Any_feature
     from table1
     where first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '3 week')) OR
    first_content_publish_date is null)
, wow_ce_adoptation as
     (select   1 as brand_slash_asin
       ,  count(distinct(case when image_status ilike 'Published' then brand_id else null end)) as image
       ,  count(distinct(case when text_status ilike 'Published' then brand_id else null end)) as text
       ,  count(distinct(case when video_upload_status ilike 'Published' then brand_id else null end)) as Video
       ,  count(distinct(case when promotions ilike 'Published' then brand_id else null end)) as promotions
       ,  count(distinct(case when (image_status ilike 'published' 
                                  or text_status ilike 'published' 
                                  or video_upload_status ilike 'published' 
                                  or promotions ilike 'published')
                             then brand_id else null 
                        end)) as Any_feature
      from table1
      WHERE  (brand_id not in (
                       SELECT 
                               distinct(brand_id ) brands
                       FROM table1
                       where uploaded_date  < (date_trunc('week', GETDATE() - INTERVAL '1 week'))
                          ))
      AND  (datediff(week,first_content_publish_date,CURRENT_DATE)  <=1))

((select (case when brand_slash_asin = 1 then '3_present_week' end) as Brands_adoptation
      , image , text, video , promotions, Any_feature
from lastweek_Ce_feature_adoptation)
union all
(select (case when brand_slash_asin = 1 then '2_one_week_ago' end) as Brands_adoptation
      , image , text, video , promotions, Any_feature
from a_week_ago_Ce_feature_adoptation)
union all
(select (case when brand_slash_asin = 1 then '1_two_week_ago' end) as Brands_adoptation
      , image , text, video , promotions, Any_feature
from Two_week_ago_Ce_feature_adoptation)
union all
(select (case when brand_slash_asin = 1 then '0_three_weeks_ago' end) as Brands_adoptation
      , image , text, video , promotions, Any_feature
from Three_weeks_ago_Ce_feature_adoptation)
union all
(select (case when brand_slash_asin = 1 then 'wow_ce_adoptation' end) as Brands_adoptation
      , image , text, video , promotions, Any_feature
from wow_ce_adoptation)))
ORDER BY 1 DESC
2.2 Reactive CE adoption by feature
- 2.2.2 CE adoption by feature Cumulative - ASINs
----query
SELECT * FROM
(With 
lastweek_Ce_feature_adoptation as
   (select   1 as brand_slash_asin
       , count(distinct(case when image_status ilike 'Published' then asin else null end)) as image
       , count(distinct(case when text_status ilike 'Published' then asin else null end)) as text
       , count(distinct(case when video_upload_status ilike 'Published' then asin else null end)) as Video
       , count(distinct(case when promotions ilike 'Published' then asin else null end)) as promotions
       , count(distinct(case when (image_status ilike 'published' 
                                  or text_status ilike 'published' 
                                  or video_upload_status ilike 'published' 
                                  or promotions ilike 'published')
                             then asin else null 
                        end)) as Any_feature
     from table1)
, a_week_ago_Ce_feature_adoptation as
   (select   1 as brand_slash_asin
       , count(distinct(case when image_status ilike 'Published' then asin else null end)) as image
       , count(distinct(case when text_status ilike 'Published' then asin else null end)) as text
       , count(distinct(case when video_upload_status ilike 'Published' then asin else null end)) as Video
       , count(distinct(case when promotions ilike 'Published' then asin else null end)) as promotions
       , count(distinct(case when (image_status ilike 'published' 
                                  or text_status ilike 'published' 
                                  or video_upload_status ilike 'published' 
                                  or promotions ilike 'published')
                             then asin else null 
                        end)) as Any_feature
     from table1
     where first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '1 week')) OR
    first_content_publish_date is null)
, Two_week_ago_Ce_feature_adoptation as
   (select   1 as brand_slash_asin
       , count(distinct(case when image_status ilike 'Published' then asin else null end)) as image
       , count(distinct(case when text_status ilike 'Published' then asin else null end)) as text
       , count(distinct(case when video_upload_status ilike 'Published' then asin else null end)) as Video
       , count(distinct(case when promotions ilike 'Published' then asin else null end)) as promotions
       , count(distinct(case when (image_status ilike 'published' 
                                  or text_status ilike 'published' 
                                  or video_upload_status ilike 'published' 
                                  or promotions ilike 'published')
                             then asin else null 
                        end)) as Any_feature
     from table1
     where first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '2 week')) OR
    first_content_publish_date is null)
, Three_weeks_ago_Ce_feature_adoptation as
   (select   1 as brand_slash_asin
       , count(distinct(case when image_status ilike 'Published' then asin else null end)) as image
       , count(distinct(case when text_status ilike 'Published' then asin else null end)) as text
       , count(distinct(case when video_upload_status ilike 'Published' then asin else null end)) as Video
       , count(distinct(case when promotions ilike 'Published' then asin else null end)) as promotions
       , count(distinct(case when (image_status ilike 'published' 
                                  or text_status ilike 'published' 
                                  or video_upload_status ilike 'published' 
                                  or promotions ilike 'published')
                             then asin else null 
                        end)) as Any_feature
     from table1
     where first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '3 week')) OR
    first_content_publish_date is null)
, wow_ce_adoptation as
     (select   1 as brand_slash_asin
       ,  count(distinct(case when image_status ilike 'Published' then asin else null end)) as image
       ,  count(distinct(case when text_status ilike 'Published' then asin else null end)) as text
       ,  count(distinct(case when video_upload_status ilike 'Published' then asin else null end)) as Video
       ,  count(distinct(case when promotions ilike 'Published' then asin else null end)) as promotions
       ,  count(distinct(case when (image_status ilike 'published' 
                                  or text_status ilike 'published' 
                                  or video_upload_status ilike 'published' 
                                  or promotions ilike 'published')
                             then asin else null 
                        end)) as Any_feature
      from table1
      WHERE  (asin not in (
                       SELECT 
                               distinct(asin ) brands
                       FROM table1
                       where uploaded_date  < (date_trunc('week', GETDATE() - INTERVAL '1 week'))
                          ))
      AND  (datediff(week,first_content_publish_date,CURRENT_DATE)  <=1))

((select (case when brand_slash_asin = 1 then '3_present_week' end) as asins_adoptation
      , image , text, video , promotions, Any_feature
from lastweek_Ce_feature_adoptation)
union all
(select (case when brand_slash_asin = 1 then '2_one_week_ago' end) as asins_adoptation
      , image , text, video , promotions, Any_feature
from a_week_ago_Ce_feature_adoptation)
union all
(select (case when brand_slash_asin = 1 then '1_two_weeks_ago' end) as asins_adoptation
      , image , text, video , promotions, Any_feature
from Two_week_ago_Ce_feature_adoptation)
union all
(select (case when brand_slash_asin = 1 then '0_three_weeks_ago' end) as asins_adoptation
      , image , text, video , promotions, Any_feature
from Three_weeks_ago_Ce_feature_adoptation)
union all
(select (case when brand_slash_asin = 1 then 'wow_ce_adoptation' end) as asins_adoptation
      , image , text, video , promotions, Any_feature
from wow_ce_adoptation)))
ORDER BY 1 DESC

--Table 1 - Cumulative Brands (Reactive) enrolled in CE 
--(Unique brands enrolled in CE)

---Query
SELECT * FROM 
((With 
 lastweek AS

    (SELECT   1 as total
           , count(distinct(x.brand_id)) as Previous_week_submitted
    FROM table1 x
    ) 
, one_week_ago_cumulative AS
    (SELECT   1 as total
           , count(distinct(x.brand_id)) as a_week_ago_submitted
    FROM table1 x
    where x.first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '1 week')) OR
    x.first_content_publish_date is null)
, two_week_ago_cumulative AS
    (SELECT  1 as total
           , count(distinct(x.brand_id)) as two_weeks_ago_submitted
    FROM table1 x
    where x.first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '2 week')) OR
    x.first_content_publish_date is null)
, three_week_ago_cumulative AS
    (SELECT  1 as total
           , count(distinct(x.brand_id)) as three_weeks_ago_submitted
    FROM table1 x
    where x.first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '3 week')) OR
    x.first_content_publish_date is null)
, wow_brands_submission  AS
   (SELECT   1 as total
        , COALESCE(count(distinct(x.brand_id)),0) as wow_brands_submitted
    FROM table1 x
    WHERE  (brand_id not in (
                       SELECT 
                               distinct(brand_id ) brands
                       FROM table1
                       where uploaded_date  < (date_trunc('week', GETDATE() - INTERVAL '1 week'))
                          ))
     AND (first_content_publish_date BETWEEN
         GETDATE()::DATE-EXTRACT(DOW FROM GETDATE())::INTEGER-7 AND GETDATE()::DATE-EXTRACT(DOW from GETDATE())::INTEGER)
     -- change 14 to 7 inorder to get lastweek's data
    
   ) 
   
SELECT  (case when a.total = 1 then 'Content_submitted' end) as Type
      , e.three_weeks_ago_submitted
      , b.two_weeks_ago_submitted
      , c.a_week_ago_submitted
      , a.Previous_week_submitted
      , COALESCE(d.wow_brands_submitted,0) wow_brands_submitted
from lastweek a
left join two_week_ago_cumulative b
ON a.total=b.total 
left join one_week_ago_cumulative c
ON a.total=c.total 
LEFT JOIN wow_brands_submission d
on a.total=d.total 
LEFT JOIN three_week_ago_cumulative e
on a.total=e.total 

ORDER BY 1)
union all
(

With 
 lastweek AS

    (SELECT   1 as total
           , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN x.brand_id else null end))) as Previous_week_published
    FROM table1 x
    ) 
, one_week_ago_cumulative AS
    (SELECT   1 as total
           , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN x.brand_id else null end))) as a_week_ago_published
    FROM table1 x
    where x.first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '1 week')) OR
    x.first_content_publish_date is null)
, two_week_ago_cumulative AS
    (SELECT  1 as total
           , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN x.brand_id else null end))) as two_weeks_ago_published
    FROM table1 x
    where x.first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '2 week')) OR
    x.first_content_publish_date is null)
, three_week_ago_cumulative AS
    (SELECT  1 as total
           , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN x.brand_id else null end))) as three_weeks_ago_published
    FROM table1 x
    where x.first_content_publish_date   < (date_trunc('week', GETDATE() - INTERVAL '3 week')) OR
    x.first_content_publish_date is null)
, wow_brands_published  AS
   (SELECT   1 as total
        , count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN x.brand_id else null end))) as wow_brands_published
    FROM table1 x
    WHERE  (brand_id not in (
                       SELECT 
                               distinct(brand_id ) brands
                       FROM table1
                       where uploaded_date  < (date_trunc('week', GETDATE() - INTERVAL '1 week'))
                          ))
     AND (first_content_publish_date BETWEEN
         GETDATE()::DATE-EXTRACT(DOW FROM GETDATE())::INTEGER-7 AND GETDATE()::DATE-EXTRACT(DOW from GETDATE())::INTEGER)
     -- change 14 to 7 inorder to get lastweek's data
    
   ) 
   
SELECT  (case when a.total = 1 then 'Content_published' end) as Type
      , e.three_weeks_ago_published
      , b.two_weeks_ago_published
      , c.a_week_ago_published
      , a.Previous_week_published
      , COALESCE(d.wow_brands_published,0) wow_brands_published
from lastweek a
left join two_week_ago_cumulative b
ON a.total=b.total 
left join one_week_ago_cumulative c
ON a.total=c.total 
LEFT JOIN wow_brands_published d
on a.total=d.total 
LEFT JOIN three_week_ago_cumulative e
on a.total=e.total 
ORDER BY 1)
UNION ALL
(SELECT (case when tot = 1 then 'Content_ainprogress' end) as Type
      , three_weeks_ago_inprogress
      , two_weeks_ago_inprogress
      , a_week_ago_inprogress
      , Present_week_inprogress
      , wow_inprogress
FROM
(with cte as 
(select  
      (SELECT 
       count(distinct(brand_id ))brands
       FROM table1) - 

      (SELECT 
       count(distinct(case when (image_status ilike 'published' or
                                text_status ilike 'published' or
                                video_upload_status ilike 'published' or
                                promotions ilike 'published')
             THEN brand_id else null
        end ))brands
        FROM table1) as Present_week_inprogress
,  (SELECT 
       count(distinct(brand_id ))brands
       FROM table1
       WHERE uploaded_date  < (date_trunc('week', GETDATE() - INTERVAL '1 week')) ) - 

      (SELECT 
       count(distinct(case when (image_status ilike 'published' or
                                text_status ilike 'published' or
                                video_upload_status ilike 'published' or
                                promotions ilike 'published')
             THEN brand_id else null
        end ))brands
        FROM table1
        WHERE uploaded_date  < (date_trunc('week', GETDATE() - INTERVAL '1 week')) ) as a_week_ago_inprogress
,  (SELECT 
       count(distinct(brand_id ))brands
       FROM table1
       WHERE uploaded_date  < (date_trunc('week', GETDATE() - INTERVAL '2 week')) ) - 

      (SELECT 
       count(distinct(case when (image_status ilike 'published' or
                                text_status ilike 'published' or
                                video_upload_status ilike 'published' or
                                promotions ilike 'published')
             THEN brand_id else null
        end ))brands
        FROM table1
        WHERE uploaded_date  < (date_trunc('week', GETDATE() - INTERVAL '2 week')) ) as two_weeks_ago_inprogress
,  (SELECT 
       count(distinct(brand_id ))brands
       FROM table1
       WHERE uploaded_date  < (date_trunc('week', GETDATE() - INTERVAL '3 week')) ) - 

      (SELECT 
       count(distinct(case when (image_status ilike 'published' or
                                text_status ilike 'published' or
                                video_upload_status ilike 'published' or
                                promotions ilike 'published')
             THEN brand_id else null
        end ))brands
        FROM table1
        WHERE uploaded_date  < (date_trunc('week', GETDATE() - INTERVAL '3 week')) ) as three_weeks_ago_inprogress
, ((SELECT   
         COALESCE(count(distinct(x.brand_id)),0) as wow_brands_submitted
    FROM table1 x
    WHERE  (brand_id not in (
                       SELECT 
                               distinct(brand_id ) brands
                       FROM table1
                       where uploaded_date  < (date_trunc('week', GETDATE() - INTERVAL '1 week'))
                          ))
     AND (first_content_publish_date BETWEEN
         GETDATE()::DATE-EXTRACT(DOW FROM GETDATE())::INTEGER-7 AND GETDATE()::DATE-EXTRACT(DOW from GETDATE())::INTEGER)
     -- change 14 to 7 inorder to get lastweek's data
  ) - (SELECT   
         count(distinct( (case when (image_status ilike 'published' or
                                        text_status ilike 'published' or
                                        video_upload_status ilike 'published' or
                                        promotions ilike 'published')
                              THEN x.brand_id else null end))) as wow_brands_published
    FROM table1 x
    WHERE  (brand_id not in (
                       SELECT 
                               distinct(brand_id ) brands
                       FROM table1
                       where uploaded_date  < (date_trunc('week', GETDATE() - INTERVAL '1 week'))
                          ))
     AND (first_content_publish_date BETWEEN
         GETDATE()::DATE-EXTRACT(DOW FROM GETDATE())::INTEGER-7 AND GETDATE()::DATE-EXTRACT(DOW from GETDATE())::INTEGER)
     )) as wow_inprogress)

select 1 as tot
      , three_weeks_ago_inprogress
      , two_weeks_ago_inprogress
      , a_week_ago_inprogress
      , Present_week_inprogress
      , wow_inprogress
from cte)))
ORDER BY 1 desc


---------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 
 
 [[[[[Proactive metrics]]]]]
 
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
