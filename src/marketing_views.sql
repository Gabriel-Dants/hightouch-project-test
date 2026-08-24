-- Remarketing: MQL who didn't becomes a seller
CREATE OR REPLACE VIEW MARKETING_FUNNEL.VW_REMARKETING_MQL_NOT_CONVERTED AS
SELECT
    mql.mql_id,
    mql.first_contact_date,
    mql.origin,           -- origem do lead, pra segmentação
    mql.full_name,
    mql.email,
    mql.phone
FROM PERSONAL_PROJECT.MARKETING_FUNNEL.MQL_ENRICHED mql
LEFT JOIN PERSONAL_PROJECT.MARKETING_FUNNEL.OLIST_CLOSED_DEALS_DATASET cd ON mql.mql_id = cd.mql_id
WHERE cd.mql_id IS NULL;

-- Top-Sellers (Retention): Referal Campaign (Who sells great probably will indicate Olist for others)
CREATE OR REPLACE VIEW MARKETING_FUNNEL.VW_TOP_SELLERS_REFERRAL AS
SELECT
    s.seller_id,
    s.FULL_NAME,
    s.email,
    s.phone,
    s.PEWC,
    SUM(oi.price) AS total_sales,
    RANK() OVER (ORDER BY SUM(oi.price) DESC) AS sales_rank
FROM PERSONAL_PROJECT.ECOMMERCE_DATASET.SELLER_IDENTITY_FULL s
JOIN PERSONAL_PROJECT.ECOMMERCE_DATASET.OLIST_ORDER_ITEMS_DATASET oi ON s.seller_id = oi.seller_id
GROUP BY s.seller_id, s.FULL_NAME, s.email, s.phone, s.PEWC
QUALIFY sales_rank <= 100;

-- Low rate of Satisfaction/reviews from customers (Retention): Try to avoid churn offering a course to improve the selling process
CREATE OR REPLACE VIEW MARKETING_FUNNEL.VW_LOW_SATISFACTION_SELLERS AS
SELECT
    s.seller_id,
    s.FULL_NAME,
    s.email,
    s.PEWC,
    AVG(r.review_score) AS avg_review_score,
    COUNT(r.review_id) AS total_reviews
FROM PERSONAL_PROJECT.ECOMMERCE_DATASET.SELLER_IDENTITY_FULL s
JOIN PERSONAL_PROJECT.ECOMMERCE_DATASET.OLIST_ORDER_ITEMS_DATASET oi ON s.seller_id = oi.seller_id
JOIN PERSONAL_PROJECT.ECOMMERCE_DATASET.OLIST_ORDERS_DATASET o ON oi.order_id = o.order_id
JOIN PERSONAL_PROJECT.ECOMMERCE_DATASET.OLIST_ORDER_REVIEWS_DATASET r ON o.order_id = r.order_id
GROUP BY s.seller_id, s.FULL_NAME, s.email, s.PEWC
HAVING AVG(r.review_score) <= 2.5 AND COUNT(r.review_id) > 5;

-- Selling a on-site course for the top-sellers of cosmetic from a X state from US.
CREATE OR REPLACE VIEW MARKETING_FUNNEL.VW_COSMETIC_TOPSELLERS_BY_STATE AS
SELECT
    s.seller_id,
    s.FULL_NAME,
    s.email,
    s.PEWC,
    s.seller_state,        -- valor dinâmico p/ comunicação
    p.product_category_name AS category,  -- valor dinâmico p/ comunicação
    SUM(oi.price) AS total_sales
FROM PERSONAL_PROJECT.ECOMMERCE_DATASET.SELLER_IDENTITY_FULL s
JOIN PERSONAL_PROJECT.ECOMMERCE_DATASET.OLIST_ORDER_ITEMS_DATASET oi ON s.seller_id = oi.seller_id
JOIN PERSONAL_PROJECT.ECOMMERCE_DATASET.OLIST_PRODUCTS_DATASET p ON oi.product_id = p.product_id
WHERE p.product_category_name ILIKE '%cool_stuff%'  -- ajustar ao nome real na tabela
GROUP BY s.seller_id, s.name, s.email, s.seller_state, p.product_category_name
QUALIFY RANK() OVER (PARTITION BY s.seller_state ORDER BY SUM(oi.price) DESC) <= 20;