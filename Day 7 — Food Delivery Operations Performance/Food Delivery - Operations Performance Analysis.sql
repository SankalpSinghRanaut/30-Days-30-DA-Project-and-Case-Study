Create Database delivery;
Use delivery;

CREATE TABLE food_delivery (
    ID VARCHAR(10),
    Delivery_person_ID VARCHAR(20),
    Delivery_person_Age INT,
    Delivery_person_Ratings DECIMAL(3,1),
    Order_Date DATE,
    Time_Orderd TIME,
    Time_Order_picked TIME,
    Weatherconditions VARCHAR(20),
    Road_traffic_density VARCHAR(20),
    Vehicle_condition INT,
    Type_of_order VARCHAR(20),
    Type_of_vehicle VARCHAR(30),
    multiple_deliveries INT,
    Festival VARCHAR(5),
    City VARCHAR(20),
    Delivery_Time_Min INT,
    Time_of_Day VARCHAR(20),
    Is_Late VARCHAR(10),
    Delivery_Speed_Band VARCHAR(30)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/food delivery.csv'
INTO TABLE food_delivery
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
ID,
Delivery_person_ID,
Delivery_person_Age,
Delivery_person_Ratings,

@Restaurant_latitude,
@Restaurant_longitude,
@Delivery_location_latitude,
@Delivery_location_longitude,

@Order_Date,
@Time_Orderd,
@Time_Order_picked,

Weatherconditions,
Road_traffic_density,
Vehicle_condition,
Type_of_order,
Type_of_vehicle,
@multiple_deliveries,
Festival,
City,
Delivery_Time_Min,
Time_of_Day,
Is_Late,
Delivery_Speed_Band
)
SET
Order_Date = STR_TO_DATE(REPLACE(@Order_Date,'-','/'), '%d/%m/%Y'),
Time_Orderd = NULLIF(TRIM(@Time_Orderd), 'NaN'),
Time_Order_picked = NULLIF(TRIM(@Time_Order_picked), 'NaN'),
multiple_deliveries = NULLIF(TRIM(@multiple_deliveries), 'NaN');

-- Average delivery time by city

SELECT
  City,
  COUNT(*)                                        AS total_deliveries,
  ROUND(AVG(Delivery_Time_Min), 2)                AS avg_delivery_time_min,
  ROUND(MIN(Delivery_Time_Min), 2)                AS fastest_delivery,
  ROUND(MAX(Delivery_Time_Min), 2)                AS slowest_delivery,
  SUM(CASE WHEN Delivery_Time_Min > 40
      THEN 1 ELSE 0 END)                          AS late_deliveries,
  ROUND(SUM(CASE WHEN Delivery_Time_Min > 40
      THEN 1 ELSE 0 END) * 100.0
      / COUNT(*), 2)                              AS late_delivery_rate_pct
FROM food_delivery
WHERE City IS NOT NULL AND City != ''
GROUP BY City
ORDER BY avg_delivery_time_min DESC;


-- Which vehicle type performs best for delivery speed?

SELECT
  Type_of_vehicle,
  COUNT(*)                                        AS total_deliveries,
  ROUND(AVG(Delivery_Time_Min), 2)                AS avg_delivery_time_min,
  ROUND(AVG(Delivery_person_Ratings), 2)          AS avg_rider_rating,
  SUM(CASE WHEN Delivery_Time_Min > 40
      THEN 1 ELSE 0 END)                          AS late_deliveries,
  ROUND(SUM(CASE WHEN Delivery_Time_Min > 40
      THEN 1 ELSE 0 END) * 100.0
      / COUNT(*), 2)                              AS late_rate_pct
FROM food_delivery
GROUP BY Type_of_vehicle
ORDER BY avg_delivery_time_min ASC;


-- Does traffic density significantly impact delivery time?

SELECT
  Road_traffic_density,
  COUNT(*)                                        AS total_deliveries,
  ROUND(AVG(Delivery_Time_Min), 2)                AS avg_delivery_time_min,
  ROUND(MIN(Delivery_Time_Min), 2)                AS min_delivery_time,
  ROUND(MAX(Delivery_Time_Min), 2)                AS max_delivery_time,
  ROUND(SUM(CASE WHEN Delivery_Time_Min > 40
      THEN 1 ELSE 0 END) * 100.0
      / COUNT(*), 2)                              AS late_rate_pct
FROM food_delivery
WHERE Road_traffic_density IS NOT NULL
  AND Road_traffic_density != ''
GROUP BY Road_traffic_density
ORDER BY avg_delivery_time_min DESC;


--  Is there a peak hour/time-of-day where delays spike?

SELECT
  CASE
    WHEN HOUR(Time_Orderd) BETWEEN 6  AND 11 THEN '1. Morning (6-11am)'
    WHEN HOUR(Time_Orderd) BETWEEN 12 AND 16 THEN '2. Afternoon (12-4pm)'
    WHEN HOUR(Time_Orderd) BETWEEN 17 AND 20 THEN '3. Evening (5-8pm)'
    ELSE                                          '4. Night (9pm-5am)'
  END                                             AS time_of_day,
  COUNT(*)                                        AS total_deliveries,
  ROUND(AVG(Delivery_Time_Min), 2)                AS avg_delivery_time_min,
  ROUND(SUM(CASE WHEN Delivery_Time_Min > 40
      THEN 1 ELSE 0 END) * 100.0
      / COUNT(*), 2)                              AS late_rate_pct,
  ROUND(AVG(Delivery_person_Ratings), 2)          AS avg_rider_rating
FROM food_delivery
WHERE Time_Orderd IS NOT NULL
GROUP BY  (CASE
    WHEN HOUR(Time_Orderd) BETWEEN 6  AND 11 THEN '1. Morning (6-11am)'
    WHEN HOUR(Time_Orderd) BETWEEN 12 AND 16 THEN '2. Afternoon (12-4pm)'
    WHEN HOUR(Time_Orderd) BETWEEN 17 AND 20 THEN '3. Evening (5-8pm)'
    ELSE                                          '4. Night (9pm-5am)'
  END       )
ORDER BY time_of_day;

--  What % of deliveries breach the 40-minute SLA?


SELECT
  Weatherconditions                               AS weather,
  COUNT(*)                                        AS total_deliveries,
  ROUND(AVG(Delivery_Time_Min), 2)                AS avg_delivery_time_min,
  SUM(CASE WHEN Delivery_Time_Min > 40
      THEN 1 ELSE 0 END)                          AS sla_breaches,
  ROUND(SUM(CASE WHEN Delivery_Time_Min > 40
      THEN 1 ELSE 0 END) * 100.0
      / COUNT(*), 2)                              AS sla_breach_rate_pct
FROM food_delivery
WHERE Weatherconditions IS NOT NULL
  AND Weatherconditions != ''
GROUP BY Weatherconditions
ORDER BY sla_breach_rate_pct DESC;


-- Bonus: Bottom 10 performers
-- Top 10
SELECT
  Delivery_person_ID,
  COUNT(*)                                        AS total_deliveries,
  ROUND(AVG(Delivery_Time_Min), 2)                AS avg_delivery_time_min,
  ROUND(AVG(Delivery_person_Ratings), 2)          AS avg_rating,
  ROUND(SUM(CASE WHEN Delivery_Time_Min > 40
      THEN 1 ELSE 0 END) * 100.0
      / COUNT(*), 2)                              AS late_rate_pct
FROM food_delivery
GROUP BY Delivery_person_ID
HAVING COUNT(*) >= 30
ORDER BY avg_delivery_time_min DESC
LIMIT 10;

-- Bottom 10
SELECT
  Delivery_person_ID,
  COUNT(*)                                        AS total_deliveries,
  ROUND(AVG(Delivery_Time_Min), 2)                AS avg_delivery_time_min,
  ROUND(AVG(Delivery_person_Ratings), 2)          AS avg_rating,
  ROUND(SUM(CASE WHEN Delivery_Time_Min > 40
      THEN 1 ELSE 0 END) * 100.0
      / COUNT(*), 2)                              AS late_rate_pct
FROM food_delivery
GROUP BY Delivery_person_ID
HAVING COUNT(*) >= 30
ORDER BY avg_delivery_time_min ASC
LIMIT 10;