#  Business Request - 1: City-Level Fare and Trip Summary Report
SELECT 
    c.city_name,
    COUNT(ft.trip_id) AS total_trips,
    ROUND(AVG(ft.fare_amount), 2) AS avg_fare_per_trip,
    ROUND(AVG(ft.fare_amount / NULLIF(ft.distance_travelled_km, 0)), 2) AS avg_fare_per_km,
    ROUND((COUNT(ft.trip_id) * 100.0 / (SELECT COUNT(*) FROM fact_trips)), 2) AS `%_contribution_to_total_trips`
FROM 
    fact_trips ft
JOIN 
    dim_city c
ON 
    ft.city_id = c.city_id
GROUP BY 
    c.city_name
ORDER BY 
    total_trips DESC;
    
# Business Request - 2: Monthly City_Level Trip Target Performance Report
SELECT
	dc.city_name,
    dd.month_name,
    COUNT(ft.trip_id) AS actual_trips,
    tt.total_target_trips AS target_trips,
	CASE
		WHEN  COUNT(ft.trip_id) > tt.total_target_trips THEN 'Above Target'
		ELSE 'Below Target'
	END AS performace_status,
    ROUND((COUNT(ft.trip_id) - tt.total_target_trips)/tt.total_target_trips*100,2) AS '%_difference'
FROM
	trips_db.fact_trips ft
JOIN
	trips_db.dim_city dc ON ft.city_id = dc.city_id
JOIN
	trips_db.dim_date dd ON ft.date = dd.date
JOIN 
	targets_db.monthly_target_trips tt ON ft.city_id = tt.city_id AND dd.start_of_month = tt.month
GROUP BY
	dc.city_name, dd.month_name, tt.total_target_trips, dd.start_of_month
ORDER BY
	dc.city_name,(dd.start_of_month);

#Business Request - 3: City-Level Repeat Passenger Trip Frequency Report
SELECT 
    dc.city_name, 
    ROUND(SUM(CASE WHEN rtd.trip_count = '2-Trips' THEN rtd.repeat_passenger_count END) / SUM(ps.total_passengers) * 100 , 2) AS '2- Trips',
    ROUND(SUM(CASE WHEN rtd.trip_count = '3-Trips' THEN rtd.repeat_passenger_count END) / SUM(ps.total_passengers) * 100 , 2) AS '3- Trips',
    ROUND(SUM(CASE WHEN rtd.trip_count = '4-Trips' THEN rtd.repeat_passenger_count END) / SUM(ps.total_passengers) * 100 , 2) AS '4- Trips',
    ROUND(SUM(CASE WHEN rtd.trip_count = '5-Trips' THEN rtd.repeat_passenger_count END) / SUM(ps.total_passengers) * 100 , 2) AS '5- Trips',
    ROUND(SUM(CASE WHEN rtd.trip_count = '6-Trips' THEN rtd.repeat_passenger_count END) / SUM(ps.total_passengers) * 100 , 2) AS '6- Trips',
    ROUND(SUM(CASE WHEN rtd.trip_count = '7-Trips' THEN rtd.repeat_passenger_count END) / SUM(ps.total_passengers) * 100 , 2) AS '7- Trips',
    ROUND(SUM(CASE WHEN rtd.trip_count = '8-Trips' THEN rtd.repeat_passenger_count END) / SUM(ps.total_passengers) * 100 , 2) AS '8- Trips',
    ROUND(SUM(CASE WHEN rtd.trip_count = '9-Trips' THEN rtd.repeat_passenger_count END) / SUM(ps.total_passengers) * 100 , 2) AS '9- Trips',
    ROUND(SUM(CASE WHEN rtd.trip_count = '10-Trips' THEN rtd.repeat_passenger_count END) / SUM(ps.total_passengers) * 100 , 2) AS '10- Trips'
FROM
	dim_repeat_trip_distribution rtd
JOIN
	dim_city dc ON rtd.city_id = dc.city_id
JOIN 
	fact_passenger_summary ps ON rtd.city_id = ps.city_id
GROUP BY
	dc.city_name;


	
#Business Request 4: Identify cities with Highest and Lowest Total New Passengers
WITH RankedCities AS (
    SELECT 
        dc.city_name,
        SUM(fps.new_passengers) AS total_new_passengers,
        RANK() OVER (ORDER BY SUM(fps.new_passengers) DESC) AS rank_high,
        RANK() OVER (ORDER BY SUM(fps.new_passengers) ASC) AS rank_low
    FROM 
        dim_city dc
    JOIN 
        fact_passenger_summary fps
    ON 
        dc.city_id = fps.city_id
    GROUP BY 
        dc.city_name
),
CategorizedCities AS (
    SELECT 
        city_name,
        total_new_passengers,
        CASE
            WHEN rank_high <= 3 THEN 'Top 3'
            WHEN rank_low <= 3 THEN 'Bottom 3'
            ELSE NULL
        END AS city_category
    FROM 
        RankedCities
)
SELECT 
    city_name,
    total_new_passengers,
    city_category
FROM 
    CategorizedCities
WHERE 
    city_category IS NOT NULL
ORDER BY 
    city_category DESC, 
    total_new_passengers DESC;
    
#Business Request - 5: Identify Month with Highest Revenue for Each City

WITH MonthlyRevenue AS (
    SELECT
        dc.city_name,
        MONTHNAME(ft.date) AS month_name,
        SUM(ft.fare_amount) AS monthly_revenue
    FROM 
        fact_trips ft
    JOIN
        dim_city dc
    ON 
        ft.city_id = dc.city_id
    GROUP BY 
        dc.city_name, YEAR(ft.date), MONTHNAME(ft.date)
),
RankedRevenue AS (
    SELECT
        city_name,
        month_name,
        monthly_revenue,
        RANK() OVER(PARTITION BY city_name ORDER BY monthly_revenue DESC) AS highest_rank,
        ROUND((monthly_revenue / SUM(monthly_revenue) OVER (PARTITION BY city_name)),2) * 100 AS `%_contribution`
	FROM
        MonthlyRevenue
)
SELECT
    city_name,
    month_name AS highest_revenue_month,
    monthly_revenue AS revenue,
    `%_contribution`
FROM 
    RankedRevenue
WHERE 
    highest_rank = 1;
    
#Business Request - 6: Repeat Passenger Rate Analysis
SELECT
	dc.city_name,
    MONTHNAME(fps.month) AS month_name,
    SUM(fps.total_passengers) AS total_passengers,
    SUM(fps.repeat_passengers) AS repeat_passengers,
    (SUM(fps.repeat_passengers)/SUM(fps.total_passengers))*100 AS monthly_repeat_passenger_rate
FROM 
	fact_passenger_summary fps
JOIN 
	dim_city dc
ON
	fps.city_id = dc.city_id
GROUP BY
	dc.city_name,MONTHNAME(fps.month);
    





    


	


	



	
    

	


	
    