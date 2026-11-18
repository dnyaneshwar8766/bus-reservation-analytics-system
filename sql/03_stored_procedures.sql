USE bus_reservation_analytics;

-- 1) Book a ticket safely.
-- The seat row is locked during the transaction to prevent two sessions
-- from booking the same seat at the same time.
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_book_ticket$$
CREATE PROCEDURE sp_book_ticket(
    IN p_passenger_id INT,
    IN p_bus_id INT,
    IN p_seat_number VARCHAR(8),
    IN p_journey_date DATE,
    IN p_fare DECIMAL(10,2)
)
BEGIN
    DECLARE v_seat_status VARCHAR(20) DEFAULT NULL;
    DECLARE v_passenger_count INT DEFAULT 0;
    DECLARE v_bus_count INT DEFAULT 0;
    DECLARE v_new_booking_id BIGINT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_journey_date IS NULL OR p_journey_date < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Journey date must be today or a future date';
    END IF;

    IF p_fare IS NULL OR p_fare < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Fare must be zero or greater';
    END IF;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_passenger_count
    FROM passengers
    WHERE passenger_id = p_passenger_id;

    IF v_passenger_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Passenger does not exist';
    END IF;

    SELECT COUNT(*) INTO v_bus_count
    FROM buses
    WHERE bus_id = p_bus_id;

    IF v_bus_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Bus does not exist';
    END IF;

    SELECT seat_status INTO v_seat_status
    FROM bus_seats
    WHERE bus_id = p_bus_id
      AND seat_number = p_seat_number
    FOR UPDATE;

    IF v_seat_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Seat does not exist for this bus';
    END IF;

    IF v_seat_status <> 'AVAILABLE' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Seat is already booked';
    END IF;

    INSERT INTO bookings
        (passenger_id, bus_id, seat_number, journey_date, fare, booking_status)
    VALUES
        (p_passenger_id, p_bus_id, p_seat_number, p_journey_date, p_fare, 'CONFIRMED');

    SET v_new_booking_id = LAST_INSERT_ID();

    UPDATE bus_seats
    SET seat_status = 'BOOKED'
    WHERE bus_id = p_bus_id
      AND seat_number = p_seat_number;

    INSERT INTO booking_audit (booking_id, action_type, remarks)
    VALUES (v_new_booking_id, 'BOOKED', 'Ticket booked through sp_book_ticket');

    COMMIT;

    SELECT v_new_booking_id AS booking_id,
           'CONFIRMED' AS booking_status,
           'Ticket booked successfully' AS message;
END$$

-- 2) Cancel a ticket and release its seat.
DROP PROCEDURE IF EXISTS sp_cancel_ticket$$
CREATE PROCEDURE sp_cancel_ticket(IN p_booking_id BIGINT)
BEGIN
    DECLARE v_bus_id INT DEFAULT NULL;
    DECLARE v_seat_number VARCHAR(8) DEFAULT NULL;
    DECLARE v_booking_status VARCHAR(20) DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT bus_id, seat_number, booking_status
      INTO v_bus_id, v_seat_number, v_booking_status
    FROM bookings
    WHERE booking_id = p_booking_id
    FOR UPDATE;

    IF v_booking_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Booking does not exist';
    END IF;

    IF v_booking_status = 'CANCELLED' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Booking is already cancelled';
    END IF;

    UPDATE bookings
    SET booking_status = 'CANCELLED'
    WHERE booking_id = p_booking_id;

    UPDATE bus_seats
    SET seat_status = 'AVAILABLE'
    WHERE bus_id = v_bus_id
      AND seat_number = v_seat_number;

    INSERT INTO booking_audit (booking_id, action_type, remarks)
    VALUES (p_booking_id, 'CANCELLED', 'Ticket cancelled through sp_cancel_ticket');

    COMMIT;

    SELECT p_booking_id AS booking_id,
           'CANCELLED' AS booking_status,
           'Ticket cancelled and seat released' AS message;
END$$

-- 3) Date-range analytics report.
-- Returns two result sets: overall KPIs, then bus-wise performance.
DROP PROCEDURE IF EXISTS sp_booking_analytics_report$$
CREATE PROCEDURE sp_booking_analytics_report(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    IF p_start_date IS NULL OR p_end_date IS NULL OR p_start_date > p_end_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Provide a valid date range (start date <= end date)';
    END IF;

    SELECT
        p_start_date AS report_start_date,
        p_end_date AS report_end_date,
        COUNT(*) AS total_bookings,
        SUM(CASE WHEN booking_status = 'CONFIRMED' THEN 1 ELSE 0 END) AS confirmed_bookings,
        SUM(CASE WHEN booking_status = 'CANCELLED' THEN 1 ELSE 0 END) AS cancelled_bookings,
        COALESCE(SUM(CASE WHEN booking_status = 'CONFIRMED' THEN fare ELSE 0 END), 0) AS confirmed_revenue,
        COALESCE(ROUND(
            100.0 * SUM(CASE WHEN booking_status = 'CANCELLED' THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*), 0), 2
        ), 0) AS cancellation_rate_pct
    FROM bookings
    WHERE journey_date BETWEEN p_start_date AND p_end_date;

    SELECT
        b.bus_id,
        b.bus_number,
        r.source_city,
        r.destination_city,
        COUNT(k.booking_id) AS total_bookings,
        SUM(CASE WHEN k.booking_status = 'CONFIRMED' THEN 1 ELSE 0 END) AS confirmed_bookings,
        SUM(CASE WHEN k.booking_status = 'CANCELLED' THEN 1 ELSE 0 END) AS cancelled_bookings,
        COALESCE(SUM(CASE WHEN k.booking_status = 'CONFIRMED' THEN k.fare ELSE 0 END), 0) AS confirmed_revenue
    FROM buses b
    JOIN routes r ON r.route_id = b.route_id
    LEFT JOIN bookings k
      ON k.bus_id = b.bus_id
     AND k.journey_date BETWEEN p_start_date AND p_end_date
    GROUP BY b.bus_id, b.bus_number, r.source_city, r.destination_city
    ORDER BY confirmed_revenue DESC, total_bookings DESC;
END$$
DELIMITER ;
