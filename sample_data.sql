-- =====================================================================
-- Hotel Booking Database — Sample Data
-- All names, emails, and phone numbers are fictional.
-- Password hashes are placeholder bcrypt-style strings, not real ones.
-- =====================================================================

USE hotel_booking;

-- Users (1 admin, 2 staff, 6 guests)
INSERT INTO users (username, email, password_hash, role, last_login) VALUES
('admin01',   'admin@examplehotel.com',   '$2b$12$AdminPlaceholderHashValue0000000000000000000000000000', 'admin', '2026-09-20 09:15:00'),
('frontdesk1','desk1@examplehotel.com',   '$2b$12$StaffPlaceholderHashValue1111111111111111111111111111', 'staff', '2026-09-21 08:02:00'),
('frontdesk2','desk2@examplehotel.com',   '$2b$12$StaffPlaceholderHashValue2222222222222222222222222222', 'staff', '2026-09-21 16:05:00'),
('aroy',      'aroy@example.com',         '$2b$12$GuestPlaceholderHashValue3333333333333333333333333333', 'guest', '2026-09-10 19:40:00'),
('jchen',     'jchen@example.com',        '$2b$12$GuestPlaceholderHashValue4444444444444444444444444444', 'guest', '2026-09-12 11:22:00'),
('smartin',   'smartin@example.com',      '$2b$12$GuestPlaceholderHashValue5555555555555555555555555555', 'guest', '2026-09-14 20:10:00'),
('pkaur',     'pkaur@example.com',        '$2b$12$GuestPlaceholderHashValue6666666666666666666666666666', 'guest', NULL),
('dnguyen',   'dnguyen@example.com',      '$2b$12$GuestPlaceholderHashValue7777777777777777777777777777', 'guest', '2026-09-18 13:55:00'),
('lsilva',    'lsilva@example.com',       '$2b$12$GuestPlaceholderHashValue8888888888888888888888888888', 'guest', '2026-09-19 07:30:00');

-- Guest profiles (linked to guest-role users 4–9)
INSERT INTO guests (user_id, first_name, last_name, phone, city, country) VALUES
(4, 'Anika',  'Roy',     '416-555-0101', 'Toronto',   'Canada'),
(5, 'James',  'Chen',    '604-555-0102', 'Vancouver', 'Canada'),
(6, 'Sophie', 'Martin',  '514-555-0103', 'Montreal',  'Canada'),
(7, 'Priya',  'Kaur',    '905-555-0104', 'Brampton',  'Canada'),
(8, 'David',  'Nguyen',  '212-555-0105', 'New York',  'USA'),
(9, 'Lucas',  'Silva',   '647-555-0106', 'Toronto',   'Canada');

-- Room types
INSERT INTO room_types (type_name, description, nightly_rate, max_occupancy) VALUES
('Standard', 'Queen bed, city view',             149.00, 2),
('Deluxe',   'King bed, lake view, work desk',   219.00, 2),
('Family',   'Two queen beds, sofa bed',         259.00, 5),
('Suite',    'Separate living area, king bed',   389.00, 3);

-- Rooms
INSERT INTO rooms (room_number, type_id, floor, status) VALUES
('101', 1, 1, 'available'),
('102', 1, 1, 'available'),
('103', 1, 1, 'maintenance'),
('201', 2, 2, 'available'),
('202', 2, 2, 'available'),
('301', 3, 3, 'available'),
('302', 3, 3, 'available'),
('401', 4, 4, 'available');

-- Bookings (total_amount = nights x nightly rate)
INSERT INTO bookings (guest_id, room_id, check_in, check_out, num_guests, status, total_amount) VALUES
(1, 1, '2026-09-05', '2026-09-08', 2, 'checked_out',  447.00),  -- Standard, 3 nights
(2, 4, '2026-09-10', '2026-09-12', 1, 'checked_out',  438.00),  -- Deluxe, 2 nights
(3, 6, '2026-09-20', '2026-09-24', 4, 'checked_in',  1036.00),  -- Family, 4 nights
(4, 8, '2026-09-22', '2026-09-25', 2, 'checked_in',  1167.00),  -- Suite, 3 nights
(5, 2, '2026-10-01', '2026-10-04', 1, 'confirmed',    447.00),  -- Standard, 3 nights
(6, 5, '2026-10-03', '2026-10-05', 2, 'confirmed',    438.00),  -- Deluxe, 2 nights
(1, 4, '2026-10-15', '2026-10-17', 2, 'confirmed',    438.00),  -- Deluxe, 2 nights (repeat guest)
(2, 7, '2026-09-15', '2026-09-18', 3, 'cancelled',    777.00);  -- Family, cancelled

-- Payments
INSERT INTO payments (booking_id, amount, method, card_last4, status, paid_at) VALUES
(1,  447.00, 'credit_card', '4242', 'completed', '2026-09-08 11:00:00'),
(2,  438.00, 'debit_card',  '1881', 'completed', '2026-09-12 10:30:00'),
(3, 1036.00, 'credit_card', '5100', 'completed', '2026-09-20 15:10:00'),
(4, 1167.00, 'credit_card', '3782', 'pending',   NULL),
(5,  447.00, 'credit_card', '4000', 'pending',   NULL),
(8,  777.00, 'credit_card', '4242', 'refunded',  '2026-09-14 09:00:00');

-- Audit log: login/logout activity, including repeated failed logins
INSERT INTO audit_log (user_id, action, details, action_time) VALUES
(2, 'LOGIN_SUCCESS', 'Front desk shift start',          '2026-09-21 08:02:00'),
(4, 'LOGIN_SUCCESS', NULL,                              '2026-09-10 19:40:00'),
(4, 'LOGOUT',        NULL,                              '2026-09-10 19:52:00'),
(7, 'LOGIN_FAILED',  'Incorrect password',              '2026-09-19 02:11:00'),
(7, 'LOGIN_FAILED',  'Incorrect password',              '2026-09-19 02:11:20'),
(7, 'LOGIN_FAILED',  'Incorrect password',              '2026-09-19 02:11:41'),
(7, 'LOGIN_FAILED',  'Incorrect password',              '2026-09-19 02:12:03'),
(7, 'LOGIN_FAILED',  'Incorrect password',              '2026-09-19 02:12:25'),
(1, 'LOGIN_SUCCESS', 'Admin console',                   '2026-09-20 09:15:00'),
(1, 'LOGOUT',        NULL,                              '2026-09-20 09:40:00'),
(2, 'LOGOUT',        'Front desk shift end',            '2026-09-21 16:00:00');

UPDATE users SET failed_logins = 5 WHERE user_id = 7;
