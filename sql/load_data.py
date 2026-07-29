#!/usr/bin/env python3
"""
Build makemytrip.db from the CSVs.

Usage:  python load_data.py
Creates makemytrip.db in the current folder: runs 01_schema.sql, loads all 15
CSVs in FK-safe order, then runs 02_views.sql. Re-run any time — it rebuilds
from scratch.
"""
import csv, sqlite3, sys
from pathlib import Path

HERE = Path(__file__).parent
DB   = HERE / "makemytrip.db"
DATA = HERE / "data"

# FK-safe load order: dimensions, then Bookings, then children of Bookings.
LOAD_ORDER = [
    "Users", "Flights", "Hotels", "Buses", "Trains", "CarRentals",
    "Bookings",
    "FlightBookings", "HotelBookings", "BusBookings", "TrainBookings", "CarRentalBookings",
    "Payments", "DiscountCoupons", "Reviews",
]
# integer columns get cast so they store as INTEGER, not TEXT
INT_COLS = {
    "UserID","FlightID","HotelID","BusID","TrainID","CarRentalID","BookingID",
    "FlightBookingID","HotelBookingID","BusBookingID","TrainBookingID","CarRentalBookingID",
    "PaymentID","CouponID","ReviewID","Passengers","NumberOfRooms","AvailableSeats",
    "AvailableRooms","Rating","DiscountPercent","MinimumOrderValue",
}
REAL_COLS = {"Price","TotalPrice","PricePerNight","PaymentAmount"}

def cast(col, val):
    if val == "" or val is None:
        return None
    if col in INT_COLS:
        try: return int(float(val))
        except ValueError: return val
    if col in REAL_COLS:
        try: return float(val)
        except ValueError: return val
    return val

def run_script(cur, path):
    cur.executescript(Path(path).read_text(encoding="utf-8"))

def load_table(cur, name):
    f = DATA / f"{name}.csv"
    with open(f, newline="", encoding="utf-8") as fh:
        rdr = csv.reader(fh)
        header = next(rdr)
        cols = ",".join(f'"{c}"' for c in header)
        ph   = ",".join("?" * len(header))
        rows = ([cast(header[i], v) for i, v in enumerate(r)] for r in rdr)
        cur.executemany(f'INSERT INTO {name} ({cols}) VALUES ({ph})', rows)
    return cur.execute(f"SELECT COUNT(*) FROM {name}").fetchone()[0]

def main():
    if DB.exists(): DB.unlink()
    con = sqlite3.connect(DB)
    cur = con.cursor()
    cur.execute("PRAGMA foreign_keys = ON")

    print("Creating schema ...")
    run_script(cur, HERE / "01_schema.sql")

    print("Loading tables ...")
    total = 0
    for name in LOAD_ORDER:
        n = load_table(cur, name)
        total += n
        print(f"  {name:<20} {n:>5} rows")
    con.commit()

    print("Creating views ...")
    run_script(cur, HERE / "02_views.sql")
    con.commit()

    # integrity: FK check should return nothing
    violations = cur.execute("PRAGMA foreign_key_check").fetchall()
    print(f"\nLoaded {total:,} rows across {len(LOAD_ORDER)} tables.")
    print("Foreign-key violations:", len(violations) if violations else 0)
    if violations:
        print("  !", violations[:5]); sys.exit(1)

    con.close()
    print(f"Done -> {DB}")

if __name__ == "__main__":
    main()
