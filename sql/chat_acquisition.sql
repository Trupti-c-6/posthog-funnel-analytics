code 
WITH base_events AS ( 
2.	SELECT 
3.	visitor_id, 
4.	event_name, 
5.	event_time, 
6.	campaign_id 
7.	FROM raw_posthog_events_v3 
8.   WHERE campaign_id IN  (/* campaign_ids */) 
9.  
10.      
11. ), 
12.	-- STEP 1: ALL views (event-level) 
13.	step1 AS ( 
14.	SELECT COUNT(*) AS step1_events 
15.	FROM base_events 
16.	WHERE event_name = 'Campaign View' 
17. ), 
18.	-- STEP 2: ALL clicks (event-level) 
19.	step2 AS ( 
20.	SELECT COUNT(*) AS step2_events 
21.	FROM base_events b 
22.	WHERE b.event_name IN ( 
23.	'public_campaign_whatsapp_start_chat_click', 
24.	'public_campaign_whatsapp_start_chat_click_anon' 
25.    ) 
26.	AND EXISTS ( 
27.	SELECT 1 
28.	FROM base_events v 
29.	WHERE v.visitor_id = b.visitor_id 
30.	AND v.event_name = 'Campaign View' 
31.	AND v.event_time < b.event_time 
32.    ) 33. ), 
34.	-- STEP 3: JOIN counted ONLY ONCE per user 
35.	step3 AS ( 
36.	SELECT COUNT(DISTINCT j.visitor_id) AS step3_users 
37.	FROM base_events j 
38.	WHERE j.event_name = 'JOIN_CAMPAIGN' 
39.	AND EXISTS ( 
40.	SELECT 1 
41.	FROM base_events c 
42.	WHERE c.visitor_id = j.visitor_id 
43.	AND c.event_name IN ( 
44.	'public_campaign_whatsapp_start_chat_click', 
45.	'public_campaign_whatsapp_start_chat_click_anon' 
46.	) 
47.	AND c.event_time < j.event_time 
48.    ) 49. ) 
50.	SELECT 
51.	s1.step1_events AS Campaign_views, 
52.	s2.step2_events AS start_Chat_clicks, 
53.	s3.step3_users  AS Influencer_onboarded 
54.	FROM step1 s1 
55.	CROSS JOIN step2 s2 56. CROSS JOIN step3 s3; 
