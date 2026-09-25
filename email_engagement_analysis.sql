WITH
  acc_stats AS (  -- step 1 - accounts
    SELECT
      s.date AS acc_creation_date,
      ac.id,
      sp.country,
      ac.send_interval,
      ac.is_verified,
      ac.is_unsubscribed
    FROM DA.account AS ac
    JOIN DA.account_session AS acs
      ON ac.id = acs.account_id
    JOIN DA.session_params AS sp
      ON sp.ga_session_id = acs.ga_session_id
    JOIN DA.session AS s
      ON s.ga_session_id = sp.ga_session_id
    WHERE
      ac.is_verified
        IS NOT NULL  -- filter for verified - checked after adding filter - count is now 0
      AND ac.is_unsubscribed
        IS NOT NULL  -- filter for unsubscribed - checked after adding filter - count is now 0
    GROUP BY 1, 2, 3, 4, 5, 6
  ),
  msg_stats AS (  -- step 1 - emails
    SELECT
      date_add(acc_stats.acc_creation_date, INTERVAL es.sent_date day)
        AS sent_date,
      es.id_account,
      acc_stats.country,
      acc_stats.send_interval,
      acc_stats.is_verified,
      acc_stats.is_unsubscribed,
      COUNT(DISTINCT es.id_message) AS sent_msg,
      COUNT(DISTINCT eo.id_message) AS open_msg,
      COUNT(DISTINCT ev.id_message) AS visit_msg
    FROM DA.email_sent AS es
    JOIN acc_stats
      ON es.id_account = acc_stats.id
    LEFT JOIN DA.email_open AS eo
      ON es.id_message = eo.id_message
    LEFT JOIN DA.email_visit AS ev
      ON es.id_message = ev.id_message
    WHERE
      es.sent_date
      IS NOT NULL  -- filter for sent date - checked after adding filter - count is now 0
    GROUP BY 1, 2, 3, 4, 5, 6
  ),
  acc_summary AS (  -- step 2 - aggregating accounts
    SELECT
      acc_creation_date AS date,
      country,
      send_interval,
      is_verified,
      is_unsubscribed,
      COUNT(DISTINCT id) AS account_cnt,
      0 AS sent_msg,
      0 AS open_msg,
      0 AS visit_msg
    FROM acc_stats
    GROUP BY 1, 2, 3, 4, 5
  ),
  msg_summary AS (  -- step 2 - aggregating emails
    SELECT
      sent_date AS date,
      country,
      send_interval,
      is_verified,
      is_unsubscribed,
      0 AS account_cnt,
      SUM(sent_msg) AS sent_msg,
      SUM(open_msg) AS open_msg,
      SUM(visit_msg) AS visit_msg
    FROM msg_stats
    GROUP BY 1, 2, 3, 4, 5
  ),
  union_data AS (  -- combining data from step 2
    SELECT * FROM acc_summary
    UNION ALL
    SELECT * FROM msg_summary
  ),
  country_stats
  AS (  -- step 3 - window function - sum of accounts and messages by country
    SELECT
      ud.*,
      SUM(account_cnt) OVER (PARTITION BY country) AS total_country_account_cnt,
      SUM(sent_msg) OVER (PARTITION BY country) AS total_country_sent_cnt
    FROM union_data AS ud
  ),
  rank_data AS (  -- step 4 - window function - assigning ranks
    SELECT
      cs.*,
      DENSE_RANK()
        OVER (ORDER BY total_country_account_cnt DESC)
        AS rank_total_country_account_cnt,
      DENSE_RANK()
        OVER (ORDER BY total_country_sent_cnt DESC)
        AS rank_total_country_sent_cnt
    FROM country_stats AS cs
  )
SELECT
  *
FROM rank_data
WHERE  -- filtering top 10 accounts or messages sent
  rank_total_country_account_cnt <= 10
  OR rank_total_country_sent_cnt <= 10
ORDER BY
  1 DESC, 2
