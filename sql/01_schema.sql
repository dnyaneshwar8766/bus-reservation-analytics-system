-- Bus Reservation & Analytics System
-- MySQL 8.0+
-- WARNING: This script drops and recreates the project database.

DROP DATABASE IF EXISTS bus_reservation_analytics;
CREATE DATABASE bus_reservation_analytics
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE bus_reservation_analytics;

CREATE TABLE routes (
    route_id       INT AUTO_INCREMENT PRIMARY KEY,
    source_city    VARCHAR(80) NOT NULL,
    destination_city VARCHAR(80) NOT NULL,
    distance_km    DECIMAL(7,2) NOT NULL,
    CONSTRAINT chk_route_distance CHECK (distance_km > 0),
    CONSTRAINT uq_route UNIQUE (source_city, destination_city)
) ENGINE=InnoDB;

CREATE TABLE buses (
    bus_id         INT AUTO_INCREMENT PRIMARY KEY,
    bus_number     VARCHAR(20) NOT NULL UNIQUE,
    bus_type       VARCHAR(40) NOT NULL,
    route_id       INT NOT NULL,
    total_seats    INT NOT NULL,
    CONSTRAINT chk_total_seats CHECK (total_seats > 0),
    CONSTRAINT fk_buses_route FOREIGN KEY (route_id)
        REFERENCES routes(route_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_buses_route (route_id)
) ENGINE=InnoDB;

CREATE TABLE passengers (
    passenger_id   INT AUTO_INCREMENT PRIMARY KEY,
    full_name      VARCHAR(120) NOT NULL,
    email          VARCHAR(150) NOT NULL UNIQUE,
    phone          VARCHAR(20) NOT NULL UNIQUE,
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE bus_seats (
    bus_id         INT NOT NULL,
    seat_number    VARCHAR(8) NOT NULL,
    seat_status    ENUM('AVAILABLE', 'BOOKED') NOT NULL DEFAULT 'AVAILABLE',
    PRIMARY KEY (bus_id, seat_number),
    CONSTRAINT fk_seats_bus FOREIGN KEY (bus_id)
        REFERENCES buses(bus_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    INDEX idx_seats_status (seat_status)
) ENGINE=InnoDB;

CREATE TABLE bookings (
    booking_id     BIGINT AUTO_INCREMENT PRIMARY KEY,
    passenger_id   INT NOT NULL,
    bus_id         INT NOT NULL,
    seat_number    VARCHAR(8) NOT NULL,
    booking_date   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    journey_date   DATE NOT NULL,
    fare           DECIMAL(10,2) NOT NULL,
    booking_status ENUM('CONFIRMED', 'CANCELLED') NOT NULL DEFAULT 'CONFIRMED',
    CONSTRAINT chk_booking_fare CHECK (fare >= 0),
    CONSTRAINT fk_bookings_passenger FOREIGN KEY (passenger_id)
        REFERENCES passengers(passenger_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_bookings_seat FOREIGN KEY (bus_id, seat_number)
        REFERENCES bus_seats(bus_id, seat_number)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_bookings_passenger (passenger_id),
    INDEX idx_bookings_bus_journey (bus_id, journey_date),
    INDEX idx_bookings_status_date (booking_status, booking_date),
    INDEX idx_bookings_journey (journey_date)
) ENGINE=InnoDB;

CREATE TABLE booking_audit (
    audit_id       BIGINT AUTO_INCREMENT PRIMARY KEY,
    booking_id     BIGINT NOT NULL,
    action_type    ENUM('BOOKED', 'CANCELLED') NOT NULL,
    action_time    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remarks        VARCHAR(255),
    CONSTRAINT fk_audit_booking FOREIGN KEY (booking_id)
        REFERENCES bookings(booking_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_audit_booking_time (booking_id, action_time)
) ENGINE=InnoDB;

-- Create the seat inventory for every bus.
DELIMITER $$
CREATE PROCEDURE sp_create_bus_seats(
    IN p_bus_id INT,
    IN p_seat_prefix VARCHAR(3),
    IN p_seat_count INT
)
BEGIN
    DECLARE v_counter INT DEFAULT 1;

    WHILE v_counter <= p_seat_count DO
        INSERT INTO bus_seats (bus_id, seat_number, seat_status)
        VALUES (p_bus_id, CONCAT(p_seat_prefix, LPAD(v_counter, 2, '0')), 'AVAILABLE');
        SET v_counter = v_counter + 1;
    END WHILE;
END$$
DELIMITER ;

-- Sample route and bus master records are inserted in 02_sample_data.sql.
