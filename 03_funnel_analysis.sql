-- ====================== 模块3 行为漏斗分析 ======================
-- 3.1 五级转化漏斗
WITH funnel AS (
    select
        count(new_user) as 总用户数,
        SUM(CASE WHEN home_page > 0 THEN 1 ELSE 0 END) AS 首页用户,
        SUM(CASE WHEN home_page > 0 AND listing_page > 0 THEN 1 ELSE 0 END) AS 列表页用户,
        SUM(CASE WHEN home_page > 0 AND listing_page > 0 AND product_page > 0 THEN 1 ELSE 0 END) AS 商品页用户,
        SUM(CASE WHEN home_page > 0 AND listing_page > 0 AND product_page > 0 AND payment_page > 0 THEN 1 ELSE 0 END) AS 支付页用户,
        SUM(CASE WHEN home_page > 0 AND listing_page > 0 AND product_page > 0 AND payment_page > 0 AND confirmation_page > 0 THEN 1 ELSE 0 END) AS 确认页用户
    FROM `实战练习项目`.`user_behavior_clean`
)
SELECT
    总用户数,
    首页用户,
    CONCAT(ROUND(首页用户 * 100.0 / 总用户数, 2),'%') AS 首页到达率,
    列表页用户,
    CONCAT(ROUND(列表页用户 * 100.0 / NULLIF(首页用户, 0), 2),'%') AS 首页到列表转化率,
    商品页用户,
    CONCAT(ROUND(商品页用户 * 100.0 / NULLIF(列表页用户, 0), 2),'%') AS 列表到商品转化率,
    支付页用户,
    CONCAT(ROUND(支付页用户 * 100.0 / NULLIF(商品页用户, 0), 2),'%') AS 商品到支付转化率,
    确认页用户,
    CONCAT(ROUND(确认页用户 * 100.0 / NULLIF(支付页用户, 0), 2),'%') AS 支付到确认转化率,
    CONCAT(ROUND(确认页用户 * 100.0 / NULLIF(总用户数, 0), 2),'%') AS 整体确认转化率
FROM funnel;
#	总用户数	首页用户	首页到达率	列表页用户	首页到列表转化率	商品页用户	列表到商品转化率	支付页用户	商品到支付转化率	确认页用户	支付到确认转化率	整体确认转化率
1	100,000	100,000	100.00%	73,894	73.89%	49,618	67.15%	6,862	13.83%	2,404	35.03%	2.40%

-- 3.2 各环节流失率
WITH funnel AS (
    select
        count(new_user) as 总用户数,
        SUM(CASE WHEN home_page > 0 THEN 1 ELSE 0 END) AS 首页用户,
        SUM(CASE WHEN home_page > 0 AND listing_page > 0 THEN 1 ELSE 0 END) AS 列表页用户,
        SUM(CASE WHEN home_page > 0 AND listing_page > 0 AND product_page > 0 THEN 1 ELSE 0 END) AS 商品页用户,
        SUM(CASE WHEN home_page > 0 AND listing_page > 0 AND product_page > 0 AND payment_page > 0 THEN 1 ELSE 0 END) AS 支付页用户,
        SUM(CASE WHEN home_page > 0 AND listing_page > 0 AND product_page > 0 AND payment_page > 0 AND confirmation_page > 0 THEN 1 ELSE 0 END) AS 确认页用户
    FROM `实战练习项目`.`user_behavior_clean`
)
SELECT
    CONCAT(ROUND((首页用户 - 列表页用户) * 100.0 / NULLIF(首页用户, 0), 2),'%') AS 首页流失率,
    CONCAT(ROUND((列表页用户 - 商品页用户) * 100.0 / NULLIF(列表页用户, 0), 2),'%') AS 列表页流失率,
    CONCAT(ROUND((商品页用户 - 支付页用户) * 100.0 / NULLIF(商品页用户, 0), 2),'%') AS 商品页流失率,
    CONCAT(ROUND((支付页用户 - 确认页用户) * 100.0 / NULLIF(支付页用户, 0), 2),'%') AS 支付页流失率
FROM funnel;
#	首页流失率	列表页流失率	商品页流失率	支付页流失率
1	26.11%	32.85%	86.17%	64.97%
