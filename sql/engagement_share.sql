WITH base_events AS ( 
  SELECT 
      event_name,       event_time,       campaign_id, 
      COALESCE(visitor_id, person_id, distinct_id) AS user_id 
  FROM raw_posthog_events_v3 
WHERE campaign_id IN  (/* campaign_ids */) 
 
), 
-- STEP 1: total campaign views (EVENT count) step1 AS ( 
  SELECT COUNT(*) AS step1_events 
  FROM base_events 
  WHERE event_name = 'Campaign View' 
), 
-- STEP 2: total share clicks AFTER a campaign view step2 AS ( 
  SELECT COUNT(*) AS step2_events 
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
-- STEP 3: total social media clicks AFTER share click step3 AS ( 
  SELECT COUNT(*) AS step3_events 
  FROM base_events b 
  WHERE b.event_name IN ( 
      'campaign_share_platform_click', 
      'campaign_manager_campaign_share_platform_click' 
  ) 
  AND EXISTS ( 
      SELECT 1 
      FROM base_events s 
      WHERE s.user_id = b.user_id 
        AND s.event_name IN ( 
            'public_campaign_share_button_click', 
            'public_campaign_share_button_click_anon' 
        ) 
        AND s.event_time < b.event_time 
  ) 
) 
SELECT 
  s1.step1_events AS campaign_viewed, 
  s2.step2_events AS share_clicked,   s3.step3_events AS social_media_click_events 
FROM step1 s1, step2 s2, step3 s3; 
 
 
