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
