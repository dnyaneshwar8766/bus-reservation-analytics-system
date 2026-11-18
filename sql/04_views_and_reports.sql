USE bus_reservation_analytics;

-- Detailed booking view for operational reporting.
CREATE OR REPLACE VIEW vw_booking_details AS
SELECT
    k.booking_id,
    p.full_name AS passenger_name,
    p.email,
    b.bus_number,
    b.bus_type,
    r.source_city,
    r.destination_city,
    k.seat_number,
    k.booking_date,
    k.journey_date,
    k.fare,
    k.booking_status
FROM bookings k
JOIN passengers p ON p.passenger_id = k.passenger_id
JOIN buses b ON b.bus_id = k.bus_id
JOIN routes r ON r.route_id = b.route_id;

-- Route/bus performance view.
CREATE OR REPLACE VIEW vw_route_performance AS
SELECT
    b.bus_id,
    b.bus_number,
    b.bus_type,
    r.source_city,
    r.destination_city,
    b.total_seats,
    COUNT(CASE WHEN k.booking_status = 'CONFIRMED' THEN 1 END) AS confirmed_bookings,
    COUNT(CASE WHEN k.booking_status = 'CANCELLED' THEN 1 END) AS cancelled_bookings,
    COALESCE(SUM(CASE WHEN k.booking_status = 'CONFIRMED' THEN k.fare ELSE 0 END), 0) AS confirmed_revenue,
    ROUND(
        100.0 * COUNT(CASE WHEN k.booking_status = 'CONFIRMED' THEN 1 END)
        / NULLIF(b.total_seats, 0), 2
    ) AS sample_seat_fill_pct
FROM buses b
JOIN routes r ON r.route_id = b.route_id
LEFT JOIN bookings k ON k.bus_id = b.bus_id
GROUP BY b.bus_id, b.bus_number, b.bus_type,
         r.source_city, r.destination_city, b.total_seats;

-- Daily confirmed revenue view.
CREATE OR REPLACE VIEW vw_daily_revenue AS
SELECT
    journey_date,
    COUNT(*) AS confirmed_ticket_count,
    SUM(fare) AS confirmed_revenue
FROM bookings
WHERE booking_status = 'CONFIRMED'
GROUP BY journey_date;

-- Example analytical queries.
-- 1. Revenue by route.
SELECT
    r.source_city,
    r.destination_city,
    COUNT(k.booking_id) AS booking_count,
    COALESCE(SUM(CASE WHEN k.booking_status = 'CONFIRMED' THEN k.fare ELSE 0 END), 0) AS revenue
FROM routes r
JOIN buses b ON b.route_id = r.route_id
LEFT JOIN bookings k ON k.bus_id = b.bus_id
GROUP BY r.route_id, r.source_city, r.destination_city
ORDER BY revenue DESC;

-- 2. Passenger booking history.
SELECT
    p.full_name,
    COUNT(k.booking_id) AS total_bookings,
    COALESCE(SUM(CASE WHEN k.booking_status = 'CONFIRMED' THEN k.fare ELSE 0 END), 0) AS confirmed_spend
FROM passengers p
LEFT JOIN bookings k ON k.passenger_id = p.passenger_id
GROUP BY p.passenger_id, p.full_name
ORDER BY confirmed_spend DESC;

-- 3. Available seats by bus.
SELECT
    b.bus_number,
    COUNT(*) AS available_seats
FROM buses b
JOIN bus_seats s ON s.bus_id = b.bus_id
WHERE s.seat_status = 'AVAILABLE'
GROUP BY b.bus_id, b.bus_number
ORDER BY available_seats DESC;
