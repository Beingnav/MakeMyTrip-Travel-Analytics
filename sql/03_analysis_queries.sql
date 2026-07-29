-- ============================================================================
-- MakeMyTrip — Analysis Queries
-- ----------------------------------------------------------------------------
-- 20 business questions, grouped. Each is standalone: run the whole file, or
-- copy one block. Techniques used are noted so this doubles as a reference:
-- joins, GROUP BY / HAVING, subqueries, CTEs, window functions (RANK, LAG,
-- running SUM, moving AVG), CASE, and the two views from 02_views.sql.
--
-- Run 01_schema, load the data, run 02_views, then this.
-- ============================================================================


-- ############################################################################
-- A. REVENUE AND VOLUME
-- ############################################################################

-- Q1 — Headline totals: basket value vs gross vs net revenue.
-- Why they differ: Pending/Cancelled bookings never pay, and Refunded ones
-- pay then reverse. This one query explains the whole "which number is revenue"
-- question. (Aggregation, CASE.)
SELECT
    COUNT(*)                                                      AS TotalBookings,
    ROUND(SUM(TotalPrice))                                        AS BasketValue,
    ROUND(SUM(COALESCE(PaymentAmount, 0)))                        AS GrossRevenue,
    ROUND(SUM(CASE WHEN Status='Refunded' THEN PaymentAmount ELSE 0 END)) AS RefundedRevenue,
    ROUND(SUM(NetRevenue))                                        AS NetRevenue,
    ROUND(100.0 * SUM(NetRevenue) / SUM(TotalPrice), 1)           AS RealisationPct
FROM v_booking_detail;


-- Q2 — Revenue by service, with each service's share of the total.
-- The core cut of the dataset. (Window function for the share denominator.)
SELECT
    ServiceType,
    Bookings,
    ROUND(NetRevenue)                                             AS NetRevenue,
    RevenuePerBooking,
    ROUND(100.0 * Bookings   / SUM(Bookings)   OVER (), 1)        AS BookingSharePct,
    ROUND(100.0 * NetRevenue / SUM(NetRevenue) OVER (), 1)        AS RevenueSharePct
FROM v_service_summary
ORDER BY NetRevenue DESC;


-- Q3 — The volume-vs-revenue divergence, stated as a single gap column.
-- A positive gap means the service punches above its booking weight on revenue.
-- (CTE feeding a window calculation.)
WITH s AS (
    SELECT ServiceType, Bookings, NetRevenue,
           100.0 * Bookings   / SUM(Bookings)   OVER () AS BookingPct,
           100.0 * NetRevenue / SUM(NetRevenue) OVER () AS RevenuePct
    FROM v_service_summary
)
SELECT ServiceType,
       ROUND(BookingPct, 1)                 AS BookingPct,
       ROUND(RevenuePct, 1)                 AS RevenuePct,
       ROUND(RevenuePct - BookingPct, 1)    AS RevenueMinusBookingGap
FROM s
ORDER BY RevenueMinusBookingGap DESC;


-- Q4 — Booking value distribution by price band. (CASE bucketing, GROUP BY.)
SELECT
    CASE
        WHEN TotalPrice <  2500 THEN '1. Under 2.5K'
        WHEN TotalPrice < 10000 THEN '2. 2.5K-10K'
        WHEN TotalPrice < 25000 THEN '3. 10K-25K'
        WHEN TotalPrice < 75000 THEN '4. 25K-75K'
        ELSE                         '5. 75K+'
    END                          AS PriceBand,
    COUNT(*)                     AS Bookings,
    ROUND(SUM(NetRevenue))       AS NetRevenue
FROM v_booking_detail
GROUP BY PriceBand
ORDER BY PriceBand;


-- ############################################################################
-- B. BOOKING STATUS AND RELIABILITY
-- ############################################################################

-- Q5 — Status breakdown overall. (Aggregation with a share window.)
SELECT
    Status,
    COUNT(*)                                          AS Bookings,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS SharePct,
    ROUND(SUM(TotalPrice))                            AS BasketValue
FROM v_booking_detail
GROUP BY Status
ORDER BY Bookings DESC;


-- Q6 — Failure rate (cancelled + refunded) by service, ranked worst first.
-- (Conditional aggregation; reads straight from the summary view.)
SELECT ServiceType, Bookings, FailedBookings, FailureRatePct
FROM v_service_summary
ORDER BY FailureRatePct DESC;


-- Q7 — Cancellation vs refund split by service, so you can see which kind of
-- failure dominates. (Conditional aggregation, two rates side by side.)
SELECT
    ServiceType,
    ROUND(100.0 * SUM(CASE WHEN Status='Cancelled' THEN 1 ELSE 0 END)/COUNT(*), 1) AS CancelPct,
    ROUND(100.0 * SUM(CASE WHEN Status='Refunded'  THEN 1 ELSE 0 END)/COUNT(*), 1) AS RefundPct
FROM v_booking_detail
GROUP BY ServiceType
ORDER BY (CancelPct + RefundPct) DESC;


-- Q8 — Money sitting in unconverted baskets (Pending + Cancelled), by service.
-- The ops-priority list. (Filter + aggregate.)
SELECT
    ServiceType,
    COUNT(*)                AS AtRiskBookings,
    ROUND(SUM(TotalPrice))  AS ValueAtRisk
FROM v_booking_detail
WHERE Status IN ('Pending','Cancelled')
GROUP BY ServiceType
ORDER BY ValueAtRisk DESC;


-- ##############################################################################
-- C. SUPPLIERS (VENDORS AND LOCATIONS)
-- ##############################################################################

-- Q9 — Top 10 vendors by net revenue, across every service.
-- (Uses the stitched Vendor field from the view; ranked with a window.)
SELECT
    Vendor,
    ServiceType,
    COUNT(*)                     AS Bookings,
    ROUND(SUM(NetRevenue))       AS NetRevenue,
    RANK() OVER (ORDER BY SUM(NetRevenue) DESC) AS RevenueRank
FROM v_booking_detail
WHERE Vendor IS NOT NULL
GROUP BY Vendor, ServiceType
ORDER BY NetRevenue DESC
LIMIT 10;


-- Q10 — Top 3 vendors WITHIN each service. Classic "top-N per group".
-- (Window RANK partitioned by service, filtered in an outer query.)
WITH ranked AS (
    SELECT
        ServiceType, Vendor,
        COUNT(*)               AS Bookings,
        SUM(NetRevenue)        AS NetRevenue,
        RANK() OVER (PARTITION BY ServiceType ORDER BY SUM(NetRevenue) DESC) AS rnk
    FROM v_booking_detail
    WHERE Vendor IS NOT NULL
    GROUP BY ServiceType, Vendor
)
SELECT ServiceType, Vendor, Bookings, ROUND(NetRevenue) AS NetRevenue, rnk
FROM ranked
WHERE rnk <= 3
ORDER BY ServiceType, rnk;


-- Q11 — Top hotel cities by revenue, with average rating per city.
-- (Filtered aggregate joining two view columns.)
SELECT
    Location                     AS City,
    COUNT(*)                     AS Bookings,
    ROUND(SUM(NetRevenue))       AS NetRevenue,
    ROUND(AVG(AvgRating), 2)     AS AvgRating
FROM v_booking_detail
WHERE ServiceType = 'Hotel'
GROUP BY Location
HAVING COUNT(*) >= 3          -- ignore cities with too few bookings to mean much
ORDER BY NetRevenue DESC
LIMIT 10;


-- ##############################################################################
-- D. CUSTOMERS
-- ##############################################################################

-- Q12 — Repeat vs one-time customers, and their revenue.
-- (Subquery counting bookings per user, then bucketed.)
WITH per_user AS (
    SELECT UserID, COUNT(*) AS Bookings, SUM(NetRevenue) AS NetRevenue
    FROM v_booking_detail
    GROUP BY UserID
)
SELECT
    CASE WHEN Bookings > 1 THEN 'Repeat' ELSE 'One-time' END AS Segment,
    COUNT(*)                                                 AS Users,
    ROUND(AVG(Bookings), 2)                                  AS AvgBookings,
    ROUND(SUM(NetRevenue))                                   AS NetRevenue
FROM per_user
GROUP BY Segment;


-- Q13 — Top 10 customers by lifetime net revenue. (Join to Users for names.)
SELECT
    u.UserID,
    u.FirstName || ' ' || u.LastName AS Customer,
    COUNT(*)                          AS Bookings,
    ROUND(SUM(d.NetRevenue))          AS NetRevenue,
    ROUND(AVG(d.AvgRating), 2)        AS AvgRating
FROM v_booking_detail d
JOIN Users u ON u.UserID = d.UserID
GROUP BY u.UserID, Customer
ORDER BY NetRevenue DESC
LIMIT 10;


-- Q14 — Days from registration to a user's FIRST booking (activation gap).
-- Measured per user, not per booking. (Correlated first-booking subquery,
-- SQLite julianday date maths.)
WITH first_booking AS (
    SELECT b.UserID, MIN(b.BookingDateTime) AS FirstBooking
    FROM Bookings b GROUP BY b.UserID
)
SELECT
    ROUND(AVG(julianday(fb.FirstBooking) - julianday(u.RegistrationDate)), 0) AS AvgDaysToFirstBooking,
    ROUND(MIN(julianday(fb.FirstBooking) - julianday(u.RegistrationDate)), 0) AS MinDays,
    ROUND(MAX(julianday(fb.FirstBooking) - julianday(u.RegistrationDate)), 0) AS MaxDays
FROM first_booking fb
JOIN Users u ON u.UserID = fb.UserID;


-- ##############################################################################
-- E. REVIEWS
-- ##############################################################################

-- Q15 — Rating distribution and a simple satisfaction (NPS-style) score.
-- (Conditional aggregation across the whole Reviews table.)
SELECT
    COUNT(*)                                                        AS Reviews,
    ROUND(AVG(Rating), 2)                                           AS AvgRating,
    SUM(CASE WHEN Rating >= 4 THEN 1 ELSE 0 END)                    AS Promoters,
    SUM(CASE WHEN Rating <= 2 THEN 1 ELSE 0 END)                    AS Detractors,
    ROUND(100.0 * (SUM(CASE WHEN Rating>=4 THEN 1 ELSE 0 END)
                 - SUM(CASE WHEN Rating<=2 THEN 1 ELSE 0 END)) / COUNT(*), 0) AS SatisfactionScore
FROM Reviews;


-- Q16 — Review coverage: what share of bookings actually got a review, by service.
-- (COUNT DISTINCT over a LEFT-joined flag.)
SELECT
    ServiceType,
    COUNT(*)                                                   AS Bookings,
    SUM(CASE WHEN AvgRating IS NOT NULL THEN 1 ELSE 0 END)     AS Reviewed,
    ROUND(100.0 * SUM(CASE WHEN AvgRating IS NOT NULL THEN 1 ELSE 0 END)/COUNT(*), 1) AS CoveragePct,
    ROUND(AVG(AvgRating), 2)                                   AS AvgRating
FROM v_booking_detail
GROUP BY ServiceType
ORDER BY AvgRating DESC;


-- ##############################################################################
-- F. PAYMENTS AND PROMOTIONS
-- ##############################################################################

-- Q17 — Net revenue by payment method. (Group on the view's PaymentType.)
SELECT
    PaymentType,
    COUNT(*)                                              AS Payments,
    ROUND(SUM(NetRevenue))                                AS NetRevenue,
    ROUND(100.0 * SUM(NetRevenue) / SUM(SUM(NetRevenue)) OVER (), 1) AS SharePct
FROM v_booking_detail
WHERE PaymentType IS NOT NULL
GROUP BY PaymentType
ORDER BY NetRevenue DESC;


-- Q18 — Coupon impact: does a coupon lift the basket, and at what discount cost?
-- The key promotion question. (CASE split into two cohorts, compared.)
SELECT
    CASE WHEN HasCoupon = 1 THEN 'With coupon' ELSE 'No coupon' END AS Cohort,
    COUNT(*)                        AS Bookings,
    ROUND(AVG(TotalPrice))          AS AvgBasket,
    ROUND(AVG(DiscountPercent), 1)  AS AvgDiscountPct
FROM v_booking_detail
GROUP BY HasCoupon
ORDER BY HasCoupon DESC;


-- ##############################################################################
-- G. TIME SERIES  (the window-function showcase)
-- ##############################################################################

-- Q19 — Monthly net revenue with a running total and a 3-month moving average.
-- (Two window functions over an ordered month series built in a CTE.)
WITH monthly AS (
    SELECT BookingMonth AS Month,
           SUM(NetRevenue) AS NetRevenue,
           COUNT(*)        AS Bookings
    FROM v_booking_detail
    GROUP BY BookingMonth
)
SELECT
    Month,
    Bookings,
    ROUND(NetRevenue)                                                    AS NetRevenue,
    ROUND(SUM(NetRevenue) OVER (ORDER BY Month))                         AS RunningTotal,
    ROUND(AVG(NetRevenue) OVER (ORDER BY Month
              ROWS BETWEEN 2 PRECEDING AND CURRENT ROW))                 AS MovingAvg3M
FROM monthly
ORDER BY Month;


-- Q20 — Year-on-year revenue by quarter using LAG.
-- NOTE: 2026 stops on 20 July, so its Q3 is partial and Q4 is absent — the
-- YoY for those will look like a crash. That's the data ending, not a decline.
-- (LAG window reaching back four quarters for the same-quarter-last-year value.)
WITH quarterly AS (
    SELECT
        substr(BookingDateTime,1,4)                                   AS Yr,
        'Q' || ((CAST(substr(BookingDateTime,6,2) AS INTEGER)-1)/3 + 1) AS Qtr,
        SUM(NetRevenue)                                               AS NetRevenue
    FROM v_booking_detail
    GROUP BY Yr, Qtr
)
SELECT
    Yr, Qtr,
    ROUND(NetRevenue)                                                 AS NetRevenue,
    ROUND(LAG(NetRevenue, 4) OVER (ORDER BY Yr, Qtr))                 AS SameQtrLastYear,
    ROUND(100.0 * (NetRevenue - LAG(NetRevenue,4) OVER (ORDER BY Yr,Qtr))
          / LAG(NetRevenue,4) OVER (ORDER BY Yr,Qtr), 1)              AS YoYPct
FROM quarterly
ORDER BY Yr, Qtr;
