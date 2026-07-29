# MakeMyTrip — Entity-Relationship Diagram

Renders on GitHub, in VS Code (Mermaid extension), or at [mermaid.live](https://mermaid.live).

```mermaid
erDiagram
    Users ||--o{ Bookings : places
    Users ||--o{ Reviews  : writes

    Bookings ||--o| Payments        : "paid by"
    Bookings ||--o{ Reviews         : "reviewed in"
    Bookings ||--o{ DiscountCoupons : "discounted by"

    Bookings ||--o| FlightBookings     : "is a"
    Bookings ||--o| HotelBookings      : "is a"
    Bookings ||--o| BusBookings        : "is a"
    Bookings ||--o| TrainBookings      : "is a"
    Bookings ||--o| CarRentalBookings  : "is a"

    Flights    ||--o{ FlightBookings    : "booked in"
    Hotels     ||--o{ HotelBookings     : "booked in"
    Buses      ||--o{ BusBookings       : "booked in"
    Trains     ||--o{ TrainBookings     : "booked in"
    CarRentals ||--o{ CarRentalBookings : "booked in"

    Users {
        int  UserID PK
        text FirstName
        text LastName
        text Email
        text RegistrationDate
    }
    Bookings {
        int  BookingID PK
        int  UserID FK
        text BookingDateTime
        real TotalPrice
        text Status
        text ServiceType
    }
    Flights {
        int  FlightID PK
        text Airline
        text DepartureAirport
        text ArrivalAirport
        real Price
    }
    Hotels {
        int  HotelID PK
        text Name
        text Location
        real PricePerNight
    }
    Buses {
        int  BusID PK
        text Operator
        real Price
    }
    Trains {
        int  TrainID PK
        text Operator
        real Price
    }
    CarRentals {
        int  CarRentalID PK
        text CarType
        real Price
    }
    FlightBookings {
        int FlightBookingID PK
        int BookingID FK
        int FlightID FK
        int Passengers
    }
    HotelBookings {
        int HotelBookingID PK
        int BookingID FK
        int HotelID FK
        int NumberOfRooms
    }
    BusBookings {
        int BusBookingID PK
        int BookingID FK
        int BusID FK
        int Passengers
    }
    TrainBookings {
        int TrainBookingID PK
        int BookingID FK
        int TrainID FK
        int Passengers
    }
    CarRentalBookings {
        int CarRentalBookingID PK
        int BookingID FK
        int CarRentalID FK
    }
    Payments {
        int  PaymentID PK
        int  BookingID FK
        text PaymentType
        text PaymentDate
        real PaymentAmount
    }
    DiscountCoupons {
        int  CouponID PK
        int  BookingID FK
        text Code
        int  DiscountPercent
    }
    Reviews {
        int  ReviewID PK
        int  BookingID FK
        int  UserID FK
        int  Rating
        text ReviewDate
    }
```

## How to read it

A **Booking** is the hub. Every booking belongs to one **User**, is for exactly one service, and reaches that service's inventory through a **bridge** table (`FlightBookings`, `HotelBookings`, and so on). The bridge pattern is what lets one `Bookings` table cover five different service types without five sets of nullable columns.

Hanging off each booking are its **Payment** (at most one — Pending and Cancelled bookings have none), any **Reviews**, and any **DiscountCoupons** redeemed against it.

The `ServiceType` column on `Bookings` is redundant with the bridges — it records directly what the bridge tables imply — but it makes filtering by service a single-table operation instead of a five-way check.
