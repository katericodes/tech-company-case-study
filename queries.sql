-- Challenge 1:
WITH monthlyrev AS(
    SELECT date_trunc('month', orderdate),productname, sum(revenue) AS rev
    FROM subscriptions
    JOIN products
    ON subscriptions.PRODUCTID = products.PRODUCTID
    WHERE orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY date_trunc('month', orderdate), productname
)
SELECT productname,
    min(rev) AS min_rev,
    max(rev) AS max_rev,
    avg(rev) AS avg_rev,
    stddev(rev) AS std_dev_rev
FROM monthlyrev
GROUP BY productname;

/*
The above query provided insight that the Expert product had a higher average monthly revenue than the Basic Product, but the Basic product had a more consistent monthly revenue (based on standard deviation).
*/

-- Challenge 2:
WITH event5stats AS(
    SELECT userid, count(userID) AS num_link_clicks
    FROM frontendeventlog
    WHERE eventid = 5
    GROUP BY UserID
)

SELECT num_link_clicks, count(num_link_clicks) AS num_users
FROM event5stats
GROUP BY  num_link_clicks;

/*
The resulting distribution revealed that half of the users return to the email to click on the link again.
*/

-- Challenge 3

WITH maximum AS(
	SELECT SubscriptionID,
        max(statusID) AS maxstatus
	FROM PaymentStatusLog
	GROUP BY SubscriptionID)
    , paymentstages AS(
        SELECT s.SubscriptionID,
            -- case expression was provided for this challenge
            CASE WHEN maxstatus = 1 THEN 'PaymentWidgetOpened'
                    WHEN maxstatus = 2 THEN 'PaymentEntered'
                    WHEN maxstatus = 3 AND currentstatus = 0 THEN 'User Error with Payment Submission'
                    WHEN maxstatus = 3 AND currentstatus != 0 THEN 'Payment Submitted'
                    WHEN maxstatus = 4 AND currentstatus = 0 THEN 'Payment Processing Error with Vendor'
                    WHEN maxstatus = 4 AND currentstatus != 0 THEN 'Payment Success'
                    WHEN maxstatus = 5 THEN 'Complete'
                    WHEN maxstatus IS NULL THEN 'User did not start payment process'
                    END AS paymentfunnelstage
        FROM Subscriptions s
        LEFT JOIN maximum m -- Not all subscriptions have a payment status
        ON s.SubscriptionID = m.SubscriptionID)

SELECT paymentfunnelstage, count(*) AS subscriptions
FROM paymentstages
GROUP BY paymentfunnelstage;

/*
The result provides insight of how users interact with the payment process and identify areas for improvement.
*/

-- Challenge 4
SELECT customerid,
    count(*) AS num_products,
    sum(numberofusers) AS total_users,
    CASE
        WHEN count(*) = 1 OR sum(numberofusers) >= 5000 THEN 1
        ELSE 0
        END AS upsell_opportunity
FROM subscriptions
group by customerid;

/*
This result identifies customers that fit the desired criteria and can be an upsell opportuntiy for the sales team.
*/

-- Challenge 5
Select userid,
    SUM(CASE WHEN log.eventid = 1 THEN 1 ELSE 0 END) AS ViewedHelpCenterPage,
    SUM(CASE WHEN log.eventid = 2 THEN 1 ELSE 0 END) AS ClickedFAQs,
    SUM(CASE WHEN log.eventid = 3 THEN 1 ELSE 0 END) AS ClickedContactSupport,
    SUM(CASE WHEN log.eventid = 4 THEN 1 ELSE 0 END) AS SubmittedTicket
FROM
	Frontendeventlog log
JOIN
	frontendeventdefinitions def
	ON log.eventid = def.eventid
WHERE
	eventtype = 'Customer Support'
GROUP BY
	userid;

/*
This result provides insight on how many times a certain user performed a specific action.
*/

-- Challenge 6
With all_subscriptions as(
	SELECT expirationdate
	FROM SubscriptionsProduct1
	WHERE active = 1 

	UNION ALL
    -- Union all can be used since the products are different and there will be no duplicates

	SELECT expirationdate
	FROM SubscriptionsProduct2
	WHERE active = 1


)
-- the code below was provided to focus on UNION
select
	date_trunc('year', expirationdate) as exp_year, 
	count(*) as subscriptions
from 
	all_subscriptions
group by 
	date_trunc('year', expirationdate)


/*
Union all allows us to pull the customer data from the two different databases and perform one query.
*/

-- Challenge 7
with all_cancelation_reasons as(
    select SUBSCRIPTIONID, cancelationreason1 as cancelationreason
    from cancelations

    UNION
    -- union is safer in this scenario just in case a user reported the same answer or null multiple times

    select SUBSCRIPTIONID, cancelationreason2 as cancelationreason
    from cancelations

    UNION 

    select SUBSCRIPTIONID, cancelationreason3 as cancelationreason
    from cancelations
)
-- the code below was provided to focus on UNION
select 
    cast(count( 
        case when cancelationreason = 'Expensive' 
        then subscriptionid end) as float)
    /count(distinct subscriptionid) as percent_expensive
from    
    all_cancelation_reasons;

/*
50%, or half, of the users who canceled their subscriptions reasoned that it was because it was too expensive.
*/

-- Challenge 8

select e.employeeid,
    e.name as employee_name,
    manager.name as manager_name,
    case
        when manager.name is null then e.email
        else manager.email 
        end as contact_email
    -- course provided coalesce() as an althernate solution:
	-- coalesce(manager.email, e.email) as contact_email
from employees e
left join employees manager
on e.managerid = manager.employeeid
where e.department = 'Sales';

-- Challenge 9
with monthly_revenue as( -- the monthly revenue cte was provided
    select 
        date_trunc('month', orderdate) as order_month, 
        sum(revenue) as monthly_revenue
    from 
        subscriptions
    group by 
        date_trunc('month', orderdate)
        )

select current.order_month as current_month,
    previous.order_month as previous_month,
    current.monthly_revenue as current_revenue,
    previous.monthly_revenue as previous_revenue
from
	monthly_revenue current
join
	monthly_revenue previous
where
	datediff('month', previous.order_month, current.order_month) = 1
	AND
	current.monthly_revenue > previous.monthly_revenue;

/*
This report identifies July and October as months where the revenue was higher than the previous month.
*/

-- Challenge 10
WITH sale_ranks AS (
	SELECT
		salesemployeeid,
		saleamount,
		saledate,
		row_number() OVER(partition by salesemployeeid order by saledate desc) as most_recent_sale
	FROM
		sale
)
SELECT
	*
FROM
	sale_ranks
WHERE most_recent_sale = 1

/*
The report keeps track of each employee's sale quota over time with a running total and percentage of their quota reached.
This data better visualizes the performance of each employee as they make a sale.
*/

-- Challenge 11
SELECT
    StatusMovementID,
    SubscriptionID,
    StatusID,
    MovementDate,
    lead(MovementDate, 1) OVER (partition by SubscriptionID order by MovementDate) as nextstatusmovementdate,
    lead(MovementDate, 1) OVER (partition by SubscriptionID order by MovementDate) - MovementDate AS timeinstatus
FROM
    PaymentStatusLog
WHERE
    subscriptionid = 38844

/*
This report provides insight on the time difference between payment steps and can identify if and where any issues occured.
*/