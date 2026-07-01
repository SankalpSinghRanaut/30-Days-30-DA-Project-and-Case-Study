create database esales;
use esales;



CREATE TABLE retail_sales (
  Invoice VARCHAR(20),
  StockCode VARCHAR(20),
  `Description` VARCHAR(255),
  Quantity INT,
  InvoiceDate DATETIME,
  Price DECIMAL(10,2),
  CustomerID VARCHAR(20),
  Country VARCHAR(100)
);

SET GLOBAL local_infile = 1;
SHOW GLOBAL VARIABLES LIKE 'local_infile';

LOAD DATA LOCAL INFILE 'C:/mysql_data/retail_sales.csv'
INTO TABLE retail_sales
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Invoice, StockCode, `Description`, Quantity,
 @InvoiceDate, Price, CustomerID, Country)
SET InvoiceDate = STR_TO_DATE(@InvoiceDate, '%m/%d/%Y %H:%i');


-- Check total rows loaded
SELECT COUNT(*) FROM retail_sales;

-- Check data looks right
SELECT * FROM retail_sales LIMIT 5;

-- Check date column parsed correctly
SELECT MIN(InvoiceDate), MAX(InvoiceDate) FROM retail_sales;


-- Who are the top 10 customers by total spend?
select CustomerID,
round(sum(Quantity*Price), 2) As total_spend
from retail_sales
where CustomerID is not null and CustomerID != ' '
group by CustomerID
order by  total_spend desc
limit 10;


-- What % of revenue comes from top 20% customers (Pareto)
WITH customer_revenue AS (
  SELECT 
    CustomerID, 
    SUM(Quantity * Price) AS revenue
  FROM retail_sales
  WHERE CustomerID IS NOT NULL
  GROUP BY CustomerID
),
ranked AS (
  SELECT 
    CustomerID,
    revenue,
    NTILE(5) OVER (ORDER BY revenue DESC) AS quintile
  FROM customer_revenue
)
SELECT 
  ROUND(
    SUM(CASE WHEN quintile = 1 THEN revenue ELSE 0 END) * 100.0 
    / SUM(revenue), 2
  ) AS pct_revenue_from_top20_customers
FROM ranked;


-- What are the top 5 best-selling products by quantity and by revenue?
select StockCode,
`Description`,
round(sum(Quantity*Price), 2) as Total_Revenue,
sum(Quantity) as Total_Quantity
from retail_sales
where Quantity > 0 and Price > 0
group by StockCode, `Description`
order by Total_Revenue desc
limit 5;

--  Which month had the highest sales, and what likely drove it?
select date_format(InvoiceDate,'%y-%m') as Order_Month,
round(sum(Quantity*Price), 2) As Monthly_Revenue
from retail_sales
Group by date_format(InvoiceDate, '%y-%m') 
Order By Monthly_Revenue asc;

--  What are the top 10 Country/Region by Total Orders and Revenue

SELECT 
  Country,
  COUNT(DISTINCT Invoice) AS Total_Orders,
  ROUND(Sum(Quantity*Price), 2) AS Total_Revenue
FROM retail_sales
GROUP BY Country
ORDER BY Total_Revenue DESC
LIMIT 10;

--  Products frequently bought 
SELECT 
  StockCode AS Product,
  `Description` AS Product_Name,  
 COUNT(*) AS Times_Bought
FROM retail_sales
GROUP BY StockCode, `Description`
ORDER BY Times_Bought DESC
LIMIT 10;