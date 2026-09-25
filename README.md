## Overview & Objectives

The core logic processes raw data from multiple operational tables to generate comprehensive insights into user lifecycles and communication engagement across different regions.

Key analytical dimensions include:

*   **Account Dynamics:** Tracking account creation dates, verification statuses (`is_verified`), and subscription/unsubscription trends (`is_unsubscribed`).
*   **Email Engagement:** Measuring daily performance indicators such as messages sent (`sent_msg`), opened (`open_msg`), and visited/clicked (`visit_msg`).
*   **Geo-Performance & Ranking:** Aggregating metrics by country (`country`) and send intervals (`send_interval`), utilizing window functions (`DENSE_RANK`) to isolate and analyze top-performing regions.

---

## SQL Pipeline Architecture

The workflow is structured into a multi-step Common Table Expression (CTE) pipeline:

1.  `acc_stats`: Extracts core account information, linking sessions, countries, and status flags.
2.  `msg_stats`: Maps email delivery dates relative to account creation and calculates daily message metrics (`sent`, `open`, `visit`).
3.  `acc_summary` & `msg_summary`: Standardizes and aggregates account counts and message metrics respectively.
4.  `union_data`: Combines account and message summaries into a unified analytical dataset.
5.  `country_stats` & `rank_data`: Applies window functions to compute total country-level volumes and assigns dense ranks to filter the top 10 most active countries.

---

## Tech Stack & Environment

*   **Database / Query Language:** Standard SQL (compatible with Google BigQuery / analytical data warehouses due to functions like `date_add` and window syntax).
*   **Key Concepts:** CTEs, Aggregations, Window Functions (`OVER`, `PARTITION BY`), Ranking (`DENSE_RANK`).
