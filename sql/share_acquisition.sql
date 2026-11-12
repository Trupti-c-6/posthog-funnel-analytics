WITH base_events AS (  SELECT 
     event_name,      event_time,      campaign_id, 
     COALESCE(visitor_id, person_id, distinct_id) AS user_id 
 FROM raw_posthog_events_v3 
WHERE  campaign_id IN  (/* campaign_ids */) 
 
), 
-- STEP 1: Campaign View (event count) step1 AS ( 
 SELECT COUNT(*) AS step1_events 
 FROM base_events 
 WHERE event_name = 'Campaign View' 
), 
-- STEP 2: Share Clicks (after view) step2_events AS ( 
 SELECT b.user_id, b.event_time 
 FROM base_events b 
 WHERE b.event_name IN ( 
     'public_campaign_share_button_click', 
     'public_campaign_share_button_click_anon' 
 ) 
 AND EXISTS ( 
     SELECT 1 
     FROM base_events v 
     WHERE v.user_id = b.user_id 
       AND v.event_name = 'Campaign View' 
       AND v.event_time < b.event_time 
 ) 
), 
step2 AS ( 
 SELECT COUNT(*) AS step2_events 
 FROM step2_events 
), 
-- STEP 3: STRICT 1:1 mapping (each share → max 1 join) step3 AS ( 
 SELECT COUNT(*) AS step3_events 
 FROM ( 
     SELECT 
         s.user_id, 
         s.event_time AS share_time, 
         MIN(j.event_time) AS join_time   -- 🔥 first join after that share 
     FROM step2_events s 
     LEFT JOIN base_events j 
       ON j.user_id = s.user_id 
      AND j.event_name = 'JOIN_CAMPAIGN' 
      AND j.event_time > s.event_time 
     GROUP BY s.user_id, s.event_time 
     HAVING MIN(j.event_time) IS NOT NULL  -- only count successful conversions 
 ) t 
) 
SELECT 
 s1.step1_events AS campaign_viewed,  s2.step2_events AS share_clicked,  s3.step3_events AS signed_up 
FROM step1 s1, step2 s2, step3 s3; 
