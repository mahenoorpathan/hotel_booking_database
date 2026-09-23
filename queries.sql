-- =====================================================================
-- Hotel Booking Database — Queries
-- Run after schema.sql and sample_data.sql
-- =====================================================================

USE hotel_booking;

-- =====================================================================
-- PART A: CRUD OPERATIONS
-- =====================================================================

-- CREATE: register a new guest (user account + guest profile)
INSERT INTO users (username, email, password_hash, role)
VALUES ('mpatel', 'mpatel@example.com',
        '$2b$12$GuestPlaceholderHashValue9999999999999999999999999999', 'guest');

INSERT INTO guests (user_id, first_name, last_name, phone, city, country)
VALUES (LAST_INSERT_ID(), 'Meera', 'Patel', '416-555-0107', 'Toronto', 'Canada');

-- READ: look up a guest's profile by email
SELECT  g.guest_id, g.first_name, g.last_name, g.phone, u.email
FROM    guests g
JOIN    users  u ON g.user_id = u.user_id
WHERE   u.email = 'mpatel@example.com';

-- UPDATE: guest changes their phone number
UPDATE  guests
SET     phone = '416-555-0199'
WHERE   guest_id = 7;

-- UPDATE: cancel a booking (the trigger writes this to audit_log)
UPDATE  bookings
SET     status = 'cancelled'
WHERE   booking_id = 6;

-- DELETE: remove a room type that has no rooms assigned
INSERT INTO room_types (type_name, description, nightly_rate, max_occupancy)
VALUES ('Penthouse', 'Temporary test type', 999.00, 4);

DELETE FROM room_types
WHERE  type_name = 'Penthouse'
AND    type_id NOT IN (SELECT type_id FROM rooms);


-- =====================================================================
-- PART B: JOIN QUERIES
-- =====================================================================

-- 1. Every booking with guest name, room, and room type
SELECT  b.booking_id,
        CONCAT(g.first_name, ' ', g.last_name) AS guest_name,
        r.room_number,
        rt.type_name,
        b.check_in,
        b.check_out,
        b.status
FROM    bookings   b
INNER JOIN guests     g  ON b.guest_id = g.guest_id
INNER JOIN rooms      r  ON b.room_id  = r.room_id
INNER JOIN room_types rt ON r.type_id  = rt.type_id
ORDER BY b.check_in;

-- 2. Bookings with their payment status (LEFT JOIN keeps unpaid bookings)
SELECT  b.booking_id,
        b.total_amount,
        COALESCE(p.status, 'no payment')   AS payment_status,
        p.method
FROM    bookings b
LEFT JOIN payments p ON b.booking_id = p.booking_id
WHERE   b.status <> 'cancelled'
ORDER BY b.booking_id;

-- 3. Guests who have never made a booking
SELECT  g.guest_id, g.first_name, g.last_name
FROM    guests g
LEFT JOIN bookings b ON g.guest_id = b.guest_id
WHERE   b.booking_id IS NULL;

-- 4. Rooms currently occupied (checked-in guests)
SELECT * FROM vw_booking_summary
WHERE  status = 'checked_in';


-- =====================================================================
-- PART C: BUSINESS / REPORTING QUERIES
-- =====================================================================

-- 5. Available rooms for a date range (no overlapping active booking)
--    Two stays overlap when: existing.check_in < new_check_out
--                        AND existing.check_out > new_check_in
SET @new_in  = '2026-10-02';
SET @new_out = '2026-10-05';

SELECT  r.room_number, rt.type_name, rt.nightly_rate, rt.max_occupancy
FROM    rooms r
JOIN    room_types rt ON r.type_id = rt.type_id
WHERE   r.status = 'available'
AND     r.room_id NOT IN (
            SELECT b.room_id
            FROM   bookings b
            WHERE  b.status IN ('confirmed', 'checked_in')
            AND    b.check_in  < @new_out
            AND    b.check_out > @new_in
        )
ORDER BY rt.nightly_rate;

-- 6. Revenue by room type (completed payments only)
SELECT  rt.type_name,
        COUNT(p.payment_id)  AS paid_bookings,
        SUM(p.amount)        AS revenue
FROM    payments   p
JOIN    bookings   b  ON p.booking_id = b.booking_id
JOIN    rooms      r  ON b.room_id    = r.room_id
JOIN    room_types rt ON r.type_id    = rt.type_id
WHERE   p.status = 'completed'
GROUP BY rt.type_name
ORDER BY revenue DESC;

-- 7. Repeat guests (more than one non-cancelled booking)
SELECT  CONCAT(g.first_name, ' ', g.last_name) AS guest_name,
        COUNT(*) AS total_bookings
FROM    bookings b
JOIN    guests   g ON b.guest_id = g.guest_id
WHERE   b.status <> 'cancelled'
GROUP BY g.guest_id, g.first_name, g.last_name
HAVING  COUNT(*) > 1;


-- =====================================================================
-- PART D: SECURITY & AUDIT QUERIES
-- =====================================================================

-- 8. Login / logout history for all users
SELECT  a.action_time, u.username, u.role, a.action, a.details
FROM    audit_log a
LEFT JOIN users u ON a.user_id = u.user_id
WHERE   a.action IN ('LOGIN_SUCCESS', 'LOGIN_FAILED', 'LOGOUT')
ORDER BY a.action_time;

-- 9. Possible brute-force attempts: 3+ failed logins by one account
SELECT  u.username,
        COUNT(*)            AS failed_attempts,
        MIN(a.action_time)  AS first_attempt,
        MAX(a.action_time)  AS last_attempt
FROM    audit_log a
JOIN    users     u ON a.user_id = u.user_id
WHERE   a.action = 'LOGIN_FAILED'
GROUP BY u.username
HAVING  COUNT(*) >= 3;

-- 10. Lock accounts with 5 or more failed logins
UPDATE  users
SET     is_active = FALSE
WHERE   failed_logins >= 5;

SELECT username, failed_logins, is_active
FROM   users
WHERE  is_active = FALSE;

-- 11. Privileged accounts review (admins and staff)
SELECT  username, email, role, is_active, last_login
FROM    users
WHERE   role IN ('admin', 'staff')
ORDER BY role, username;

-- 12. Change history from the audit trigger
SELECT  action_time, table_name, record_id, details
FROM    audit_log
WHERE   action = 'UPDATE'
ORDER BY action_time DESC;
