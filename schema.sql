-- =====================================================================
-- Hotel Booking Database — Schema
-- Target: MySQL 8.0+
-- Description: Relational schema for a small hotel booking system,
--              with user accounts, role-based access, bookings,
--              payments, and an audit log for security events.
-- =====================================================================

DROP DATABASE IF EXISTS hotel_booking;
CREATE DATABASE hotel_booking;
USE hotel_booking;

-- ---------------------------------------------------------------------
-- 1. users — login accounts (guests, front-desk staff, admins)
--    Passwords are never stored in plain text; only a hash is kept.
-- ---------------------------------------------------------------------
CREATE TABLE users (
    user_id        INT AUTO_INCREMENT PRIMARY KEY,
    username       VARCHAR(50)  NOT NULL UNIQUE,
    email          VARCHAR(100) NOT NULL UNIQUE,
    password_hash  VARCHAR(255) NOT NULL,
    role           ENUM('guest', 'staff', 'admin') NOT NULL DEFAULT 'guest',
    is_active      BOOLEAN      NOT NULL DEFAULT TRUE,
    failed_logins  INT          NOT NULL DEFAULT 0,
    last_login     DATETIME     NULL,
    created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------
-- 2. guests — personal details, linked 1:1 to a user account
-- ---------------------------------------------------------------------
CREATE TABLE guests (
    guest_id       INT AUTO_INCREMENT PRIMARY KEY,
    user_id        INT          NOT NULL UNIQUE,
    first_name     VARCHAR(50)  NOT NULL,
    last_name      VARCHAR(50)  NOT NULL,
    phone          VARCHAR(20)  NULL,
    city           VARCHAR(50)  NULL,
    country        VARCHAR(50)  NULL,
    CONSTRAINT fk_guests_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- 3. room_types — categories of rooms and their nightly price
-- ---------------------------------------------------------------------
CREATE TABLE room_types (
    type_id        INT AUTO_INCREMENT PRIMARY KEY,
    type_name      VARCHAR(50)   NOT NULL UNIQUE,
    description    VARCHAR(255)  NULL,
    nightly_rate   DECIMAL(8,2)  NOT NULL,
    max_occupancy  INT           NOT NULL,
    CONSTRAINT chk_rate_positive      CHECK (nightly_rate > 0),
    CONSTRAINT chk_occupancy_positive CHECK (max_occupancy > 0)
);

-- ---------------------------------------------------------------------
-- 4. rooms — physical rooms in the hotel
-- ---------------------------------------------------------------------
CREATE TABLE rooms (
    room_id        INT AUTO_INCREMENT PRIMARY KEY,
    room_number    VARCHAR(10)  NOT NULL UNIQUE,
    type_id        INT          NOT NULL,
    floor          INT          NOT NULL,
    status         ENUM('available', 'maintenance', 'out_of_service')
                                NOT NULL DEFAULT 'available',
    CONSTRAINT fk_rooms_type
        FOREIGN KEY (type_id) REFERENCES room_types(type_id)
);

-- ---------------------------------------------------------------------
-- 5. bookings — reservations made by guests
-- ---------------------------------------------------------------------
CREATE TABLE bookings (
    booking_id     INT AUTO_INCREMENT PRIMARY KEY,
    guest_id       INT           NOT NULL,
    room_id        INT           NOT NULL,
    check_in       DATE          NOT NULL,
    check_out      DATE          NOT NULL,
    num_guests     INT           NOT NULL DEFAULT 1,
    status         ENUM('confirmed', 'checked_in', 'checked_out', 'cancelled')
                                 NOT NULL DEFAULT 'confirmed',
    total_amount   DECIMAL(10,2) NOT NULL,
    created_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_bookings_guest
        FOREIGN KEY (guest_id) REFERENCES guests(guest_id),
    CONSTRAINT fk_bookings_room
        FOREIGN KEY (room_id)  REFERENCES rooms(room_id),
    CONSTRAINT chk_dates_valid  CHECK (check_out > check_in),
    CONSTRAINT chk_guests_valid CHECK (num_guests > 0)
);

-- Speeds up availability searches (room + date range)
CREATE INDEX idx_bookings_room_dates ON bookings (room_id, check_in, check_out);

-- ---------------------------------------------------------------------
-- 6. payments — payments against bookings
--    Only the last 4 digits of a card are stored (never the full number).
-- ---------------------------------------------------------------------
CREATE TABLE payments (
    payment_id     INT AUTO_INCREMENT PRIMARY KEY,
    booking_id     INT           NOT NULL,
    amount         DECIMAL(10,2) NOT NULL,
    method         ENUM('credit_card', 'debit_card', 'cash') NOT NULL,
    card_last4     CHAR(4)       NULL,
    status         ENUM('pending', 'completed', 'refunded') NOT NULL DEFAULT 'pending',
    paid_at        DATETIME      NULL,
    CONSTRAINT fk_payments_booking
        FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
    CONSTRAINT chk_amount_positive CHECK (amount > 0)
);

-- ---------------------------------------------------------------------
-- 7. audit_log — records logins, logouts, and data changes
-- ---------------------------------------------------------------------
CREATE TABLE audit_log (
    log_id         INT AUTO_INCREMENT PRIMARY KEY,
    user_id        INT          NULL,
    action         ENUM('LOGIN_SUCCESS', 'LOGIN_FAILED', 'LOGOUT',
                        'INSERT', 'UPDATE', 'DELETE') NOT NULL,
    table_name     VARCHAR(50)  NULL,
    record_id      INT          NULL,
    details        VARCHAR(255) NULL,
    action_time    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE SET NULL
);

-- ---------------------------------------------------------------------
-- Trigger: automatically log every booking status change
-- ---------------------------------------------------------------------
DELIMITER //
CREATE TRIGGER trg_booking_status_change
AFTER UPDATE ON bookings
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        INSERT INTO audit_log (user_id, action, table_name, record_id, details)
        VALUES (NULL, 'UPDATE', 'bookings', NEW.booking_id,
                CONCAT('Status changed from ', OLD.status, ' to ', NEW.status));
    END IF;
END //
DELIMITER ;

-- ---------------------------------------------------------------------
-- View: front-desk booking summary
-- Shows only what staff need — no password hashes or payment details.
-- ---------------------------------------------------------------------
CREATE VIEW vw_booking_summary AS
SELECT  b.booking_id,
        CONCAT(g.first_name, ' ', g.last_name) AS guest_name,
        r.room_number,
        rt.type_name,
        b.check_in,
        b.check_out,
        DATEDIFF(b.check_out, b.check_in)       AS nights,
        b.num_guests,
        b.status
FROM    bookings   b
JOIN    guests     g  ON b.guest_id = g.guest_id
JOIN    rooms      r  ON b.room_id  = r.room_id
JOIN    room_types rt ON r.type_id  = rt.type_id;
