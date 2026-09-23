# 🏨 Hotel Booking Database

A relational database for a small hotel booking system, built in **MySQL**. It covers guest accounts, rooms, reservations, and payments, with **security controls built into the design**: hashed passwords, role-based accounts, data minimization for payment cards, and an audit log that tracks logins and data changes.

## 📌 What this project shows
- Relational schema design (normalization, primary/foreign keys, constraints)
- CRUD operations and multi-table `JOIN` queries
- Business reporting (room availability, revenue, repeat guests)
- Security-minded database design and audit queries

## 🗂️ Database Structure

| Table | Purpose |
|---|---|
| `users` | Login accounts with a role (`guest`, `staff`, `admin`), a password hash, and failed-login tracking |
| `guests` | Guest personal details, linked 1:1 to a user account |
| `room_types` | Room categories with nightly rate and max occupancy |
| `rooms` | Physical rooms and their current status |
| `bookings` | Reservations with check-in/check-out dates and status |
| `payments` | Payments per booking (stores **only the last 4 card digits**) |
| `audit_log` | Login, logout, failed-login, and data-change events |

**Relationships**

```
users 1───1 guests 1───* bookings *───1 rooms *───1 room_types
                              │
                              1
                              │
                              * payments

users 1───* audit_log
```

## 🔐 Security & Data Protection Features
| Control | How it's implemented |
|---|---|
| No plain-text passwords | `users.password_hash` stores only a hashed value |
| Role-based access | `role` column separates guests, front-desk staff, and admins |
| Data minimization | `payments.card_last4` stores 4 digits, never the full card number |
| Account lockout | `failed_logins` counter + query that deactivates accounts after 5 failures |
| Audit trail | `audit_log` table records logins/logouts; a **trigger** logs every booking status change |
| Least-privilege view | `vw_booking_summary` gives staff booking info without exposing hashes or payment data |
| Data integrity | `CHECK` constraints (check-out after check-in, positive amounts), `UNIQUE` usernames/emails, foreign keys |

## 🔎 Example Queries (`queries.sql`)
**CRUD:** register a guest, look up a profile, update a phone number, cancel a booking, delete an unused room type

**Joins:**
- All bookings with guest name, room, and room type (`INNER JOIN` across 4 tables)
- Bookings with payment status (`LEFT JOIN` to include unpaid bookings)
- Guests who have never booked

**Reporting:**
- Available rooms for a given date range (overlap logic)
- Revenue by room type
- Repeat guests

**Security & audit:**
- Login/logout history
- Accounts with 3+ failed logins (possible brute-force attempts)
- Locking accounts after 5 failed logins
- Review of privileged (admin/staff) accounts
- Change history captured by the trigger

## ▶️ How to Run
1. Install [MySQL 8.0+](https://dev.mysql.com/downloads/) (or use MySQL Workbench).
2. Run the files in this order:
   ```sql
   SOURCE schema.sql;
   SOURCE sample_data.sql;
   SOURCE queries.sql;
   ```

## 📁 Files
| File | Description |
|---|---|
| `schema.sql` | Creates the database, tables, constraints, index, trigger, and view |
| `sample_data.sql` | Inserts fictional users, guests, rooms, bookings, payments, and audit events |
| `queries.sql` | CRUD, join, reporting, and security/audit queries |

> All data in this project is fictional.

---
👩‍💻 **Mahenoor (Mahi) Pathan**. [LinkedIn](https://www.linkedin.com/in/mahenoor-pathan/)
