-- =========================================
-- Dream Homes NYC - Improved SQL Schema
-- PostgreSQL version
-- =========================================

-- 1. Offices
CREATE TABLE Offices (
    office_id INT PRIMARY KEY,
    office_name VARCHAR(50) NOT NULL,
    state CHAR(2) NOT NULL CHECK (state IN ('NJ', 'NY', 'CT')),
    city VARCHAR(50) NOT NULL,
    street_address VARCHAR(100) NOT NULL,
    zip_code VARCHAR(10) NOT NULL,
    phone_number VARCHAR(20),
    office_rent DECIMAL(10,2) CHECK (office_rent >= 0)
);

-- 2. Neighbourhoods
CREATE TABLE Neighbourhoods (
    neighbourhood_id INT PRIMARY KEY,
    neighbourhood_name VARCHAR(100),
    school_zone VARCHAR(100),
    is_near_public_transit BOOLEAN NOT NULL,
    is_pet_friendly BOOLEAN NOT NULL,
    has_children_playground BOOLEAN NOT NULL
);

-- 3. Agents
CREATE TABLE Agents (
    agent_id INT PRIMARY KEY,
    office_id INT NOT NULL,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    email VARCHAR(50) UNIQUE,
    phone VARCHAR(30),
    hire_date DATE,
    license_number VARCHAR(20) UNIQUE,
    base_salary DECIMAL(10,2) CHECK (base_salary >= 0),
    CONSTRAINT fk_agents_office
        FOREIGN KEY (office_id) REFERENCES Offices(office_id)
);

-- 4. Clients
CREATE TABLE Clients (
    client_id INT PRIMARY KEY,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    email VARCHAR(50) UNIQUE,
    phone VARCHAR(30),
    registration_date DATE NOT NULL
);

-- 5. Properties
CREATE TABLE Properties (
    property_id INT PRIMARY KEY,
    property_type VARCHAR(20) NOT NULL CHECK (
        property_type IN ('House', 'Condo', 'Apartment', 'Townhouse', 'Commercial')
    ),
    street_address VARCHAR(100) NOT NULL,
    city VARCHAR(30) NOT NULL,
    state CHAR(2) NOT NULL CHECK (state IN ('NJ', 'NY', 'CT')),
    neighbourhood_id INT,
    bedrooms INT CHECK (bedrooms >= 0),
    bathrooms INT CHECK (bathrooms >= 0),
    square_feet INT CHECK (square_feet >= 0),
    year_built INT CHECK (year_built >= 1800),
    current_status VARCHAR(20) NOT NULL CHECK (
        current_status IN ('Available', 'Under Contract', 'Sold', 'Rented', 'Off Market')
    ),
    CONSTRAINT fk_properties_neighbourhood
        FOREIGN KEY (neighbourhood_id) REFERENCES Neighbourhoods(neighbourhood_id)
);

-- 6. Appointments
CREATE TABLE Appointments (
    appointment_id INT PRIMARY KEY,
    office_id INT NOT NULL,
    property_id INT NOT NULL,
    appointment_type VARCHAR(30) NOT NULL CHECK (
        appointment_type IN ('Viewing', 'Consultation', 'Follow-up')
    ),
    status VARCHAR(20) NOT NULL CHECK (
        status IN ('Scheduled', 'Completed', 'Cancelled')
    ),
    notes TEXT,
    CONSTRAINT fk_appointments_office
        FOREIGN KEY (office_id) REFERENCES Offices(office_id),
    CONSTRAINT fk_appointments_property
        FOREIGN KEY (property_id) REFERENCES Properties(property_id)
);

-- 7. Listings
CREATE TABLE Listings (
    listing_id INT PRIMARY KEY,
    property_id INT NOT NULL,
    agent_id INT NOT NULL,
    listing_type VARCHAR(20) NOT NULL CHECK (
        listing_type IN ('Sale', 'Rent')
    ),
    start_date DATE NOT NULL,
    end_date DATE,
    listing_status VARCHAR(20) NOT NULL CHECK (
        listing_status IN ('Active', 'Pending', 'Closed', 'Expired', 'Cancelled')
    ),
    last_updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_listing_dates
        CHECK (end_date IS NULL OR end_date >= start_date),
    CONSTRAINT fk_listings_property
        FOREIGN KEY (property_id) REFERENCES Properties(property_id),
    CONSTRAINT fk_listings_agent
        FOREIGN KEY (agent_id) REFERENCES Agents(agent_id)
);

-- 8. OpenHouses
CREATE TABLE OpenHouses (
    open_house_id INT PRIMARY KEY,
    hosting_agent_id INT NOT NULL,
    property_id INT NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    cost DECIMAL(10,2) CHECK (cost >= 0),
    notes VARCHAR(255),
    CONSTRAINT chk_openhouse_time
        CHECK (end_time > start_time),
    CONSTRAINT fk_openhouses_agent
        FOREIGN KEY (hosting_agent_id) REFERENCES Agents(agent_id),
    CONSTRAINT fk_openhouses_property
        FOREIGN KEY (property_id) REFERENCES Properties(property_id)
);

-- 9. Transactions
CREATE TABLE Transactions (
    transaction_id INT PRIMARY KEY,
    listing_id INT NOT NULL,
    transaction_type VARCHAR(20) NOT NULL CHECK (
        transaction_type IN ('Sale', 'Rent')
    ),
    transaction_status VARCHAR(20) NOT NULL CHECK (
        transaction_status IN ('Pending', 'Completed', 'Cancelled')
    ),
    contract_date DATE,
    closing_date DATE,
    final_price DECIMAL(12,2) CHECK (final_price >= 0),
    notes VARCHAR(255),
    CONSTRAINT chk_transaction_dates
        CHECK (
            closing_date IS NULL
            OR contract_date IS NULL
            OR closing_date >= contract_date
        ),
    CONSTRAINT fk_transactions_listing
        FOREIGN KEY (listing_id) REFERENCES Listings(listing_id)
);

-- 10. PropertyOwners
CREATE TABLE PropertyOwners (
    property_owner_id INT PRIMARY KEY,
    property_id INT NOT NULL,
    client_id INT NOT NULL,
    ownership_start_date DATE NOT NULL,
    ownership_end_date DATE,
    is_current_owner BOOLEAN NOT NULL,
    CONSTRAINT chk_ownership_dates
        CHECK (
            ownership_end_date IS NULL
            OR ownership_end_date >= ownership_start_date
        ),
    CONSTRAINT fk_propertyowners_property
        FOREIGN KEY (property_id) REFERENCES Properties(property_id),
    CONSTRAINT fk_propertyowners_client
        FOREIGN KEY (client_id) REFERENCES Clients(client_id)
);

-- 11. TransactionAgents
CREATE TABLE TransactionAgents (
    transaction_id INT NOT NULL,
    agent_id INT NOT NULL,
    agent_role VARCHAR(20) NOT NULL CHECK (
        agent_role IN ('Buyer Agent', 'Seller Agent', 'Tenant Agent', 'Landlord Agent')
    ),
    PRIMARY KEY (transaction_id, agent_id, agent_role),
    CONSTRAINT fk_transactionagents_transaction
        FOREIGN KEY (transaction_id) REFERENCES Transactions(transaction_id),
    CONSTRAINT fk_transactionagents_agent
        FOREIGN KEY (agent_id) REFERENCES Agents(agent_id)
);

-- 12. TransactionParties
CREATE TABLE TransactionParties (
    transaction_id INT NOT NULL,
    client_id INT NOT NULL,
    role_type VARCHAR(20) NOT NULL CHECK (
        role_type IN ('Buyer', 'Seller', 'Tenant', 'Landlord')
    ),
    PRIMARY KEY (transaction_id, client_id, role_type),
    CONSTRAINT fk_transactionparties_transaction
        FOREIGN KEY (transaction_id) REFERENCES Transactions(transaction_id),
    CONSTRAINT fk_transactionparties_client
        FOREIGN KEY (client_id) REFERENCES Clients(client_id)
);

-- 13. Commissions
CREATE TABLE Commissions (
    agent_id INT NOT NULL,
    transaction_id INT NOT NULL,
    commission_amount DECIMAL(10,2) NOT NULL CHECK (commission_amount >= 0),
    PRIMARY KEY (agent_id, transaction_id),
    CONSTRAINT fk_commissions_agent
        FOREIGN KEY (agent_id) REFERENCES Agents(agent_id),
    CONSTRAINT fk_commissions_transaction
        FOREIGN KEY (transaction_id) REFERENCES Transactions(transaction_id)
);

-- 14. Expenses
CREATE TABLE Expenses (
    expense_id INT PRIMARY KEY,
    transaction_id INT NOT NULL,
    staging_cost DECIMAL(10,2) DEFAULT 0 CHECK (staging_cost >= 0),
    legal_fees DECIMAL(10,2) DEFAULT 0 CHECK (legal_fees >= 0),
    other_expenses DECIMAL(10,2) DEFAULT 0 CHECK (other_expenses >= 0),
    CONSTRAINT fk_expenses_transaction
        FOREIGN KEY (transaction_id) REFERENCES Transactions(transaction_id)
);

-- 15. AppointmentInteractions
CREATE TABLE AppointmentInteractions (
    interaction_id INT PRIMARY KEY,
    appointment_id INT NOT NULL,
    agent_id INT NOT NULL,
    client_id INT NOT NULL,
    interaction_datetime TIMESTAMP NOT NULL,
    CONSTRAINT fk_appointmentinteractions_appointment
        FOREIGN KEY (appointment_id) REFERENCES Appointments(appointment_id),
    CONSTRAINT fk_appointmentinteractions_agent
        FOREIGN KEY (agent_id) REFERENCES Agents(agent_id),
    CONSTRAINT fk_appointmentinteractions_client
        FOREIGN KEY (client_id) REFERENCES Clients(client_id)
);
