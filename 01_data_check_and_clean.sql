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

-- 校验清洗之后的表分布
SELECT sex_clean,COUNT(*) FROM `实战练习项目`.`user_behavior_clean` GROUP BY sex_clean;
SELECT device_clean,COUNT(*) FROM `实战练习项目`.`user_behavior_clean` GROUP BY device_clean;
SELECT os_clean,COUNT(*) FROM `实战练习项目`.`user_behavior_clean` GROUP BY os_clean;
SELECT source_clean,COUNT(*) FROM `实战练习项目`.`user_behavior_clean` GROUP BY source_clean;
