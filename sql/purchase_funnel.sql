WITH base_events AS (   SELECT       event_name,       event_time,       campaign_id,       properties,       properties ->> 'visitor_id' AS visitor_id,   -- 🔥 changed       properties ->> 'purchaser_influencer_id' AS influencer_id 
  FROM raw_posthog_events_v3 
WHERE  campaign_id IN  (/* campaign_ids */) 
 
), 
-- ========================= 
-- STEP 1: TOTAL VIEWS (EVENT LEVEL) -- ========================= step1 AS ( 
  SELECT COUNT(*) AS total_views 
  FROM base_events 
  WHERE event_name = 'Campaign View' 
), 
-- helper for ordering step1_events AS ( 
  SELECT visitor_id, MIN(event_time) AS t1 
  FROM base_events 
  WHERE event_name = 'Campaign View' 
    AND visitor_id IS NOT NULL 
  GROUP BY visitor_id 
), 
-- ========================= -- STEP 2 
-- ========================= step2 AS ( 
  SELECT b.visitor_id, MIN(b.event_time) AS t2 
  FROM base_events b 
  JOIN step1_events s1 
      ON b.visitor_id = s1.visitor_id 
     AND b.event_time > s1.t1 
  WHERE b.event_name = 'public_campaign_rewards_button_click' 
  GROUP BY b.visitor_id 
), 
-- ========================= -- STEP 3 
-- ========================= step3 AS ( 
  SELECT b.visitor_id, MIN(b.event_time) AS t3 
  FROM base_events b 
  JOIN step2 s2 
      ON b.visitor_id = s2.visitor_id 
     AND b.event_time > s2.t2 
  WHERE b.event_name = 'public_campaign_purchase_flow_start' 
  GROUP BY b.visitor_id 
), 
-- ========================= -- STEP 4 
-- ========================= step4 AS ( 
  SELECT b.visitor_id, MIN(b.event_time) AS t4 
  FROM base_events b 
  JOIN step3 s3 
      ON b.visitor_id = s3.visitor_id 
     AND b.event_time > s3.t3 
  WHERE b.event_name = 'public_campaign_proof_upload_submit' 
  GROUP BY b.visitor_id 
), 
-- ========================= -- STEP 5 (backend) 
-- ========================= step5 AS ( 
  SELECT DISTINCT influencer_id 
  FROM base_events 
  WHERE event_name = 'reward_purchase_approved' 
    AND influencer_id IS NOT NULL 
) 
-- ========================= -- FINAL OUTPUT 
-- ========================= 
SELECT 
  (SELECT total_views FROM step1) AS campaign_viewed, 
  (SELECT COUNT(*) FROM step2) AS reward_clicked, 
  (SELECT COUNT(*) FROM step3) AS purchase_cta, 
  (SELECT COUNT(*) FROM step4) AS proof_submitted, 
  (SELECT COUNT(*) FROM step5) AS proof_approved; 
 
 
