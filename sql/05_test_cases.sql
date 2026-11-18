USE bus_reservation_analytics;

-- TEST 1: Confirm baseline sample records.
SELECT * FROM vw_booking_details ORDER BY booking_id;
SELECT * FROM vw_route_performance ORDER BY confirmed_revenue DESC;

-- TEST 2: Book a seat. Run once on a fresh database.
-- Passenger 1, bus 1, seat A03 should be available in the sample data.
CALL sp_book_ticket(
    1,
    1,
    'A03',
    DATE_ADD(CURDATE(), INTERVAL 7 DAY),
    650.00
);

-- Find the booking just created; do not assume an ID.
SELECT booking_id, passenger_id, bus_id, seat_number, journey_date, booking_status
FROM bookings
WHERE bus_id = 1 AND seat_number = 'A03'
ORDER BY booking_id DESC;

-- TEST 3: Cancel the booking created above.
-- Copy its booking_id from the previous result and replace <BOOKING_ID>.
-- Example only: CALL sp_cancel_ticket(6);
-- CALL sp_cancel_ticket(<BOOKING_ID>);

-- TEST 4: Verify seat status after cancellation.
SELECT bus_id, seat_number, seat_status
FROM bus_seats
WHERE bus_id = 1 AND seat_number = 'A03';

-- TEST 5: Run analytics report for the current month.
CALL sp_booking_analytics_report(
    DATE_FORMAT(CURDATE(), '%Y-%m-01'),
    LAST_DAY(CURDATE())
);

-- TEST 6: Verify audit trail.
SELECT * FROM booking_audit ORDER BY action_time DESC, audit_id DESC;

-- NEGATIVE TESTS (uncomment and run individually; an error is expected):
-- A. Duplicate seat booking should fail:
-- CALL sp_book_ticket(2, 1, 'A01', DATE_ADD(CURDATE(), INTERVAL 7 DAY), 650.00);
--
-- B. Past journey date should fail:
-- CALL sp_book_ticket(2, 1, 'A04', DATE_SUB(CURDATE(), INTERVAL 1 DAY), 650.00);
--
-- C. Unknown passenger should fail:
-- CALL sp_book_ticket(9999, 1, 'A04', DATE_ADD(CURDATE(), INTERVAL 7 DAY), 650.00);
--
-- D. Invalid report date range should fail:
-- CALL sp_booking_analytics_report(CURDATE(), DATE_SUB(CURDATE(), INTERVAL 1 DAY));
--
-- E. Cancelling the same booking twice should fail:
-- CALL sp_cancel_ticket(<ALREADY_CANCELLED_BOOKING_ID>);
