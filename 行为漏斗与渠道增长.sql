-- ====================== 模块1 数据集清洗与预处理 ======================
-- 1.查看表结构与基础信息
desc `实战练习项目`.`用户行为漏斗与渠道增长`;
select COUNT(*) as 总行数 from `实战练习项目`.`用户行为漏斗与渠道增长`;
select * from `实战练习项目`.`用户行为漏斗与渠道增长` limit 20;

-- 2.缺失值检查
select
    COUNT(*) 总行数,
    SUM(CASE WHEN new_user IS NULL THEN 1 ELSE 0 END) AS new_user缺失,
    SUM(case when age is null or age<1 or age='' then 1 else 0 end) as age缺失,
    SUM(CASE WHEN sex IS NULL OR sex = '' THEN 1 ELSE 0 END) AS sex缺失,
    SUM(CASE WHEN market IS NULL OR market = '' THEN 1 ELSE 0 END) AS market缺失,
    SUM(CASE WHEN device IS NULL OR device = '' THEN 1 ELSE 0 END) AS device缺失,
    SUM(CASE WHEN operative_system IS NULL OR operative_system = '' THEN 1 ELSE 0 END) AS os缺失,
    SUM(CASE WHEN source IS NULL OR source = '' THEN 1 ELSE 0 END) AS source缺失,
    SUM(CASE WHEN total_pages_visited IS NULL THEN 1 ELSE 0 END) AS total_pages缺失,
    SUM(CASE WHEN home_page IS NULL THEN 1 ELSE 0 END) AS home_page缺失,
    SUM(CASE WHEN listing_page IS NULL THEN 1 ELSE 0 END) AS listing_page缺失,
    SUM(CASE WHEN product_page IS NULL THEN 1 ELSE 0 END) AS product_page缺失,
    SUM(CASE WHEN payment_page IS NULL THEN 1 ELSE 0 END) AS payment_page缺失,
    SUM(CASE WHEN confirmation_page IS NULL THEN 1 ELSE 0 END) AS confirmation_page缺失
from `实战练习项目`.`用户行为漏斗与渠道增长`;
--【探查结论】所有字段无NULL、无空字符串缺失，缺失值层面数据质量良好

-- 3.重复值检查
select
    new_user,
    age,
    sex,
    market,
    device,
    operative_system,
    source,
    total_pages_visited,
    home_page,
    listing_page,
    product_page,
    payment_page,
    confirmation_page,
    count(*) as 重复次数
from `实战练习项目`.`用户行为漏斗与渠道增长`
group by
    new_user,
    age,
    sex,
    market,
    device,
    operative_system,
    source,
    total_pages_visited,
    home_page,
    listing_page,
    product_page,
    payment_page,
    confirmation_page
having COUNT(*) > 1
order by 重复次数 desc;
--【探查结论】无重复样本，无需去重

-- 4.异常值检查
-- 新老用户取值检查
select new_user, COUNT(*)
from `实战练习项目`.`用户行为漏斗与渠道增长`
group by new_user;

-- 年龄异常检查
SELECT *
FROM `实战练习项目`.`用户行为漏斗与渠道增长`
WHERE age <= 10 OR age > 100;
-- --【探查结论】发现2条年龄异常记录(109、123)，超出人类合理年龄范围

-- 性别检查
select
       case
       	when sex='female' then '女性'
       	when sex='male' then '男性'
       	else '未知性别'
       end as sex_clean,
       count(*)
from `实战练习项目`.`用户行为漏斗与渠道增长`
group by sex_clean;
--【探查结论】sex字段存在female、male、0三类取值，0不属于业务性别分类

-- 页面访问次数负值检查
SELECT *
FROM `实战练习项目`.`用户行为漏斗与渠道增长`
WHERE total_pages_visited < 0
   OR home_page < 0
   OR listing_page < 0
   OR product_page < 0
   OR payment_page < 0
   OR confirmation_page < 0;
--【探查结论】页面访问量无负数异常

-- 页面访问逻辑矛盾检查
SELECT *
FROM `实战练习项目`.`用户行为漏斗与渠道增长`
WHERE COALESCE(total_pages_visited, 0) < GREATEST(
    COALESCE(home_page, 0),
    COALESCE(listing_page, 0),
    COALESCE(product_page, 0),
    COALESCE(payment_page, 0),
    COALESCE(confirmation_page, 0)
);
--【探查结论】页面访问指标逻辑自洽，不存在逻辑冲突脏数据

-- 设备取值检查
SELECT device, COUNT(*) FROM `实战练习项目`.`用户行为漏斗与渠道增长` GROUP BY device;
--【探查结论】device合法值mobile/desktop，存在异常编码0

-- 操作系统取值检查
SELECT operative_system, COUNT(*)
FROM `实战练习项目`.`用户行为漏斗与渠道增长` GROUP BY operative_system;
--【探查结论】os合法值android/iOS/windows/mac/other/linux，存在异常编码0

-- 流量来源取值检查
SELECT source, COUNT(*) FROM `实战练习项目`.`用户行为漏斗与渠道增长` GROUP BY source;
--【探查结论】source合法值Direct/Seo/Ads，存在异常编码0

-- 全部探查完成，生成清洗后总表
CREATE TABLE `实战练习项目`.`user_behavior_clean` AS
SELECT
    new_user,
    -- 年龄清洗：1~100为有效年龄，异常置NULL
    CASE
	    WHEN age BETWEEN 1 AND 100 THEN age ELSE NULL
    END AS age_clean,
    -- 性别清洗
    CASE
        WHEN sex='female' THEN '女性'
        WHEN sex='male' THEN '男性'
        ELSE '未知性别'
    END AS sex_clean,
    -- 市场编码：不做文字映射，保留原始编码
    market AS market_clean,
    -- 设备清洗
    CASE
	    WHEN device IN ('mobile','desktop') THEN device ELSE '未知设备'
    END AS device_clean,
    -- 操作系统清洗
    CASE
	    WHEN operative_system IN ('android','iOS','windows','mac','other','linux') THEN operative_system ELSE '未知系统'
    END AS os_clean,
    -- 流量来源清洗
    CASE
	    WHEN source IN ('Direct','Seo','Ads') THEN source ELSE '未知来源'
    END AS source_clean,
    total_pages_visited,
    home_page,
    listing_page,
    product_page,
    payment_page,
    confirmation_page
FROM `实战练习项目`.`用户行为漏斗与渠道增长`;

-- 校验清洗之后的表分布（验证清洗效果）
SELECT sex_clean,COUNT(*) FROM `实战练习项目`.`user_behavior_clean` GROUP BY sex_clean;
SELECT device_clean,COUNT(*) FROM `实战练习项目`.`user_behavior_clean` GROUP BY device_clean;
SELECT os_clean,COUNT(*) FROM `实战练习项目`.`user_behavior_clean` GROUP BY os_clean;
SELECT source_clean,COUNT(*) FROM `实战练习项目`.`user_behavior_clean` GROUP BY source_clean;

-- ====================== 模块2 用户结构画像 ======================
-- 2.1新用户占比
SELECT
    CASE
	    WHEN new_user = 1 THEN '新用户' ELSE '老用户'
    END AS 用户类型,
    COUNT(*) AS 用户数,
    CONCAT(ROUND(COUNT(*)*100.0/ SUM(COUNT(*) ) OVER(), 2),'%') AS 占比_pct
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY 用户类型;
#	用户类型	用户数	占比_pct
1	老用户	68,475	68.48%
2	新用户	31,525	31.53%

-- 2.2 性别分布
SELECT
    sex_clean AS 性别,
    COUNT(*) AS 用户数,
    CONCAT(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2),'%') AS 占比_pct
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY sex_clean
ORDER BY 用户数 DESC;
#	性别	用户数	占比_pct
1	女性	60,554	60.55%
2	男性	38,673	38.67%
3	未知性别	773	0.77%

-- 2.3 年龄段分布
SELECT
    CASE
        WHEN age_clean < 20 THEN '20岁以下'
        WHEN age_clean BETWEEN 20 AND 29 THEN '20-29岁'
        WHEN age_clean BETWEEN 30 AND 39 THEN '30-39岁'
        WHEN age_clean BETWEEN 40 AND 49 THEN '40-49岁'
        WHEN age_clean >= 50 THEN '50岁及以上'
        ELSE '未知年龄'
    END AS 年龄段,
    COUNT(*) AS 用户数,
    CONCAT(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2),'%') AS 占比_pct
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY 年龄段
ORDER BY 用户数 DESC;
#	年龄段	用户数	占比_pct
1	20-29岁	41,671	41.67%
2	30-39岁	37,226	37.23%
3	40-49岁	12,075	12.08%
4	20岁以下	7,413	7.41%
5	50岁及以上	1,613	1.61%
6	未知年龄	2	0.00%

-- 2.4 地区分布
SELECT
     market_clean  AS 市场编码,
     COUNT(*) AS 各地区人数,
     CONCAT(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(),2),'%') AS 各地区人数占比
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY market_clean;
#	市场编码	各地区人数	各地区人数占比
1	1	58,094	58.09%
2	2	17,795	17.80%
3	4	6,221	6.22%
4	3	17,890	17.89%

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

-- ====================== 模块4 渠道质量分析 ======================
-- 4.1 各渠道转化质量
SELECT
    source_clean AS 渠道,
    COUNT(*) AS 用户数,
    ROUND(AVG(total_pages_visited), 2) AS 平均访问页数,
    SUM(CASE WHEN confirmation_page > 0 THEN 1 ELSE 0 END) AS 确认页用户数,
    CONCAT(ROUND(
        SUM(CASE WHEN confirmation_page > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ),'%') AS 确认转化率
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY source_clean
ORDER BY 确认转化率 DESC;
#	渠道	用户数	平均访问页数	确认页用户数	确认转化率
1	Direct	56,688	5.79	1,718	3.03%
2	Ads	14,852	6.07	245	1.65%
3	未知来源	123	4.92	2	1.63%
4	Seo	28,337	6.07	439	1.55%

-- 4.2 各渠道支付页流失率
SELECT
    source_clean AS 渠道,
    SUM(CASE WHEN payment_page > 0 THEN 1 ELSE 0 END) AS 支付页用户数,
    SUM(CASE WHEN payment_page > 0 AND confirmation_page = 0 THEN 1 ELSE 0 END) AS 支付页流失用户数,
    CONCAT(ROUND(
        SUM(CASE WHEN payment_page > 0 AND confirmation_page = 0 THEN 1 ELSE 0 END) * 100.0
        / NULLIF(SUM(CASE WHEN payment_page > 0 THEN 1 ELSE 0 END), 0),
        2
    ),'%') AS 支付页流失率
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY source_clean
ORDER BY 支付页流失率 DESC;
#	渠道	支付页用户数	支付页流失用户数	支付页流失率
1	Seo	1,706	1,267	74.27%
2	Ads	904	659	72.90%
3	未知来源	6	4	66.67%
4	Direct	4,246	2,528	59.54%

-- ====================== 模块5 设备与操作系统分析 ======================
-- 5.1 设备转化对比
SELECT
    device_clean AS 设备,
    COUNT(*) AS 用户数,
    ROUND(AVG(total_pages_visited), 2) AS 平均访问页数,
    CONCAT(ROUND(
        SUM(CASE WHEN confirmation_page > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ),'%') AS 确认转化率
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY device_clean
ORDER BY 确认转化率 DESC;
#	设备	用户数	平均访问页数	确认转化率
1	desktop	39,503	5.73	2.60%
2	mobile	60,364	6.02	2.27%
3	未知设备	133	5.65	1.50%

-- 5.2 操作系统转化对比
SELECT
    os_clean AS 操作系统,
    COUNT(*) AS 用户数,
    ROUND(AVG(total_pages_visited), 2) AS 平均访问页数,
    CONCAT(ROUND(
        SUM(CASE WHEN confirmation_page > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ),'%') AS 确认转化率
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY os_clean
ORDER BY 确认转化率 DESC;
#	操作系统	用户数	平均访问页数	确认转化率
1	mac	8,552	6.33	3.82%
2	iOS	28,570	5.67	2.41%
3	windows	29,700	5.58	2.31%
4	android	27,328	6.51	2.28%
5	未知系统	217	5.13	1.38%
6	other	4,446	5.35	1.37%
7	linux	1,187	5.25	1.26%

-- 5.3 设备 × 系统交叉
SELECT
    device_clean AS 设备,
    os_clean AS 操作系统,
    COUNT(*) AS 用户数,
    ROUND(AVG(total_pages_visited), 2) AS 平均访问页数,
    CONCAT(ROUND(
        SUM(CASE WHEN confirmation_page > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ),'%') AS 确认转化率
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY device_clean, os_clean
HAVING COUNT(*) >= 100
ORDER BY 确认转化率 DESC;
#	设备	操作系统	用户数	平均访问页数	确认转化率
1	desktop	mac	8,541	6.33	3.83%
2	mobile	iOS	28,531	5.67	2.41%
3	desktop	windows	29,658	5.58	2.31%
4	mobile	android	27,300	6.51	2.28%
5	mobile	未知系统	132	5.37	2.27%
6	mobile	other	4,401	5.36	1.34%
7	desktop	linux	1,185	5.25	1.27%

-- ====================== 模块6 市场编码分析 ======================
-- 6.1 各市场编码转化情况
SELECT
    market_clean AS 市场编码,
    COUNT(*) AS 用户数,
    ROUND(AVG(total_pages_visited),2) AS 平均访问页数,
    SUM(CASE WHEN confirmation_page>0 THEN 1 ELSE 0 END) AS 确认用户数,
    CONCAT(ROUND(SUM(CASE WHEN confirmation_page>0 THEN 1 ELSE 0 END)*100.0/COUNT(*),2),'%') AS 确认转化率
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY market_clean
ORDER BY 确认转化率 DESC;
#	市场编码	用户数	平均访问页数	确认用户数	确认转化率
1	4	6,221	6.49	199	3.20%
2	2	17,795	6.15	473	2.66%
3	1	58,094	5.84	1,424	2.45%
4	3	17,890	5.69	308	1.72%

-- 6.2 市场编码 × 渠道交叉
SELECT
    market_clean AS 市场编码,
    source_clean AS 渠道,
    COUNT(*) AS 用户数,
    CONCAT(ROUND(SUM(CASE WHEN confirmation_page>0 THEN 1 ELSE 0 END)*100.0/COUNT(*),2),'%') AS 确认转化率
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY market_clean, source_clean
HAVING COUNT(*)>=100
ORDER BY 市场编码,确认转化率 DESC;
#	市场编码	渠道	用户数	确认转化率
1	1	Direct	33,045	3.07%
2	1	Ads	8,567	1.73%
3	1	Seo	16,423	1.59%
4	3	Direct	10,087	2.12%
5	3	Seo	5,145	1.26%
6	3	Ads	2,639	1.10%
7	2	Direct	10,048	3.45%
8	2	Ads	2,653	1.85%
9	2	Seo	5,078	1.52%
10	4	Direct	3,508	4.10%
11	4	Seo	1,691	2.13%
12	4	Ads	993	1.91%

-- ====================== 模块7 新老用户差异分析 ======================
-- 7.1 新老用户整体对比
SELECT
    CASE WHEN new_user = 1 THEN '新用户' ELSE '老用户' END AS 用户类型,
    COUNT(*) AS 用户数,
    ROUND(AVG(total_pages_visited), 2) AS 平均访问页数,
    SUM(CASE WHEN confirmation_page > 0 THEN 1 ELSE 0 END) AS 确认页用户数,
    CONCAT(ROUND(
        SUM(CASE WHEN confirmation_page > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ),'%') AS 确认转化率
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY 用户类型;
#	用户类型	用户数	平均访问页数	确认页用户数	确认转化率
1	老用户	68,475	5.75	1,941	2.83%
2	新用户	31,525	6.25	463	1.47%

-- 7.2 新老用户各环节到达率对比
SELECT
    CASE WHEN new_user = 1 THEN '新用户' ELSE '老用户' END AS 用户类型,
    COUNT(*) AS 总用户数,
    CONCAT(ROUND(SUM(CASE WHEN home_page > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2),'%') AS 首页到达率,
    CONCAT(ROUND(SUM(CASE WHEN listing_page > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2),'%') AS 列表页到达率,
    CONCAT(ROUND(SUM(CASE WHEN product_page > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2),'%') AS 商品页到达率,
    CONCAT(ROUND(SUM(CASE WHEN payment_page > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2),'%') AS 支付页到达率,
    CONCAT(ROUND(SUM(CASE WHEN confirmation_page > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2),'%') AS 确认页到达率
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY 用户类型;
#	用户类型	总用户数	首页到达率	列表页到达率	商品页到达率	支付页到达率	确认页到达率
1	老用户	68,475	100.00%	74.02%	50.11%	7.35%	2.83%
2	新用户	31,525	100.00%	73.62%	48.55%	5.80%	1.47%

-- ====================== 模块8 年龄与性别分群分析 ======================
-- 8.1 年龄段转化对比
SELECT
    CASE
        WHEN age_clean < 20 THEN '20岁以下'
        WHEN age_clean BETWEEN 20 AND 29 THEN '20-29岁'
        WHEN age_clean BETWEEN 30 AND 39 THEN '30-39岁'
        WHEN age_clean BETWEEN 40 AND 49 THEN '40-49岁'
        WHEN age_clean >= 50 THEN '50岁及以上'
        ELSE '未知年龄'
    END AS 年龄段,
    COUNT(*) AS 用户数,
    CONCAT(ROUND(
        SUM(CASE WHEN confirmation_page > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ),'%') AS 确认转化率
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY 年龄段
ORDER BY 确认转化率 DESC;
#	年龄段	用户数	确认转化率
1	20岁以下	7,413	4.13%
2	20-29岁	41,671	3.24%
3	30-39岁	37,226	1.86%
4	40-49岁	12,075	0.47%
5	50岁及以上	1,613	0.00%
6	未知年龄	2	0.00%

-- 8.2 性别转化对比
SELECT
    sex_clean AS 性别,
    COUNT(*) AS 用户数,
    ROUND(AVG(total_pages_visited), 2) AS 平均访问页数,
    CONCAT(ROUND(
        SUM(CASE WHEN confirmation_page > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ),'%') AS 确认转化率
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY sex_clean
ORDER BY 确认转化率 DESC;
#	性别	用户数	平均访问页数	确认转化率
1	女性	60,554	5.98	3.02%
2	未知性别	773	5.29	1.94%
3	男性	38,673	5.81	1.45%

-- ====================== 模块9 浏览深度与转化关系 ======================
-- 9.1 浏览深度分桶与转化率
SELECT
    CASE
        WHEN total_pages_visited <= 1 THEN '1页'
        WHEN total_pages_visited <= 3 THEN '2-3页'
        WHEN total_pages_visited <= 5 THEN '4-5页'
        WHEN total_pages_visited <= 10 THEN '6-10页'
        ELSE '10页以上'
    END AS 浏览深度,
    COUNT(*) AS 用户数,
    CONCAT(ROUND(
        SUM(CASE WHEN confirmation_page > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ),'%') AS 确认转化率
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY 浏览深度
ORDER BY MIN(total_pages_visited);
#	浏览深度	用户数	确认转化率
1	1页	3,442	0.00%
2	2-3页	32,080	0.00%
3	4-5页	24,223	0.23%
4	6-10页	28,125	1.13%
5	10页以上	12,130	16.74%

-- ====================== 模块10 支付页流失专项分析 ======================
-- 10.1 各年龄段支付页流失
SELECT
    CASE
        WHEN age_clean < 20 THEN '20岁以下'
        WHEN age_clean BETWEEN 20 AND 29 THEN '20-29岁'
        WHEN age_clean BETWEEN 30 AND 39 THEN '30-39岁'
        WHEN age_clean BETWEEN 40 AND 49 THEN '40-49岁'
        WHEN age_clean >= 50 THEN '50岁及以上'
        ELSE '未知年龄'
    END AS 年龄段,
    SUM(CASE WHEN payment_page>0 THEN 1 ELSE 0 END) AS 支付页用户,
    SUM(CASE WHEN payment_page>0 AND confirmation_page=0 THEN 1 ELSE 0 END) AS 流失用户,
    CONCAT(ROUND(SUM(CASE WHEN payment_page>0 AND confirmation_page=0 THEN 1 ELSE 0 END)*100.0/NULLIF(SUM(CASE WHEN payment_page>0 THEN 1 ELSE 0 END),0),2),'%') AS 支付页流失率
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY 年龄段
ORDER BY 支付页流失率 DESC;
#	年龄段	支付页用户	流失用户	支付页流失率
1	40-49岁	609	552	90.64%
2	30-39岁	2,351	1,660	70.61%
3	20-29岁	3,191	1,841	57.69%
4	20岁以下	644	338	52.48%
5	50岁及以上	67	67	100.00%
6	未知年龄	0	0	[NULL]

-- 10.2 各性别支付页流失
SELECT
    sex_clean AS 性别,
    SUM(CASE WHEN payment_page>0 THEN 1 ELSE 0 END) AS 支付页用户,
    SUM(CASE WHEN payment_page>0 AND confirmation_page=0 THEN 1 ELSE 0 END) AS 流失用户,
    CONCAT(ROUND(SUM(CASE WHEN payment_page>0 AND confirmation_page=0 THEN 1 ELSE 0 END)*100.0/NULLIF(SUM(CASE WHEN payment_page>0 THEN 1 ELSE 0 END),0),2),'%') AS 支付页流失率
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY 性别
ORDER BY 支付页流失率 DESC;
#	性别	支付页用户	流失用户	支付页流失率
1	男性	2,212	1,653	74.73%
2	未知性别	49	34	69.39%
3	女性	4,601	2,771	60.23%

-- ====================== 模块11 交叉分析 ======================
-- 11.1 渠道 × 设备
SELECT
    source_clean AS 渠道,
    device_clean AS 设备,
    COUNT(*) AS 用户数,
    CONCAT(ROUND(SUM(CASE WHEN confirmation_page > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2),'%') AS 确认转化率
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY source_clean, device_clean
HAVING COUNT(*) >= 100
ORDER BY 确认转化率 DESC;
#	渠道	设备	用户数	确认转化率
1	Direct	desktop	22,497	3.35%
2	Direct	mobile	34,118	2.82%
3	Ads	desktop	5,941	1.72%
4	Ads	mobile	8,887	1.61%
5	Seo	mobile	17,292	1.55%
6	Seo	desktop	11,009	1.55%

-- 11.2 渠道 × 新老用户
SELECT
    source_clean AS 渠道,
    CASE WHEN new_user = 1 THEN '新用户' ELSE '老用户' END AS 用户类型,
    COUNT(*) AS 用户数,
    CONCAT(ROUND(SUM(CASE WHEN confirmation_page > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2),'%') AS 确认转化率
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY source_clean, 用户类型
ORDER BY source_clean, 确认转化率 DESC;
#	渠道	用户类型	用户数	确认转化率
1	Ads	新用户	10,435	1.67%
2	Ads	老用户	4,417	1.61%
3	Direct	老用户	54,426	3.12%
4	Direct	新用户	2,262	0.84%
5	Seo	老用户	9,545	1.77%
6	Seo	新用户	18,792	1.44%
7	未知来源	老用户	87	2.30%
8	未知来源	新用户	36	0.00%

-- 11.3 设备 × 操作系统
SELECT
    device_clean AS 设备,
    os_clean AS 操作系统,
    COUNT(*) AS 用户数,
    CONCAT(ROUND(SUM(CASE WHEN confirmation_page > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2),'%') AS 确认转化率
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY device_clean, os_clean
HAVING COUNT(*) >= 100
ORDER BY 确认转化率 DESC;
#	设备	操作系统	用户数	确认转化率
1	desktop	mac	8,541	3.83%
2	mobile	iOS	28,531	2.41%
3	desktop	windows	29,658	2.31%
4	mobile	android	27,300	2.28%
5	mobile	未知系统	132	2.27%
6	mobile	other	4,401	1.34%
7	desktop	linux	1,185	1.27%

-- 11.4 市场编码 × 渠道
SELECT
    market_clean AS 市场编码,
    source_clean AS 渠道,
    COUNT(*) AS 用户数,
    CONCAT(
        ROUND(
            SUM(CASE WHEN confirmation_page > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
            2
        ),'%'
    ) AS 确认转化率
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY market_clean, source_clean
HAVING COUNT(*) >= 100
ORDER BY 确认转化率 DESC;
#	市场编码	渠道	用户数	确认转化率
1	4	Direct	3,508	4.10%
2	2	Direct	10,048	3.45%
3	1	Direct	33,045	3.07%
4	4	Seo	1,691	2.13%
5	3	Direct	10,087	2.12%
6	4	Ads	993	1.91%
7	2	Ads	2,653	1.85%
8	1	Ads	8,567	1.73%
9	1	Seo	16,423	1.59%
10	2	Seo	5,078	1.52%
11	3	Seo	5,145	1.26%
12	3	Ads	2,639	1.10%

-- 11.5 年龄 × 性别
SELECT
    CASE
        WHEN age_clean < 20 THEN '20岁以下'
        WHEN age_clean BETWEEN 20 AND 29 THEN '20-29岁'
        WHEN age_clean BETWEEN 30 AND 39 THEN '30-39岁'
        WHEN age_clean BETWEEN 40 AND 49 THEN '40-49岁'
        WHEN age_clean >= 50 THEN '50岁及以上'
        ELSE '未知年龄'
    END AS 年龄段,
    sex_clean AS 性别,
    COUNT(*) AS 用户数,
    CONCAT(
        ROUND(
            SUM(CASE WHEN confirmation_page > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
            2
        ),'%'
    ) AS 确认转化率
FROM `实战练习项目`.`user_behavior_clean`
GROUP BY 年龄段, sex_clean
ORDER BY 确认转化率 DESC;
#	年龄段	性别	用户数	确认转化率
1	20岁以下	女性	4,235	5.55%
2	20岁以下	未知性别	57	5.26%
3	20-29岁	女性	25,208	4.13%
4	20-29岁	未知性别	316	2.22%
5	30-39岁	女性	23,215	2.19%
6	20岁以下	男性	3,121	2.18%
7	20-29岁	男性	16,147	1.88%
8	30-39岁	未知性别	295	1.69%
9	30-39岁	男性	13,716	1.29%
10	40-49岁	女性	6,999	0.66%
11	40-49岁	男性	4,987	0.22%
12	50岁及以上	女性	895	0.00%
13	40-49岁	未知性别	89	0.00%
14	50岁及以上	未知性别	16	0.00%
15	50岁及以上	男性	702	0.00%
16	未知年龄	女性	2	0.00%
