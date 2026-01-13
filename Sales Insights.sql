/*Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.*/
SELECT DISTINCT(market) 
FROM gdb023.dim_customer 
WHERE customer="Atliq Exclusive" AND region="APAC";

/*Create date table and respecting fical year starting from September*/
CREATE TABLE dim_date as SELECT DISTINCT(date) as date FROM gdb023.fact_sales_monthly;
ALTER TABLE dim_date ADD COLUMN fiscal_year YEAR;
UPDATE dim_date SET fiscal_year = YEAR(DATE_ADD(date, INTERVAL 4 MONTH));
SELECT * FROM dim_date;

/*What is the percentage of unique product increase in 2021 vs 2020?*/
WITH 
p_2020 AS (SELECT COUNT(DISTINCT(product_code)) AS unique_products_2020 FROM fact_sales_monthly WHERE fiscal_year=2020),
p_2021 AS (SELECT COUNT(DISTINCT(product_code)) AS unique_products_2021 FROM fact_sales_monthly WHERE fiscal_year=2021)
SELECT 
	p_2020.unique_products_2020, 
	p_2021.unique_products_2021, 
	ROUND((p_2020.unique_products_2020/p_2021.unique_products_2021)*100, 2) AS percentage_chg
FROM p_2020
CROSS JOIN p_2021;

/*Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.*/
SELECT segment, COUNT(DISTINCT(product_code)) as product_count 
FROM dim_product 
GROUP BY segment 
ORDER BY product_count DESC;

/*Which segment had the most increase in unique products in 2021 vs 2020?*/
WITH
data_2020 AS (
	SELECT segment, COUNT(DISTINCT(s.product_code)) AS product_2020 
	FROM fact_sales_monthly s 
	JOIN dim_product p 
    ON s.product_code=p.product_code 
    WHERE fiscal_year=2020 
    GROUP BY segment
    ),
data_2021 AS (
	SELECT segment, COUNT(DISTINCT(s.product_code)) AS product_2021 
    FROM fact_sales_monthly s 
    JOIN dim_product p 
    ON s.product_code=p.product_code 
    WHERE fiscal_year=2021 
    GROUP BY segment)
SELECT 
	data_2020.segment,
	product_2020, 
	product_2021,
	product_2021-product_2020  AS differenece
FROM data_2020 
JOIN data_2021
ON data_2020.segment=data_2021.segment;

/*Get the products that have the highest and lowest manufacturing costs.*/
SELECT p.product_code, p.product, m.manufacturing_cost
FROM dim_product p 
JOIN fact_manufacturing_cost m 
ON p.product_code=m.product_code
WHERE manufacturing_cost IN (
	(SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost), 
    (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
    );

/*Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.*/
SELECT pre.customer_code, c.customer, pre.pre_invoice_discount_pct
FROM fact_pre_invoice_deductions pre
JOIN dim_customer c
ON pre.customer_code=c.customer_code
WHERE fiscal_year=2021 AND market="India"
ORDER BY pre_invoice_discount_pct DESC
LIMIT 5;

/*Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. */
SELECT MONTHNAME(f.date) AS month, YEAR(f.date) AS year, SUM(f.sold_quantity*g.gross_price) AS gross_sales_amount
FROM fact_sales_monthly f
JOIN fact_gross_price g
ON f.product_code=g.product_code AND f.fiscal_year=g.fiscal_year
JOIN dim_customer c
ON f.customer_code=c.customer_code
WHERE c.customer="Atliq Exclusive"
GROUP BY f.date;

/*In which quarter of 2020, got the maximum total_sold_quantity?*/
SELECT QUARTER(DATE_ADD(date, INTERVAL 4 MONTH)) AS quarter, SUM(sold_quantity) AS total_sold_qty 
FROM fact_sales_monthly 
WHERE fiscal_year=2020 
GROUP BY quarter 
ORDER BY total_sold_qty DESC;

/*Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?*/
SELECT 
	c.channel, 
	SUM(f.sold_quantity*g.gross_price) AS gross_sales_amount,
    ROUND(SUM(f.sold_quantity*g.gross_price)*100/SUM(SUM(f.sold_quantity*g.gross_price)) OVER() ,2) AS percentage
FROM fact_sales_monthly f
JOIN fact_gross_price g
ON f.product_code=g.product_code AND f.fiscal_year=g.fiscal_year
JOIN dim_customer c
ON f.customer_code=c.customer_code
WHERE f.fiscal_year=2021
GROUP BY c.channel;

/*Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?*/
WITH data_2021 AS(
	SELECT 
		division,
		p.product_code,
		product,
		SUM(f.sold_quantity) AS total_sold_quantity
	FROM dim_product p
	JOIN fact_sales_monthly f
	ON p.product_code=f.product_code
	WHERE fiscal_year=2021
	GROUP BY p.division, p.product_code, p.product),
   ranking_2021_data as (
    SELECT 
		*,
		DENSE_RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
	FROM data_2021)
SELECT * FROM ranking_2021_data
WHERE rank_order<=3;


    
    
    
    
    
    
    
    
    
    
    
    
    
