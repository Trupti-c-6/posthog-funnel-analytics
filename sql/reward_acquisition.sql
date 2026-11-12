WITH base_events AS (    SELECT        event_name,        event_time, 
       properties ->> 'visitor_id' AS visitor_id 
   FROM raw_posthog_events_v3 
WHERE campaign_id IN  (/* campaign_ids */) 
 
     AND properties ->> 'visitor_id' IS NOT NULL 
), 
-- STEP 1: total campaign views (EVENT count) step1 AS ( 
   SELECT COUNT(*) AS step1_events 
   FROM base_events 
   WHERE event_name = 'Campaign View' 
), 
-- STEP 2: total reward clicks AFTER a view step2 AS ( 
   SELECT COUNT(*) AS step2_events 
   FROM base_events b 
   WHERE b.event_name = 'public_campaign_rewards_button_click' 
     AND EXISTS ( 
         SELECT 1 
         FROM base_events v 
         WHERE v.visitor_id = b.visitor_id 
           AND v.event_name = 'Campaign View' 
           AND v.event_time < b.event_time 
     ) 
), 
-- STEP 3: total JOIN_CAMPAIGN AFTER reward click step3 AS ( 
   SELECT COUNT(*) AS step3_events 
   FROM base_events b 
   WHERE b.event_name = 'JOIN_CAMPAIGN' 
     AND EXISTS ( 
         SELECT 1 
         FROM base_events r 
         WHERE r.visitor_id = b.visitor_id 
           AND r.event_name = 'public_campaign_rewards_button_click' 
           AND r.event_time < b.event_time 
     ) 
) 
SELECT 
   s1.step1_events AS campaign_viewed,    s2.step2_events AS reward_button,    s3.step3_events AS joined_campaign 
FROM step1 s1, step2 s2, step3 s3; 
 
