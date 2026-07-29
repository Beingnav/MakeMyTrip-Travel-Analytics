-- ============================================================================
-- MakeMyTrip — Schema (DDL)
-- ----------------------------------------------------------------------------
-- Travel-booking database: flights, hotels, buses, trains, car rentals.
-- 15 tables in four roles:
--   Dimensions  Users, Flights, Hotels, Buses, Trains, CarRentals
--   Core fact   Bookings (one row per booking)
--   Bridges     FlightBookings ... CarRentalBookings (booking <-> service)
--   Facts       Payments, DiscountCoupons, Reviews
--
-- Written for SQLite. For MySQL / PostgreSQL see notes at the bottom of README.
-- Load order matters because of the foreign keys — dimensions first, then
-- Bookings, then everything that references a booking.
-- ============================================================================

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS Reviews;
DROP TABLE IF EXISTS DiscountCoupons;
DROP TABLE IF EXISTS Payments;
DROP TABLE IF EXISTS CarRentalBookings;
DROP TABLE IF EXISTS TrainBookings;
DROP TABLE IF EXISTS BusBookings;
DROP TABLE IF EXISTS HotelBookings;
DROP TABLE IF EXISTS FlightBookings;
DROP TABLE IF EXISTS Bookings;
DROP TABLE IF EXISTS CarRentals;
DROP TABLE IF EXISTS Trains;
DROP TABLE IF EXISTS Buses;
DROP TABLE IF EXISTS Hotels;
DROP TABLE IF EXISTS Flights;
DROP TABLE IF EXISTS Users;

-- ---------- Dimensions -------------------------------------------------------

CREATE TABLE Users (
    UserID           INTEGER PRIMARY KEY,
    FirstName        TEXT    NOT NULL,
    LastName         TEXT    NOT NULL,
    Email            TEXT    NOT NULL,
    Password         TEXT,                         -- masked placeholder in source
    PhoneNumber      TEXT,
    RegistrationDate TEXT    NOT NULL              -- ISO 8601 date
);

CREATE TABLE Flights (
    FlightID          INTEGER PRIMARY KEY,
    Airline           TEXT    NOT NULL,
    DepartureAirport  TEXT    NOT NULL,
    ArrivalAirport    TEXT    NOT NULL,
    DepartureDateTime TEXT    NOT NULL,
    ArrivalDateTime   TEXT    NOT NULL,
    Price             REAL    NOT NULL CHECK (Price >= 0),
    AvailableSeats    INTEGER NOT NULL CHECK (AvailableSeats >= 0)
);

CREATE TABLE Hotels (
    HotelID          INTEGER PRIMARY KEY,
    Name             TEXT    NOT NULL,
    Location         TEXT    NOT NULL,
    CheckInDateTime  TEXT    NOT NULL,
    CheckOutDateTime TEXT    NOT NULL,
    PricePerNight    REAL    NOT NULL CHECK (PricePerNight >= 0),
    AvailableRooms   INTEGER NOT NULL CHECK (AvailableRooms >= 0)
);

CREATE TABLE Buses (
    BusID             INTEGER PRIMARY KEY,
    Operator          TEXT    NOT NULL,
    DepartureLocation TEXT    NOT NULL,
    ArrivalLocation   TEXT    NOT NULL,
    DepartureDateTime TEXT    NOT NULL,
    ArrivalDateTime   TEXT    NOT NULL,
    Price             REAL    NOT NULL CHECK (Price >= 0),
    AvailableSeats    INTEGER NOT NULL CHECK (AvailableSeats >= 0)
);

CREATE TABLE Trains (
    TrainID           INTEGER PRIMARY KEY,
    Operator          TEXT    NOT NULL,
    DepartureStation  TEXT    NOT NULL,
    ArrivalStation    TEXT    NOT NULL,
    DepartureDateTime TEXT    NOT NULL,
    ArrivalDateTime   TEXT    NOT NULL,
    Price             REAL    NOT NULL CHECK (Price >= 0),
    AvailableSeats    INTEGER NOT NULL CHECK (AvailableSeats >= 0)
);

CREATE TABLE CarRentals (
    CarRentalID     INTEGER PRIMARY KEY,
    CarType         TEXT NOT NULL,
    PickupLocation  TEXT NOT NULL,
    DropOffLocation TEXT NOT NULL,
    PickupDateTime  TEXT NOT NULL,
    DropOffDateTime TEXT NOT NULL,
    Price           REAL NOT NULL CHECK (Price >= 0)
);

-- ---------- Core fact --------------------------------------------------------

CREATE TABLE Bookings (
    BookingID       INTEGER PRIMARY KEY,
    UserID          INTEGER NOT NULL,
    BookingDateTime TEXT    NOT NULL,
    TotalPrice      REAL    NOT NULL CHECK (TotalPrice >= 0),
    Status          TEXT    NOT NULL
                     CHECK (Status IN ('Pending','Confirmed','Completed','Cancelled','Refunded')),
    ServiceType     TEXT    NOT NULL
                     CHECK (ServiceType IN ('Flight','Hotel','Bus','Train','CarRental')),
    FOREIGN KEY (UserID) REFERENCES Users (UserID)
);

-- ---------- Bridges ----------------------------------------------------------

CREATE TABLE FlightBookings (
    FlightBookingID INTEGER PRIMARY KEY,
    BookingID       INTEGER NOT NULL,
    FlightID        INTEGER NOT NULL,
    Passengers      INTEGER NOT NULL CHECK (Passengers > 0),
    FOREIGN KEY (BookingID) REFERENCES Bookings (BookingID),
    FOREIGN KEY (FlightID)  REFERENCES Flights  (FlightID)
);

CREATE TABLE HotelBookings (
    HotelBookingID INTEGER PRIMARY KEY,
    BookingID      INTEGER NOT NULL,
    HotelID        INTEGER NOT NULL,
    NumberOfRooms  INTEGER NOT NULL CHECK (NumberOfRooms > 0),
    FOREIGN KEY (BookingID) REFERENCES Bookings (BookingID),
    FOREIGN KEY (HotelID)   REFERENCES Hotels   (HotelID)
);

CREATE TABLE BusBookings (
    BusBookingID INTEGER PRIMARY KEY,
    BookingID    INTEGER NOT NULL,
    BusID        INTEGER NOT NULL,
    Passengers   INTEGER NOT NULL CHECK (Passengers > 0),
    FOREIGN KEY (BookingID) REFERENCES Bookings (BookingID),
    FOREIGN KEY (BusID)     REFERENCES Buses    (BusID)
);

CREATE TABLE TrainBookings (
    TrainBookingID INTEGER PRIMARY KEY,
    BookingID      INTEGER NOT NULL,
    TrainID        INTEGER NOT NULL,
    Passengers     INTEGER NOT NULL CHECK (Passengers > 0),
    FOREIGN KEY (BookingID) REFERENCES Bookings (BookingID),
    FOREIGN KEY (TrainID)   REFERENCES Trains   (TrainID)
);

CREATE TABLE CarRentalBookings (
    CarRentalBookingID INTEGER PRIMARY KEY,
    BookingID          INTEGER NOT NULL,
    CarRentalID        INTEGER NOT NULL,
    FOREIGN KEY (BookingID)   REFERENCES Bookings   (BookingID),
    FOREIGN KEY (CarRentalID) REFERENCES CarRentals (CarRentalID)
);

-- ---------- Satellite facts --------------------------------------------------

CREATE TABLE Payments (
    PaymentID     INTEGER PRIMARY KEY,
    BookingID     INTEGER NOT NULL,
    PaymentType   TEXT    NOT NULL
                   CHECK (PaymentType IN
                     ('UPI','Credit Card','Debit Card','Net Banking','Wallet','EMI')),
    PaymentDate   TEXT    NOT NULL,
    PaymentAmount REAL    NOT NULL CHECK (PaymentAmount >= 0),
    FOREIGN KEY (BookingID) REFERENCES Bookings (BookingID)
);

CREATE TABLE DiscountCoupons (
    CouponID          INTEGER PRIMARY KEY,
    Code              TEXT    NOT NULL,
    DiscountPercent   INTEGER NOT NULL CHECK (DiscountPercent BETWEEN 0 AND 100),
    MinimumOrderValue INTEGER,
    ExpiryDate        TEXT,
    BookingID         INTEGER NOT NULL,
    FOREIGN KEY (BookingID) REFERENCES Bookings (BookingID)
);

CREATE TABLE Reviews (
    ReviewID   INTEGER PRIMARY KEY,
    UserID     INTEGER NOT NULL,
    BookingID  INTEGER NOT NULL,
    Rating     INTEGER NOT NULL CHECK (Rating BETWEEN 1 AND 5),
    Comment    TEXT,
    ReviewDate TEXT    NOT NULL,
    FOREIGN KEY (UserID)    REFERENCES Users    (UserID),
    FOREIGN KEY (BookingID) REFERENCES Bookings (BookingID)
);

-- ---------- Indexes on the foreign keys we join on most ---------------------

CREATE INDEX idx_bookings_user      ON Bookings (UserID);
CREATE INDEX idx_bookings_status    ON Bookings (Status);
CREATE INDEX idx_bookings_service   ON Bookings (ServiceType);
CREATE INDEX idx_payments_booking   ON Payments (BookingID);
CREATE INDEX idx_reviews_booking    ON Reviews (BookingID);
CREATE INDEX idx_coupons_booking    ON DiscountCoupons (BookingID);
CREATE INDEX idx_flightb_booking    ON FlightBookings (BookingID);
CREATE INDEX idx_hotelb_booking     ON HotelBookings (BookingID);
CREATE INDEX idx_busb_booking       ON BusBookings (BookingID);
CREATE INDEX idx_trainb_booking     ON TrainBookings (BookingID);
CREATE INDEX idx_carb_booking       ON CarRentalBookings (BookingID);
