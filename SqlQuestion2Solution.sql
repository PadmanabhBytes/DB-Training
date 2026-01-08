-- ==========================================
-- 1. INDEPENDENT ENTITIES
-- ==========================================

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(50) DEFAULT 'attendee', -- admin, organizer, attendee
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE venues (
    venue_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    capacity INTEGER NOT NULL
);

-- Handling Multivalued Attribute: Venue Amenities (Double Oval)
CREATE TABLE venue_amenities (
    amenity_id SERIAL PRIMARY KEY,
    venue_id INTEGER REFERENCES venues(venue_id) ON DELETE CASCADE,
    amenity_name VARCHAR(100) NOT NULL -- e.g., 'WiFi', 'Parking'
);

CREATE TABLE speakers (
    speaker_id SERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    bio TEXT
);

CREATE TABLE promotions (
    promo_code VARCHAR(50) PRIMARY KEY, -- Using Code as PK
    type VARCHAR(20) CHECK (type IN ('percent', 'fixed')),
    value DECIMAL(10, 2) NOT NULL
);

-- ==========================================
-- 2. CORE LOGIC (Events & Logistics)
-- ==========================================

CREATE TABLE events (
    event_id SERIAL PRIMARY KEY,
    organizer_id INTEGER REFERENCES users(user_id), -- Relationship: Organizes
    venue_id INTEGER REFERENCES venues(venue_id),   -- Relationship: Hosted At
    category_id INTEGER REFERENCES categories(category_id), -- Relationship: Is Type
    title VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'draft',
    start_time TIMESTAMP NOT NULL
);

-- Handling Multivalued Attribute: Event Tags (Double Oval)
CREATE TABLE event_tags (
    tag_id SERIAL PRIMARY KEY,
    event_id INTEGER REFERENCES events(event_id) ON DELETE CASCADE,
    tag_name VARCHAR(50) NOT NULL -- e.g., 'Tech', 'Networking'
);

-- Relationship: Features (M:N between Event and Speaker)
CREATE TABLE event_speakers (
    event_id INTEGER REFERENCES events(event_id) ON DELETE CASCADE,
    speaker_id INTEGER REFERENCES speakers(speaker_id) ON DELETE CASCADE,
    PRIMARY KEY (event_id, speaker_id)
);

-- Relationship: Has (1:N)
CREATE TABLE ticket_tiers (
    tier_id SERIAL PRIMARY KEY,
    event_id INTEGER REFERENCES events(event_id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    qty_total INTEGER NOT NULL,
    qty_available INTEGER NOT NULL
);

-- ==========================================
-- 3. SALES & TRANSACTIONS
-- ==========================================

CREATE TABLE bookings (
    booking_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id), -- Relationship: Makes
    status VARCHAR(50) DEFAULT 'pending', -- pending, confirmed, cancelled
    total_price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Relationship: Applied To (M:N - A booking might use a promo)
-- Note: Simplified to 1:N if only one code allowed per booking, 
-- but represented here as a link table for flexibility.
CREATE TABLE booking_promotions (
    booking_id INTEGER REFERENCES bookings(booking_id),
    promo_code VARCHAR(50) REFERENCES promotions(promo_code),
    applied_amount DECIMAL(10, 2),
    PRIMARY KEY (booking_id, promo_code)
);

CREATE TABLE tickets (
    ticket_id SERIAL PRIMARY KEY,
    booking_id INTEGER REFERENCES bookings(booking_id), -- Relationship: Contains
    tier_id INTEGER REFERENCES ticket_tiers(tier_id),
    attendee_name VARCHAR(255),
    qr_code VARCHAR(255) UNIQUE
);

CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    booking_id INTEGER REFERENCES bookings(booking_id), -- Relationship: Generates
    provider VARCHAR(50), -- stripe, paypal
    amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) -- success, failed
);

-- ==========================================
-- 4. GROWTH MODULE (Waitlists & Reviews)
-- ==========================================

CREATE TABLE waitlists (
    waitlist_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id),
    tier_id INTEGER REFERENCES ticket_tiers(tier_id), -- Relationship: Queued For
    status VARCHAR(50) DEFAULT 'waiting', -- waiting, notified, converted
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reviews (
    review_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id),
    booking_id INTEGER REFERENCES bookings(booking_id), -- Relationship: Rates (Link to Booking for verification)
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);