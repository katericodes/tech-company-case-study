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
    SUM(CASE
        WHEN eventid = 1 THEN 1
        ELSE 0
        END) AS ViewedHelpCenterPage,
    SUM(CASE
        WHEN eventid = 2 THEN 1
        ELSE 0
        END) AS ClickedFAQs,
    SUM(CASE
        WHEN eventid = 3 THEN 1
        ELSE 0
        END) AS ClickedContactSupport,
    SUM(CASE
        WHEN eventid = 4 THEN 1
        ELSE 0
        END) AS SubmittedTicket
From FrontendEventLog
WHERE eventid in (1,2,3,4)
GROUP BY userid;

/*
This result provides insight on how manny times a certain user perfored a specific action.
*/

-- Challenge 6

/*
Takeaway
*/

-- Challenge 7

/*
Takeaway
*/

-- Challenge 8

/*
Takeaway
*/

-- Challenge 9

/*
Takeaway
*/

-- Challenge 10

/*
Takeaway
*/

-- Challenge 11

/*
Takeaway
*/