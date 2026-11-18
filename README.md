# Bus Reservation & Analytics System

**A portfolio-ready MySQL project demonstrating relational database design, stored procedures, transactional booking, cancellation, reporting, data integrity, and query optimisation.**

## Technology
- MySQL 8.0+
- SQL (DDL, DML, joins, subqueries, aggregate functions)
- Stored procedures, transactions, exception handling
- Indexes, views, and `EXPLAIN`

## Project structure

```text
Bus_Reservation_Analytics_System/
├── README.md
├── LICENSE
├── .gitignore
├── sql/
│   ├── 01_schema.sql
│   ├── 02_sample_data.sql
│   ├── 03_stored_procedures.sql
│   ├── 04_views_and_reports.sql
│   └── 05_test_cases.sql
└── docs/
    ├── DATA_DICTIONARY.md
    └── TESTING_GUIDE.md
```

## What this project demonstrates

1. **Relational schema design:** routes, buses, seats, passengers, and bookings are separated into related tables.
2. **Stored procedure – booking:** validates passenger, bus, journey date, fare, and seat availability; locks the seat row; inserts the booking and updates seat status in one transaction.
3. **Stored procedure – cancellation:** locks the booking, prevents repeated cancellation, changes its status, and releases the seat in one transaction.
4. **Stored procedure – analytics report:** returns summary KPIs and bus-wise performance for a selected date range.
5. **Reporting:** views and queries for revenue, booking status, route performance, and occupancy.
6. **Performance:** indexes on common join/filter columns and an `EXPLAIN` exercise.

## Setup (MySQL Workbench)

1. Install MySQL Server 8.0+ and open MySQL Workbench.
2. Open and execute these files **in this exact order**:
   - `sql/01_schema.sql`
   - `sql/02_sample_data.sql`
   - `sql/03_stored_procedures.sql`
   - `sql/04_views_and_reports.sql`
3. Execute `sql/05_test_cases.sql` to test booking, cancellation, and reporting.
4. Refresh the Schemas panel and confirm `bus_reservation_analytics` exists.

> The schema script creates and selects a database named `bus_reservation_analytics`. If you already have a database with that name, the script drops and recreates it. Back up any existing database with that name before running it.

## Setup (VS Code terminal)

If the MySQL command-line client is installed and available on PATH:

```bash
mysql -u root -p < sql/01_schema.sql
mysql -u root -p < sql/02_sample_data.sql
mysql -u root -p < sql/03_stored_procedures.sql
mysql -u root -p < sql/04_views_and_reports.sql
mysql -u root -p < sql/05_test_cases.sql
```

Enter your own MySQL password when prompted. Do not put passwords in project files or GitHub.

## Try the stored procedures

```sql
-- Book an available seat for a date one week from today.
CALL sp_book_ticket(1, 101, 'A04', DATE_ADD(CURDATE(), INTERVAL 7 DAY), 650.00);

-- Cancel the newly created booking (replace 4 with the booking_id returned by your query).
SELECT * FROM bookings ORDER BY booking_id DESC LIMIT 5;
CALL sp_cancel_ticket(4);

-- Get report results for the current month.
CALL sp_booking_analytics_report(
    DATE_FORMAT(CURDATE(), '%Y-%m-01'),
    LAST_DAY(CURDATE())
);
```

The exact generated `booking_id` depends on whether the database has been freshly created and whether you have run the test script before. Always look it up instead of assuming it is `4`.

## Useful verification queries

```sql
SELECT * FROM vw_booking_details;
SELECT * FROM vw_route_performance;
SELECT * FROM vw_daily_revenue;
SELECT bus_id, seat_number, seat_status
FROM bus_seats
ORDER BY bus_id, seat_number;
```

## Query optimisation exercise

Run the following before and after temporarily removing/recreating the suggested index only in a separate practice copy of the database:

```sql
EXPLAIN
SELECT booking_id, passenger_id, bus_id, journey_date, fare, booking_status
FROM bookings
WHERE bus_id = 101
  AND journey_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY)
ORDER BY journey_date;
```

Inspect `key`, `type`, and `rows` in the output. The composite index `idx_bookings_bus_journey` is intended to support this filter and sort pattern. Do not claim a measured speed improvement unless you actually benchmark it on your own machine and dataset.

## Important portfolio guidance

- Run every SQL file and test the procedures before publishing.
- Capture genuine screenshots from MySQL Workbench showing the schema, successful procedure calls, and report result sets.
- If you connect this database to your existing Java/JDBC Bus Reservation application later, document that integration only after it is implemented.
- This is a database/SQL portfolio project, not a finished web application. Do not describe it as a deployed booking website.

## Suggested resume entry (use after testing)

**Bus Reservation & Analytics System | MySQL, SQL, Stored Procedures**
- Designed a normalized relational database for routes, buses, passengers, seats, and bookings with primary/foreign-key constraints and indexes.
- Developed transactional MySQL stored procedures for ticket booking and cancellation, including validation, row locking, and exception handling.
- Built reporting views and a stored procedure to analyse booking volume, revenue, cancellations, and bus-wise performance.

Only retain claims that you personally run, understand, and can explain in an interview.
