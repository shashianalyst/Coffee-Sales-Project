-- Monday Coffie schema
use coffie_sales;

DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS city;

CREATE TABLE city(
city_id int primary key,
city_name VARCHAR(50),
population BIGINT,
estimated_rent float,
city_rank int);

CREATE TABLE customers(
customer_id INT PRIMARY KEY,
customer_name VARCHAR(50),
city_id int,
CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);

CREATE TABLE products(
product_id INT PRIMARY KEY,
product_name VARCHAR(50),
price float
);

CREATE TABLE sales(
sale_id INT PRIMARY KEY,
sale_date DATE,
product_id int,
customer_id int,
total float,
rating int,
constraint fk_products foreign key (product_id) references products(product_id),
constraint fk_customers foreign key (customer_id) references customers(customer_id)
);

SELECT * FROM sales;
SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM city;

-- 1. How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
	city_name,
	ROUND(
	(population * 0.25)/1000000, 
	2) as coffee_consumers_in_millions,
	city_rank
FROM city
ORDER BY 2 DESC;

-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT 
	SUM(total) as total_revenue
FROM sales
WHERE 
	EXTRACT(YEAR FROM sale_date)  = 2023
	AND
	EXTRACT(quarter FROM sale_date) = 4;
    
SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date)  = 2023
	AND
	EXTRACT(quarter FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC;

-- Sales Count for Each Product
-- How many units of each coffee product have been sold?
select p.product_name, count(s.sale_id) as total_orders
from products as p join sales as s
on s.product_id = p.product_id
group by 1
order by 2 desc;

-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?
-- city abd total sale
-- no cx in each these city
select ci.city_name, sum(s.total) total_revenue,
count(DISTINCT s.customer_id) as total_cust
from sales as s join customers as c
on s.customer_id = c.customer_id
join city as ci
on c.city_id = ci.city_id
group by ci.city_name
order by total_revenue desc;

-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

select ci.city_name, ci.population,
count(DISTINCT c.customer_id)as total_cust,
(ci.population*0.25) as estmtd_coffie_consumers
from city as ci left join customers as c
on ci.city_id = c.city_id
group by 1, 2
order by 3 desc;


-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

WITH ranked_products AS (
    SELECT 
        ci.city_name,
        p.product_name,
        SUM(s.total) AS total_sales_volume,
        DENSE_RANK() OVER (
            PARTITION BY ci.city_name 
            ORDER BY SUM(s.total) DESC
        ) AS product_rank
    FROM sales AS s
    JOIN products AS p ON s.product_id = p.product_id
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS ci ON c.city_id = ci.city_id
    GROUP BY 1, 2
)
SELECT 
    city_name,
    product_name,
    total_sales_volume,
    product_rank
FROM ranked_products
WHERE product_rank <= 3
ORDER BY city_name, product_rank;

-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

select ci.city_name, count(DISTINCT c.customer_id) as Coffie_customer
from customers as c join sales as s
on c.customer_id = s.customer_id
join products as p on p.product_id=s.product_id
join city as ci on ci.city_id=c.city_id
where p.product_name like '%coffee%'
group by 1
order by 2 desc;

-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

SELECT 
    ci.city_name,
    -- 1. Average Sale per Customer
    ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_per_customer,
    
    -- 2. Average Rent per Customer (Total City Rent / Unique Customers)
    Round(ci.estimated_rent / COUNT(DISTINCT s.customer_id), 2)AS avg_rent_per_customer
FROM sales AS s
JOIN customers AS c ON s.customer_id = c.customer_id
JOIN city AS ci ON c.city_id = ci.city_id
GROUP BY ci.city_name, ci.estimated_rent
ORDER BY avg_sale_per_customer DESC;
