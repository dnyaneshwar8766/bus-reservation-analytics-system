USE bus_reservation_analytics;

INSERT INTO routes (source_city, destination_city, distance_km) VALUES
('Pune', 'Mumbai', 150.00),
('Pune', 'Nashik', 210.00),
('Pune', 'Kolhapur', 235.00),
('Mumbai', 'Goa', 590.00);

INSERT INTO buses (bus_number, bus_type, route_id, total_seats) VALUES
('MH12-PN-101', 'AC Seater', 1, 10),
('MH12-PN-102', 'Sleeper',   2, 10),
('MH12-PN-103', 'AC Seater', 3, 10),
('MH01-MU-104', 'Sleeper',   4, 10);

-- Generate 10 seats for each bus.
CALL sp_create_bus_seats(1, 'A', 10);
CALL sp_create_bus_seats(2, 'B', 10);
CALL sp_create_bus_seats(3, 'C', 10);
CALL sp_create_bus_seats(4, 'D', 10);

INSERT INTO passengers (full_name, email, phone) VALUES
('Aarav Patil', 'aarav.patil@example.com', '9000000001'),
('Saanvi Deshmukh', 'saanvi.d@example.com', '9000000002'),
('Ishaan Kulkarni', 'ishaan.k@example.com', '9000000003'),
('Ananya Joshi', 'ananya.j@example.com', '9000000004'),
('Vihaan Shah', 'vihaan.shah@example.com', '9000000005'),
('Mira More', 'mira.more@example.com', '9000000006');

-- Historical/future sample bookings for analytics practice.
-- The selected dates are relative to the day the script is run.
INSERT INTO bookings
(passenger_id, bus_id, seat_number, journey_date, fare, booking_status)
VALUES
(1, 1, 'A01', DATE_ADD(CURDATE(), INTERVAL 2 DAY), 650.00, 'CONFIRMED'),
(2, 1, 'A02', DATE_ADD(CURDATE(), INTERVAL 2 DAY), 650.00, 'CONFIRMED'),
(3, 2, 'B01', DATE_ADD(CURDATE(), INTERVAL 4 DAY), 820.00, 'CONFIRMED'),
(4, 3, 'C01', DATE_ADD(CURDATE(), INTERVAL 5 DAY), 700.00, 'CANCELLED'),
(5, 4, 'D01', DATE_ADD(CURDATE(), INTERVAL 8 DAY), 1250.00, 'CONFIRMED');

-- Keep seat inventory consistent with confirmed bookings only.
UPDATE bus_seats s
JOIN bookings b
  ON b.bus_id = s.bus_id
 AND b.seat_number = s.seat_number
SET s.seat_status = 'BOOKED'
WHERE b.booking_status = 'CONFIRMED';

INSERT INTO booking_audit (booking_id, action_type, remarks)
SELECT booking_id, 'BOOKED', 'Sample booking loaded for portfolio demonstration'
FROM bookings
WHERE booking_status = 'CONFIRMED';

INSERT INTO booking_audit (booking_id, action_type, remarks)
SELECT booking_id, 'CANCELLED', 'Sample cancelled booking loaded for reporting demonstration'
FROM bookings
WHERE booking_status = 'CANCELLED';

-- Verify sample data.
SELECT 'routes' AS table_name, COUNT(*) AS row_count FROM routes
UNION ALL SELECT 'buses', COUNT(*) FROM buses
UNION ALL SELECT 'bus_seats', COUNT(*) FROM bus_seats
UNION ALL SELECT 'passengers', COUNT(*) FROM passengers
UNION ALL SELECT 'bookings', COUNT(*) FROM bookings;
