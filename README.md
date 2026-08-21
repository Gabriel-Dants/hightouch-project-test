# Hightouch + Snowflake: Data Activation Trial (Olist Dataset)

A hands-on evaluation of **Hightouch** as a Reverse ETL / Data Activation tool — comparable to Segment's activation layer — using **Snowflake** as the Data Warehouse, built on top of the [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) and the [Marketing Funnel by Olist](https://www.kaggle.com/datasets/olistbr/marketing-funnel-olist), both from Kaggle.

The goal was to simulate a realistic B2B scenario (the *seller* side of the Olist marketplace) and put Hightouch through a full pipeline — data → segmentation → activation into CRM/engagement tools — to see how it stacks up against other CDP/activation tools in a production-like Martech setup.

---

## 🎯 Why this trial

I wanted to test-drive Hightouch's Reverse ETL approach end-to-end, from warehouse modeling to syncing into destination tools, and evaluate it as an alternative/complement to tools like Segment for data activation use cases:

1. Load and model raw data in a Data Warehouse (Snowflake)
2. Enrich synthetic identity data (name, email, phone) to simulate a real CRM environment
3. Model **SQL views** representing realistic marketing/retention use cases
4. Sync those views to destination tools via **Hightouch** (Reverse ETL)

---

## 🏗️ Architecture

```
Kaggle (CSV) → Snowflake (staging + enrichment) → SQL Views (use cases)
→ Hightouch (Reverse ETL) → HubSpot / Salesforce / engagement tools
```

- **Data Warehouse:** Snowflake
- **Identity enrichment:** Python (Faker) via a Python UDF in Snowflake
- **Use case modeling:** SQL Views
- **Activation (Reverse ETL):** Hightouch

---

## 📊 Dataset

- **Brazilian E-Commerce Public Dataset by Olist** — orders, products, sellers, reviews, customers
- **Marketing Funnel by Olist** — MQL (Marketing Qualified Lead) data and `closed_deals` (MQL-to-seller conversion)

Loaded manually into Snowflake from the Kaggle CSV files.

---

## 🔧 Data enrichment

Since the original dataset has no PII (emails, phone numbers), a synthetic enrichment layer was added to simulate a realistic CRM/Martech scenario:

- The **MQL** table was enriched with synthetic name, phone, email, and a `pewc = true` flag, generated via **Faker** through a **Python UDF in Snowflake**
- That identity is propagated to the **sellers** table via `closed_deals` (an MQL that became a seller carries the same identity)
- Sellers with no trace in the MQL funnel only get synthetic name and email (phone and `pewc` stay null), simulating sellers who entered through another channel

> Scripts in [`/src`](./src)

---

## 🧩 Data activation use cases tested

Four views were modeled, each representing a realistic marketing/retention use case:

| # | Use case | Goal |
|---|---|---|
| 1 | **Remarketing** — MQLs who never became sellers | Re-engage prospects who entered the funnel but never converted |
| 2 | **Top Sellers (Retention)** — Referral campaign | High-performing sellers are more likely to refer Olist to others — referral program |
| 3 | **Low satisfaction/reviews (Retention)** | Sellers with low ratings get offered a course to improve their selling process, aiming to reduce churn |
| 4 | **On-site course for top cosmetics sellers** by US state | Uses state and product category as dynamic values in communications |

Modeling notes applied across all views:
- **Lead origin** (from the MQL table) is always carried along, to allow analysis of which channel/segmentation performs best
- Other tables from the `ECOMMERCE_DATASET` (products, categories, reviews) are used to enrich the data and expose **dynamic values** (state, product category, etc.) for communications

> SQL scripts for the views in [`/src`](./src)

---

## 🔌 Activation via Hightouch

The views were connected as *models* in Hightouch and synced to CRM/engagement destinations (HubSpot, Salesforce, among others), mapping the dynamic fields (lead origin, state, category) as *traits*/attributes.

> Sync configs and screenshots in [`/src`](./src)

---

## 📁 Repository structure

```
/src        → SQL scripts (views), Python scripts (Faker/UDF), Hightouch sync configs and screenshots
README.md   → this document
```

---

## 💡 Takeaways from the trial

- **Synthetic identity enrichment:** designing identity propagation from MQL to seller (via `closed_deals`) required care to avoid inconsistent data between sellers who came through the marketing funnel and "direct" sellers (without full PII)
- **Python UDFs in Snowflake:** first hands-on experience writing enrichment logic (Faker) directly inside Snowflake via UDF, instead of pre-processing outside the warehouse
- **Use-case-driven modeling:** instead of generic views, working through 4 realistic business use cases (remarketing, retention, anti-churn, segmented upsell) showed how a Martech team prioritizes and structures data for activation
- **Dynamic values in communications:** learned the importance of clearly naming columns like `seller_state` and `product_category_name` in the views, so mapping in Hightouch/Braze is direct, with no extra transformation needed
- **Reverse ETL in practice:** got a full-loop understanding of "data modeled in the warehouse → automated sync → activation destination," which is the core of Martech Engineering work — and a useful comparison point against Segment-style activation

---

## 🛠️ Stack

- **Snowflake** — Data Warehouse
- **Python (Faker)** — synthetic data generation via UDF
- **SQL** — activation view modeling
- **Hightouch** — Reverse ETL / Data Activation

---

## 👤 Author

Gabriel — Marketing Automation & Integration Engineer (Braze, Segment CDP, Snowflake)
