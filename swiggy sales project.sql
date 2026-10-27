SELECT * FROM swiggy_data
--Data validation & Cleaning
---Null check
SELECT
    SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS null_state,
    SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) AS null_order_date,
    SUM(CASE WHEN Restaurant_Name IS NULL THEN 1 ELSE 0 END) AS null_restaurant,
    SUM(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) AS null_location,
    SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN Dish_Name IS NULL THEN 1 ELSE 0 END) AS null_dish,
    SUM(CASE WHEN Price_INR IS NULL THEN 1 ELSE 0 END) AS null_price,
    SUM(CASE WHEN Rating IS NULL THEN 1 ELSE 0 END) AS null_rating,
    SUM(CASE WHEN Rating_Count IS NULL THEN 1 ELSE 0 END) AS null_rating_count
FROM swiggy_data;
--Blank or empty strings
SELECT *
FROM swiggy_data
WHERE
State='' OR City='' OR Restaurant_Name='' OR Location='' OR Category='' OR Dish_Name=''

--Duplicate Detection
SELECT
State,City,Order_date,restaurant_name,location,category,
dish_name,price_INR,rating,rating_count,count(*) as CNT
FROM swiggy_data
GROUP BY
State,City,order_date,restaurant_name,location,category,
dish_name,price_INR,rating,rating_count
Having count(*)>1

--Delete Duplication
WITH CTE AS (
SELECT *, ROW_NUMBER() Over(
    PARTITION BY State,City,order_date,restaurant_name,location,category,
    dish_name,price_INR,rating,rating_count
ORDER BY (SELECT NULL)
) AS rn
FROM Swiggy_data
)
DELETE FROM CTE WHERE rn>1

---CREATING SCHEMA
---DIMENSION TABLES
---DATA TABLE
CREATE TABLE dim_date (
date_id INT IDENTITY(1,1) PRIMARY KEY,
Full_Date DATE,
Year INT,
Month INT,
Month_Name varchar(20),
Quarter INT,
Day INT,
Week INT
)

--dim_location

CREATE TABLE dim_location (
location_id INT IDENTITY(1,1) PRIMARY KEY,
State VARCHAR(100),
City VARCHAR(100),
Location VARCHAR(200)
);

--dim_category

CREATE TABLE dim_category (
category_id INT IDENTITY (1,1) PRIMARY KEY,
Category VARCHAR(200)
);

---dim restaurant
CREATE TABLE dim_restaurant (
restaurant_id INT IDENTITY (1,1) PRIMARY KEY,
Restaurant_Name VARCHAR(200)
);

--dim_dish
CREATE TABLE dim_dish (
dish_id INT IDENTITY (1,1) PRIMARY KEY,
Dish_Name VARCHAR(200)
)

SELECT * FROM swiggy_data 

-FACT TABLE
CREATE TABLE fact_swiggy_order (
order_id INT IDENTITY(1,1) PRIMARY KEY,
date_id INT,
Price_INR DECIMAL (10,2),
Rating DECIMAL(4,2),
Rating_Count INT,
location_id INT,
restaurant_id INT,
category_id INT,
dish_id INT,
FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
FOREIGN KEY (location_id) REFERENCES dim_location (location_id),
FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant (restaurant_id),
FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
FOREIGN KEY (dish_id) REFERENCES dim_dish(dish_id)
);
Select * from fact_swiggy_order

--INSERT DATA IN TABLES
--dim_date

INSERT INTO dim_date (Full_Date, Year, Month, Month_Name, Quarter, Day, Week)
SELECT DISTINCT
Order_Date,
YEAR (Order_Date),
MONTH (Order_Date),
DATENAME (MONTH, Order_Date),
DATEPART (QUARTER, Order_Date),
DAY (Order_Date),
DATEPART(WEEK, Order_Date) I
FROM swiggy_data
WHERE Order_Date IS NOT NULL;

SELECT * FROM dim_date

--dim_location
INSERT INTO dim_location (State, City, Location)
SELECT DISTINCT
State,
City,
Location
FROM swiggy_data;
SELECT * FROM dim_location

INSERT INTO dim_restaurant (Restaurant_Name)
SELECT DISTINCT
     Restaurant_Name
FROM swiggy_data;
SELECT * FROM dim_restaurant

--dim_category
INSERT INTO dim_category (Category)
SELECT DISTINCT
Category
FROM swiggy_data;
SELECT * FROM dim_category

--dim_dish
INSERT INTO dim_dish (Dish_Name)
SELECT DISTINCT
Dish_Name
FROM swiggy_data;
SELECT * FROM dim_dish

--fact_table
INSERT INTO fact_swiggy_order
(
date_id,
Price_INR,
Rating,
Rating_Count,
location_id,
restaurant_id,
category_id,
dish_id
)
SELECT
dd.date_id,
s.Price_INR,
s. Rating,
s. Rating_Count,
dl.location_id,
dr.restaurant_id,
dc.category_id,
dsh.dish_id
FROM swiggy_data s
JOIN dim_date dd
ON dd. Full_Date = s. Order_Date
JOIN dim_location dl
ON dl.State = s. State
AND dl.City = s.City
AND dl. Location = s. Location
JOIN dim_restaurant dr
ON dr. Restaurant_Name = s. Restaurant_Name
JOIN dim_category dc
ON dc. Category = s. Category
JOIN dim_dish dsh
ON dsh. Dish_Name = s. Dish_Name;

SELECT * FROM fact_swiggy_order


SELECT * FROM fact_swiggy_order f

JOIN dim_date d ON f.date_id = d.date_id
JOIN dim_location l ON f.location_id = l.location_id
JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
JOIN dim_category c ON f.category_id = c.category_id
JOIN dim_dish di ON f.dish_id= di.dish_id;

---KPI
----total orders
SELECT COUNT(*) AS Total_Orders
From fact_swiggy_order

---revenue
SELECT
FORMAT(SUM(CONVERT(FLOAT,price_INR))/1000000,'N2')+'INR MILLION'
As Total_Revenue 
FROM  fact_swiggy_order

----Average  DISH price
SELECT
FORMAT(AVG(CONVERT(FLOAT,price_INR)),'N2')+'INR'
As Total_Revenue 
FROM  fact_swiggy_order

--Average rating
SELECT 
AVG(Rating) As Avg_Rating
FROM  fact_swiggy_order
--Monthly Order Trends

SELECT
d.year,
d.month,
d.month_name,
count(*) AS Total_Orders
FROM fact_swiggy_order f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year,
d.month,
d.month_name

--Yearly Trend
SELECT
d.year,
count(*) AS Total_Orders
FROM fact_swiggy_order f
JOIN dim_date d ON f.date_id= d.date_id
GROUP BY d.year
ORDER BY count(*) DESC

 --Quaterly Trend
SELECT
d.year,
d.quarter,
count(*) AS Total_Orders
FROM fact_swiggy_order f
JOIN dim_date d ON f.date_id= d.date_id
GROUP BY d.year,
d.quarter
ORDER BY count(*) DESC

 SELECT
d.year,
d.month,
d.month_name,
SUM(price_INR) AS Total_Revenue
FROM fact_swiggy_order f
JOIN dim_date d ON f. date_id= d.date_id
GROUP BY d.year,
d.month,
d.month_name
ORDER BY SUM (price_INR) DESC

 --Orders by Day of Week (Mon-Sun)
SELECT
DATENAME (WEEKDAY, d.full_date) AS day_name,
COUNT(*) AS total_orders
FROM fact_swiggy_order f
JOIN dim_date d ON f.date_id= d.date_id
GROUP BY DATENAME (WEEKDAY, d.full_date), DATEPART (WEEKDAY, d.full_date)
ORDER BY DATEPART (WEEKDAY, d.full_date);

 --Top 10 cities by order volume
SELECT TOP 10
l.city,
SUM(f.price_INR) AS Total_Revenue FROM fact_swiggy_order f
JOIN dim_location l
ON l.location_id = f. location_id
GROUP BY l.city
ORDER BY SUM(f.price_INR) ASC

 --Revenue contribution by states

SELECT
l.state,
SUM(f.price_INR) AS Total_Revenue FROM fact_swiggy_order f
JOIN dim_location l
ON l.location_id = f. location_id
GROUP BY l.state
ORDER BY SUM(f.price_INR) DESC
--Top 10 restaurants by orders

SELECT 
r.restaurant_name,
SUM(f.price_INR) AS Total_Revenue FROM fact_swiggy_order f
JOIN dim_restaurant r
ON r.restaurant_id = f.restaurant_id
GROUP BY r.restaurant_name

ORDER BY SUM(f.price_INR) DESC

 --Most Ordered Dishes
SELECT
d.dish_name,
COUNT(*) AS order_count
FROM fact_swiggy_order f
JOIN dim_dish d ON f.dish_id= d.dish_id
GROUP BY d.dish_name
ORDER BY order_count DESC;

 --Cuisine Performance (Orders + Avg Rating)
SELECT
c.category,
COUNT(*) AS total_orders,
AVG(f.rating) AS avg_rating
FROM fact_swiggy_order f
JOIN dim_category c ON f.category_id = c.category_id
GROUP BY c.category
ORDER BY avg_rating DESC;

 --Total Orders by Price Range

SELECT
    CASE
        WHEN CONVERT(FLOAT, Price_INR) < 100 THEN 'Under 100'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 100 AND 199 THEN '100-199'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 200 AND 299 THEN '200-299'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 300 AND 499 THEN '300-499'
        ELSE '500+'
    END AS price_range,
    COUNT(*) AS total_orders
FROM fact_swiggy_order
GROUP BY
    CASE
        WHEN CONVERT(FLOAT, Price_INR) < 100 THEN 'Under 100'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 100 AND 199 THEN '100-199'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 200 AND 299 THEN '200-299'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 300 AND 499 THEN '300-499'
        ELSE '500+'
    END;

 --Rating Count Distribution (1-5)
SELECT
rating,
COUNT(*) AS rating_count
FROM fact_swiggy_order
GROUP BY rating
ORDER BY rating; 


