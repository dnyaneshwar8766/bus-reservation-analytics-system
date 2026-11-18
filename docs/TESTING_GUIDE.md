# Testing Guide

## Before testing
Execute SQL scripts 01 through 04 in order. Confirm that the database contains 4 buses, 40 seats, 6 passengers and 5 sample bookings.

## Functional test matrix

| Test | Action | Expected result |
|---|---|---|
| Valid booking | Book available seat A03 | New confirmed booking; A03 becomes BOOKED |
| Duplicate booking | Book already-booked seat A01 | Procedure returns an error; no new booking |
| Invalid passenger | Use passenger ID 9999 | Procedure returns an error; no seat change |
| Past journey | Supply yesterday's date | Procedure returns an error |
| Valid cancellation | Cancel a confirmed booking | Booking becomes CANCELLED; seat becomes AVAILABLE |
| Repeat cancellation | Cancel same booking again | Procedure returns an error |
| Valid report | Supply start date <= end date | Two result sets: summary and bus-wise report |
| Invalid report | Supply start date after end date | Procedure returns an error |

## Evidence to capture for GitHub
1. MySQL Workbench schema navigator showing the six tables.
2. `CALL sp_book_ticket(...)` success result and the inserted booking.
3. Seat status showing `BOOKED` after booking.
4. `CALL sp_cancel_ticket(...)` success result and seat status `AVAILABLE`.
5. Both result sets returned by `sp_booking_analytics_report`.
6. `EXPLAIN` output for the indexed bus/date query.

Use your own screenshots after running the scripts. Do not upload fabricated test evidence.
