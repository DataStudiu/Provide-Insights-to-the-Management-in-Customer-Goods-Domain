SELECT * FROM dim_customer;

-- QUESTION NO  : 1
-- Provide the list of markets in which customer "Atliq Exclusive" operates its
-- business in the APAC region.

select
distinct market , customer  , region 
from dim_customer
where 
customer = "Atliq Exclusive" and region = "APAC" ;

-- Question 2 :
  -- What is the percentage of unique product increase in 2021 vs. 2020? The
-- final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg 


WITH unique_2020 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_product_2020
    FROM fact_gross_price
    WHERE fiscal_year = 2020
),
unique_2021 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_product_2021
    FROM fact_gross_price
    WHERE fiscal_year = 2021
)
SELECT
    unique_2020.unique_product_2020,
    unique_2021.unique_product_2021,
    ((unique_2021.unique_product_2021 / unique_2020.unique_product_2020) - 1)*100  AS percentage_change
FROM unique_2020, unique_2021;

-- Question no 3 :
--  Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains
-- 2 fields,
-- segment
-- product_count

select 
segment ,
 count( distinct product ) as product_counts
 from dim_product
 group by segment 
 order by product_counts desc ;
 
 
-- Question 4 : 
-- Follow-up: Which segment had the most increase in unique products in
-- 2021 vs 2020? The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference
 
 with segment_count_2020 as (
select 
 segment,
 count(distinct fact_gross_price.product_code) as product_count_2020
 from fact_gross_price 
 inner join dim_product on
 fact_gross_price.product_code = dim_product.product_code
 where fiscal_year = 2020 
 group by segment
 order by product_count_2020 desc
) ,
segment_count_2021 as (
select 
 segment ,
 count(distinct fact_gross_price.product_code) as product_count_2021
 from fact_gross_price 
 inner join dim_product on
 fact_gross_price.product_code = dim_product.product_code
 where fiscal_year = 2021 
 group by segment
 order by product_count_2021 desc
)
select
 sc_2020.segment,
 product_count_2020 ,
 product_count_2021 ,
 (product_count_2020 - product_count_2021) as difference
 from segment_count_2020 sc_2020
 inner join   segment_count_2021 sc_2021 on sc_2020.segment = sc_2021.segment
 
-- Question no 5  :
--  Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost

with high_cost_product as
(
select
 fact_manufacturing_cost.product_code,
 product,
 sum(manufacturing_cost) as T_manufacturing_cost
 from fact_manufacturing_cost
 inner join dim_product on 
 fact_manufacturing_cost.product_code = dim_product.product_code
 group by product_code , product
 order by t_manufacturing_cost desc 
 limit 1
 ),
 low_cost_product as (
 select
 fact_manufacturing_cost.product_code,
 product,
 sum(manufacturing_cost) as T_manufacturing_cost
 from fact_manufacturing_cost
 inner join dim_product on 
 fact_manufacturing_cost.product_code = dim_product.product_code
 group by product_code , product
 order by t_manufacturing_cost asc 
 limit 1
 )
 select * from high_cost_product 
 union
 select * from low_cost_product 

-- Question no 6 :
--  Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage

select 
 fact_pre_invoice_deductions.customer_code,
 customer,
 avg(pre_invoice_discount_pct) as high_avg_discount_pct
 from fact_pre_invoice_deductions 
 join dim_customer on 
 fact_pre_invoice_deductions.customer_code =  dim_customer.customer_code
 where fiscal_year = 2021
 and
 market = 'india'
 group by customer , customer_code
 order by high_avg_discount_pct desc
 limit 5 ;

-- Question no : 7
-- Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount

select
 month(date) as month ,
 year(date) as year  ,
 sum(sold_quantity * gross_price) as  Gross_sales_Amount
 from fact_sales_monthly 
 inner join fact_gross_price on fact_sales_monthly.product_code = fact_gross_price.product_code
 inner join dim_customer on fact_sales_monthly.customer_code =  dim_customer.customer_code
 where customer = "Atliq Exclusive" 
 group by month,year
 order by  year asc
 ;


-- Question no 8 :
 -- In which quarter of 2020, got the maximum total_sold_quantity? The final
-- output contains these fields sorted by the total_sold_quantity,
-- Quarter
-- total_sold_quantity

select 
extract(quarter from date) as Quarter,
sum(sold_quantity) as total_sales_quantity
from fact_sales_monthly
group by  extract(quarter from date) 
order by total_sales_quantity desc
limit 1 ;


-- Question no : 9
-- Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
-- channel
-- gross_sales_mln
-- percentage

WITH sales AS(
SELECT channel,
       round(sum(G.gross_price * M.sold_quantity),2) AS gross_sales_mln
FROM dim_customer AS C
INNER JOIN fact_sales_monthly AS M
ON C.customer_code = M.customer_code
INNER JOIN fact_gross_price AS G
ON G.product_code = M.product_code
WHERE M.fiscal_year = 2021
GROUP BY channel
ORDER BY gross_sales_mln desc)
SELECT channel,
       gross_sales_mln,
       round(((S.gross_sales_mln/t.total )*100),2) AS Percentage
FROM sales AS S
CROSS JOIN (SELECT sum(gross_sales_mln) AS total FROM sales) t;

-- Question no :10
-- Get the Top 3 products in each division that have a high
-- total_sold_quantity in the fiscal_year 2021? The final output contains these
-- fields,
-- division
-- product_code
-- codebasics.io
-- product
-- total_sold_quantity
-- rank_order

with Results as (
select division ,
 dim_product.product_code ,
 product ,
 sum(sold_quantity) as total_sold_quantity ,
 row_number() over (partition by division order by  sum(sold_quantity) desc) as rank_order
 from dim_product 
 inner join  fact_sales_monthly on 
 dim_product.product_code = fact_sales_monthly.product_code
 where fiscal_year  = 2021 
 group by division, dim_product.product_code ,product
 )
 select * from results where rank_order <=3


