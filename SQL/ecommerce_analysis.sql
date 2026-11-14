create database ecommerce_db;
use ecommerce_db;

CREATE TABLE customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(150),
    city VARCHAR(50),
    region VARCHAR(30),
    signup_date DATE
);


CREATE TABLE products (
    product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    category VARCHAR(50),
    unit_price DECIMAL(10,2),
    unit_cost DECIMAL(10,2),
    supplier VARCHAR(50)
);


CREATE TABLE orders (
    order_id VARCHAR(15) PRIMARY KEY,
    customer_id VARCHAR(10),
    order_date DATE,
    order_status VARCHAR(30),
    sales_channel VARCHAR(30),

    FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id)
);


CREATE TABLE order_details (
    order_detail_id VARCHAR(15) PRIMARY KEY,
    order_id VARCHAR(15),
    product_id VARCHAR(10),
    quantity INT,
    unit_price DECIMAL(10,2),
    discount_pct DECIMAL(5,2),
    line_total DECIMAL(12,2),

    FOREIGN KEY (order_id)
    REFERENCES orders(order_id),

    FOREIGN KEY (product_id)
    REFERENCES products(product_id)
);


CREATE TABLE payments (
    payment_id VARCHAR(15) PRIMARY KEY,
    order_id VARCHAR(15) UNIQUE,
    payment_date DATE,
    payment_method VARCHAR(40),
    payment_status VARCHAR(30),
    shipping_fee DECIMAL(10,2),
    order_total DECIMAL(12,2),

    FOREIGN KEY (order_id)
    REFERENCES orders(order_id)
);


use ecommerce_db;
show tables;
desc customers;
alter table customers modify column customer_id int;
DROP TABLE order_details, orders, produts, customers;

select count(*) from payments;
select * from payments limit 10;


select count(*) as total_orders from orders;

select order_status, count(*) as total_orders from orders group by order_status;

select count(distinct customer_id) as unique_customers from orders;

select Year(order_date) as order_year, count(*) as total_orders from orders
group by Year(order_date) order by order_year;

select round(sum(line_total)) as total_revenue from order_details;

SELECT ROUND(AVG(order_revenue), 2) AS average_order_value
FROM (
    SELECT order_id, SUM(line_total) AS order_revenue
    FROM order_details
    GROUP BY order_id
) AS order_totals;

select order_id, round(SUM(line_total),2) as order_revenue from order_details
group by order_id order by order_revenue desc limit 1;

select order_id, round(SUM(line_total),2) as order_revenue from order_details
group by order_id order by order_revenue asc limit 1;

select month(order_date) as Month_Number, monthname(order_date) as Month_Name,
count(*) as total_orders from orders group by month(order_date), 
monthname(order_date) order by Month_Number;

select year(o.order_date) as order_year, month(o.order_date) as month_number,
monthname(o.order_date) as month_name, round(sum(od.line_total)) as monthly_revenue
from orders o join order_details od ON o.order_id = od.order_id
group by year(o.order_date), month(o.order_date), monthname(o.order_date)
order by order_year, month_number;

SELECT DAYNAME(order_date) AS day_name, COUNT(*) AS total_orders
FROM orders GROUP BY DAYOFWEEK(order_date), DAYNAME(order_date)
ORDER BY total_orders DESC;

select year(o.order_date) as order_year, round(sum(od.line_total), 2) 
as yearly_revenue from orders o JOIN order_details od ON o.order_id = od.order_id 
group by year(o.order_date) order by order_year;

WITH yearly_revenue AS (
    SELECT YEAR(o.order_date) AS order_year, SUM(od.line_total) AS revenue
    FROM orders o JOIN order_details od ON o.order_id = od.order_id
    GROUP BY YEAR(o.order_date)
)
SELECT order_year,
       ROUND(revenue, 2) AS revenue,
       ROUND(
           (revenue - LAG(revenue) OVER (ORDER BY order_year))
           / NULLIF(LAG(revenue) OVER (ORDER BY order_year), 0)
           * 100, 2
       ) AS yoy_growth_pct
FROM yearly_revenue ORDER BY order_year;

SELECT MONTHNAME(o.order_date) AS month_name, ROUND(SUM(od.line_total), 2) 
AS total_revenue FROM orders o JOIN order_details od ON o.order_id = od.order_id
GROUP BY MONTH(o.order_date), MONTHNAME(o.order_date) ORDER BY total_revenue DESC
LIMIT 1;

SELECT ROUND(AVG(monthly_orders), 2) AS average_orders_per_month
FROM (
    SELECT DATE_FORMAT(order_date, '%Y-%m') AS order_month, 
    COUNT(*) AS monthly_orders FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
) AS monthly_summary;

SELECT p.product_id, p.product_name, ROUND(SUM(od.line_total), 2) AS total_revenue
FROM products p JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.product_id, p.product_name ORDER BY total_revenue DESC LIMIT 10;

SELECT p.product_id, p.product_name, SUM(od.quantity) AS units_sold
FROM products p JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.product_id, p.product_name ORDER BY units_sold DESC LIMIT 10;

SELECT p.category, ROUND(SUM(od.line_total), 2) AS category_revenue
FROM products p JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.category ORDER BY category_revenue DESC;

SELECT p.category, SUM(od.quantity) AS units_sold
FROM products p JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.category ORDER BY units_sold DESC LIMIT 1;

SELECT p.product_id, p.product_name, ROUND(AVG(od.unit_price), 2) 
AS average_selling_price FROM products p JOIN order_details od
ON p.product_id = od.product_id GROUP BY p.product_id, p.product_name
ORDER BY average_selling_price DESC;

SELECT p.product_id, p.product_name FROM products p LEFT JOIN order_details od
ON p.product_id = od.product_id WHERE od.product_id IS NULL;

SELECT p.category, ROUND(SUM((od.unit_price * (1 - od.discount_pct) - 
p.unit_cost)* od.quantity ), 2) AS estimated_gross_profit
FROM products p JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.category ORDER BY estimated_gross_profit DESC;

SELECT p.product_id, p.product_name,
       ROUND(SUM(od.unit_price * od.quantity * od.discount_pct), 2) AS total_discount_amount
FROM products p JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.product_id, p.product_name ORDER BY total_discount_amount DESC LIMIT 10;

SELECT c.customer_id, c.customer_name, ROUND(SUM(od.line_total), 2) AS total_revenue
FROM customers c JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id 
GROUP BY c.customer_id, c.customer_name ORDER BY total_revenue DESC LIMIT 10;

SELECT c.customer_id, c.customer_name, COUNT(DISTINCT o.order_id) AS total_orders
FROM customers c JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name ORDER BY total_orders DESC LIMIT 10;

SELECT ROUND(AVG(customer_revenue), 2) AS average_revenue_per_customer
FROM (
    SELECT o.customer_id, SUM(od.line_total) AS customer_revenue
    FROM orders o JOIN order_details od ON o.order_id = od.order_id
    GROUP BY o.customer_id) AS customer_totals;
    
SELECT region, COUNT(*) AS total_customers FROM customers GROUP BY region
ORDER BY total_customers DESC;

SELECT c.city, ROUND(SUM(od.line_total), 2) AS total_revenue FROM customers c
JOIN orders o ON c.customer_id = o.customer_id JOIN order_details od
ON o.order_id = od.order_id GROUP BY c.city ORDER BY total_revenue DESC LIMIT 10;

SELECT COUNT(*) AS repeat_customers FROM (SELECT customer_id FROM orders
GROUP BY customer_id HAVING COUNT(*) > 1) AS repeat_customer_list;

SELECT payment_method, COUNT(*) AS total_payments FROM payments 
GROUP BY payment_method ORDER BY total_payments DESC;

SELECT payment_status, ROUND(SUM(order_total), 2) AS total_payment_amount
FROM payments GROUP BY payment_status ORDER BY total_payment_amount DESC;

SELECT o.sales_channel, ROUND(SUM(od.line_total), 2) AS total_revenue
FROM orders o JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.sales_channel ORDER BY total_revenue DESC;

SELECT sales_channel, COUNT(*) AS total_orders FROM orders
GROUP BY sales_channel ORDER BY total_orders DESC;

SELECT payment_method, ROUND(SUM(shipping_fee), 2) AS total_shipping_fee
FROM payments GROUP BY payment_method ORDER BY total_shipping_fee DESC;

SELECT ROUND(AVG(shipping_fee), 2) AS average_shipping_fee
FROM payments;

use ecommerce_db;
select count(*) from order_details;