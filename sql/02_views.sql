-- ============================================================================
-- MakeMyTrip — Views
-- ----------------------------------------------------------------------------
-- These encapsulate the two things that are easy to get wrong in this schema,
-- so every later query gets them right for free:
--
--   1. NET REVENUE.  Payments exist only for Confirmed / Completed / Refunded
--      bookings — Pending and Cancelled never paid. And a Refunded payment came
--      back out. So net revenue = paid, minus anything refunded.
--
--   2. VENDOR + LOCATION.  A booking's supplier lives in whichever bridge +
--      dimension pair matches its service. v_booking_detail stitches all five
--      paths into one row per booking so you never write a five-way UNION again.
-- ============================================================================

DROP VIEW IF EXISTS v_booking_detail;
DROP VIEW IF EXISTS v_service_summary;

-- One enriched row per booking: payment, rating, coupon, vendor, location.
CREATE VIEW v_booking_detail AS
SELECT
    b.BookingID,
    b.UserID,
    b.BookingDateTime,
    substr(b.BookingDateTime, 1, 4)              AS BookingYear,
    substr(b.BookingDateTime, 1, 7)              AS BookingMonth,   -- YYYY-MM
    b.ServiceType,
    b.Status,
    b.TotalPrice,
    p.PaymentAmount,
    p.PaymentType,
    CASE WHEN b.Status = 'Refunded' THEN 0
         ELSE COALESCE(p.PaymentAmount, 0) END   AS NetRevenue,
    CASE WHEN p.PaymentAmount IS NOT NULL THEN 1 ELSE 0 END AS IsPaid,
    r.AvgRating,
    dc.DiscountPercent,
    CASE WHEN dc.BookingID IS NOT NULL THEN 1 ELSE 0 END    AS HasCoupon,
    vend.Vendor,
    vend.Location
FROM Bookings b
LEFT JOIN Payments p        ON p.BookingID = b.BookingID
LEFT JOIN (
    SELECT BookingID, AVG(Rating) AS AvgRating
    FROM Reviews GROUP BY BookingID
) r  ON r.BookingID = b.BookingID
LEFT JOIN (
    SELECT BookingID, AVG(DiscountPercent) AS DiscountPercent
    FROM DiscountCoupons GROUP BY BookingID
) dc ON dc.BookingID = b.BookingID
LEFT JOIN (
    SELECT fb.BookingID, f.Airline  AS Vendor,
           f.DepartureAirport || '-' || f.ArrivalAirport AS Location
    FROM FlightBookings fb JOIN Flights f ON f.FlightID = fb.FlightID
    UNION ALL
    SELECT hb.BookingID, h.Name AS Vendor, h.Location
    FROM HotelBookings hb JOIN Hotels h ON h.HotelID = hb.HotelID
    UNION ALL
    SELECT bb.BookingID, bu.Operator AS Vendor,
           bu.DepartureLocation || '-' || bu.ArrivalLocation
    FROM BusBookings bb JOIN Buses bu ON bu.BusID = bb.BusID
    UNION ALL
    SELECT tb.BookingID, tr.Operator AS Vendor,
           tr.DepartureStation || '-' || tr.ArrivalStation
    FROM TrainBookings tb JOIN Trains tr ON tr.TrainID = tb.TrainID
    UNION ALL
    SELECT cb.BookingID, cr.CarType AS Vendor,
           cr.PickupLocation || '-' || cr.DropOffLocation
    FROM CarRentalBookings cb JOIN CarRentals cr ON cr.CarRentalID = cb.CarRentalID
) vend ON vend.BookingID = b.BookingID;

-- Service-level rollup used across the reporting queries.
CREATE VIEW v_service_summary AS
SELECT
    ServiceType,
    COUNT(*)                                             AS Bookings,
    SUM(TotalPrice)                                      AS BasketValue,
    SUM(NetRevenue)                                      AS NetRevenue,
    ROUND(SUM(NetRevenue) * 1.0 / COUNT(*), 0)           AS RevenuePerBooking,
    ROUND(AVG(AvgRating), 2)                             AS AvgRating,
    SUM(CASE WHEN Status IN ('Cancelled','Refunded') THEN 1 ELSE 0 END) AS FailedBookings,
    ROUND(100.0 * SUM(CASE WHEN Status IN ('Cancelled','Refunded') THEN 1 ELSE 0 END)
          / COUNT(*), 1)                                 AS FailureRatePct
FROM v_booking_detail
GROUP BY ServiceType;
