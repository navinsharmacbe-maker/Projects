
CREATE TABLE manufacturers (
    manufacturer_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    hq_country VARCHAR(50),
    established_year INT
);

CREATE TABLE market_segments (
    segment_id INT PRIMARY KEY,
    segment_name VARCHAR(50), 
    base_depreciation_factor DECIMAL(5, 4)
);

CREATE TABLE cars (
    vehicle_id INT PRIMARY KEY, 
    manufacturer_id INT, 
    segment_id INT, 
    model_name VARCHAR(100),
    brand VARCHAR(50), 
    new_price DECIMAL(10, 2),
    engine_cc INT,
    body_style VARCHAR(50),
    trim_level VARCHAR(50),
    fuel_type VARCHAR(30),
    range_mpl DECIMAL(6, 2), 
    introduced_date DATE,
    discontinued_date DATE,
    
    CONSTRAINT fk_car_manufacturer FOREIGN KEY (manufacturer_id) 
        REFERENCES manufacturers(manufacturer_id),
    CONSTRAINT fk_car_segment FOREIGN KEY (segment_id) 
        REFERENCES market_segments(segment_id)
);

CREATE TABLE residual_forecasts (
    forecast_id INT PRIMARY KEY,
    vehicle_id INT NOT NULL,
    forecast_date DATE,
    term_months INT, 
    annual_mileage_allowance INT,
    predicted_residual_value DECIMAL(10, 2),
    predicted_residual_percent DECIMAL(5, 2),
    
    CONSTRAINT fk_forecast_vehicle FOREIGN KEY (vehicle_id) 
        REFERENCES cars(vehicle_id)
);

CREATE TABLE auction_transactions (
    transaction_id INT PRIMARY KEY,
    vehicle_id INT,
    transaction_date DATE,
    odometer_reading INT,
    condition_grade VARCHAR(10), 
    sold_price DECIMAL(10, 2),
    location_region VARCHAR(50),
    
    CONSTRAINT fk_auction_vehicle FOREIGN KEY (vehicle_id) 
        REFERENCES cars(vehicle_id)
);

CREATE TABLE equipment_options (
    option_id INT PRIMARY KEY,
    feature_name VARCHAR(100), 
    category VARCHAR(50), 
    value_adjustment_amount DECIMAL(8, 2) 
);

CREATE TABLE car_features_link (
    link_id INT PRIMARY KEY,
    vehicle_id INT,
    option_id INT,
    is_standard_equipment BOOLEAN,
    
    CONSTRAINT fk_link_car FOREIGN KEY (vehicle_id) REFERENCES cars(vehicle_id),
    CONSTRAINT fk_link_option FOREIGN KEY (option_id) REFERENCES equipment_options(option_id)
);

CREATE TABLE competitors (
    competitor_id INT PRIMARY KEY,
    source_vehicle_id INT,
    target_vehicle_id INT,
    competition_strength VARCHAR(20), 
    
    CONSTRAINT fk_comp_source FOREIGN KEY (source_vehicle_id) REFERENCES cars(vehicle_id),
    CONSTRAINT fk_comp_target FOREIGN KEY (target_vehicle_id) REFERENCES cars(vehicle_id)
);

CREATE TABLE depreciation_curves (
    curve_id INT PRIMARY KEY,
    segment_id INT,
    month_index INT, 
    decay_rate DECIMAL(6, 4),
    
    CONSTRAINT fk_curve_segment FOREIGN KEY (segment_id) 
        REFERENCES market_segments(segment_id)
);

CREATE TABLE lease_contracts (
    lease_id INT PRIMARY KEY,
    vehicle_id INT,
    customer_hash VARCHAR(64), 
    start_date DATE,
    end_date DATE,
    contract_residual_value DECIMAL(10, 2),
    actual_money_factor DECIMAL(7, 5),
    
    CONSTRAINT fk_lease_vehicle FOREIGN KEY (vehicle_id) 
        REFERENCES cars(vehicle_id)
);