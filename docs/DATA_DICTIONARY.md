# Data Dictionary

## Entity relationship overview

```text
routes 1 ─── many buses
buses  1 ─── many bus_seats
buses  1 ─── many bookings
passengers 1 ─── many bookings
bookings 1 ─── many booking_audit records
```

## Tables

| Table | Purpose | Important columns |
|---|---|---|
| `routes` | Stores origin, destination and distance | `route_id` PK |
| `buses` | Bus master data and route assignment | `bus_id` PK, `route_id` FK |
| `bus_seats` | Seat inventory and current availability | Composite PK: `bus_id`, `seat_number` |
| `passengers` | Passenger contact details | `passenger_id` PK |
| `bookings` | Ticket booking and journey information | `booking_id` PK, passenger and seat FKs |
| `booking_audit` | Booking/cancellation activity history | `audit_id` PK, `booking_id` FK |

## Stored procedures

| Procedure | Inputs | Purpose |
|---|---|---|
| `sp_book_ticket` | passenger, bus, seat, journey date, fare | Validates and books a seat transactionally |
| `sp_cancel_ticket` | booking ID | Cancels a confirmed booking and releases its seat |
| `sp_booking_analytics_report` | start date, end date | Returns overall KPIs and bus-wise metrics |

## Views

- `vw_booking_details`: joined booking, passenger, bus and route information.
- `vw_route_performance`: booking counts and confirmed revenue by bus/route.
- `vw_daily_revenue`: confirmed ticket count and revenue by journey date.

## Data integrity choices

- Primary keys uniquely identify records.
- Foreign keys prevent orphan bookings and invalid route/bus references.
- `CHECK` constraints reject invalid distances, seat counts and negative fares.
- `UNIQUE` constraints prevent duplicate bus numbers, passenger email addresses and phone numbers.
- InnoDB transactions and `SELECT ... FOR UPDATE` protect the seat-booking operation from concurrent updates to the same seat.
