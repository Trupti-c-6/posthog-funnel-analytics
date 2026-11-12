WITH base_events AS ( SELECT 
    visitor_id, 
    event_name,     event_time,     campaign_id 
FROM raw_posthog_events_v3 
WHERE campaign_id IN  (/* campaign_ids */) 
 
), 
-- STEP 1 step1 AS ( 
SELECT COUNT(*) AS step1_events 
FROM base_events 
WHERE event_name = 'Campaign View' 
), 
-- STEP 2 step2 AS ( 
SELECT COUNT(*) AS step2_events 
FROM base_events b 
WHERE b.event_name IN ( 
    'public_campaign_whatsapp_start_chat_click', 
    'public_campaign_whatsapp_start_chat_click_anon' 
) 
AND EXISTS ( 
    SELECT 1 
    FROM base_events v 
    WHERE v.visitor_id = b.visitor_id 
      AND v.event_name = 'Campaign View' 
      AND v.event_time < b.event_time 
) 
), 
-- STEP 3 step3 AS ( 
SELECT COUNT(*) AS step3_events 
FROM base_events c 
WHERE c.event_name = 'public_campaign_whatsapp_chat_redirect' AND EXISTS ( 
    SELECT 1 
    FROM base_events s 
    WHERE s.visitor_id = c.visitor_id 
      AND s.event_name IN ( 
          'public_campaign_whatsapp_start_chat_click', 
          'public_campaign_whatsapp_start_chat_click_anon' 
      ) 
      AND s.event_time < c.event_time 
) 
) 
SELECT 
s1.step1_events AS campaign_view, s2.step2_events AS start_chat, s3.step3_events AS chat_success 
FROM step1 s1 
CROSS JOIN step2 s2 
CROSS JOIN step3 s3; 
 
