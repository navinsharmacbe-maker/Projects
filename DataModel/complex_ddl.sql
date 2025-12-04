-- E-commerce Analytics System (Snowflake Schema)

-- 1. Region Dimension (Normalized from Store/Customer Location)
CREATE TABLE dim_regions (
    region_id INT PRIMARY KEY,
    region_name VARCHAR(50),
    country VARCHAR(50),
    sales_manager_id INT
);

-- 2. City Dimension (Child of Region)
CREATE TABLE dim_cities (
    city_id INT PRIMARY KEY,
    region_id INT,
    city_name VARCHAR(50),
    population INT,
    
    CONSTRAINT fk_city_region FOREIGN KEY (region_id) REFERENCES dim_regions(region_id)
);

-- 3. Store Dimension (Child of City)
CREATE TABLE dim_stores (
    store_id INT PRIMARY KEY,
    city_id INT,
    store_name VARCHAR(100),
    store_type VARCHAR(20), -- 'Flagship', 'Outlet', 'Kiosk'
    opened_date DATE,
    
    CONSTRAINT fk_store_city FOREIGN KEY (city_id) REFERENCES dim_cities(city_id)
);

-- 4. Category Dimension (Normalized from Product)
CREATE TABLE dim_categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(50),
    parent_category_id INT, -- Self-referencing for hierarchy
    
    CONSTRAINT fk_cat_parent FOREIGN KEY (parent_category_id) REFERENCES dim_categories(category_id)
);

-- 5. Brand Dimension (Normalized from Product)
CREATE TABLE dim_brands (
    brand_id INT PRIMARY KEY,
    brand_name VARCHAR(100),
    manufacturer_name VARCHAR(100),
    contract_start_date DATE
);

-- 6. Product Dimension (Central Dimension)
CREATE TABLE dim_products (
    product_id INT PRIMARY KEY,
    category_id INT,
    brand_id INT,
    product_name VARCHAR(200),
    sku VARCHAR(50),
    unit_price DECIMAL(10, 2),
    weight_kg DECIMAL(6, 3),
    is_active BOOLEAN,
    
    CONSTRAINT fk_prod_category FOREIGN KEY (category_id) REFERENCES dim_categories(category_id),
    CONSTRAINT fk_prod_brand FOREIGN KEY (brand_id) REFERENCES dim_brands(brand_id)
);

-- 7. Customer Dimension
CREATE TABLE dim_customers (
    customer_id INT PRIMARY KEY,
    city_id INT, -- Snowflake connection to geography
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    registration_date DATE,
    customer_segment VARCHAR(20), -- 'VIP', 'Regular', 'New'
    
    CONSTRAINT fk_cust_city FOREIGN KEY (city_id) REFERENCES dim_cities(city_id)
);

-- 8. Time Dimension (Standard for Warehousing)
CREATE TABLE dim_time (
    time_id INT PRIMARY KEY,
    full_date DATE,
    day_of_week VARCHAR(10),
    month_name VARCHAR(10),
    quarter INT,
    year INT,
    is_holiday BOOLEAN
);

-- 9. Promotion Dimension
CREATE TABLE dim_promotions (
    promo_id INT PRIMARY KEY,
    promo_name VARCHAR(100),
    discount_type VARCHAR(20), -- 'Percentage', 'Fixed Amount'
    discount_value DECIMAL(10, 2),
    start_date DATE,
    end_date DATE
);

-- 10. Fact Sales (Central Fact Table)
CREATE TABLE fact_sales (
    sales_id BIGINT PRIMARY KEY,
    time_id INT,
    store_id INT,
    product_id INT,
    customer_id INT,
    promo_id INT,
    quantity INT,
    gross_amount DECIMAL(12, 2),
    discount_amount DECIMAL(12, 2),
    net_amount DECIMAL(12, 2),
    tax_amount DECIMAL(12, 2),
    
    CONSTRAINT fk_sales_time FOREIGN KEY (time_id) REFERENCES dim_time(time_id),
    CONSTRAINT fk_sales_store FOREIGN KEY (store_id) REFERENCES dim_stores(store_id),
    CONSTRAINT fk_sales_prod FOREIGN KEY (product_id) REFERENCES dim_products(product_id),
    CONSTRAINT fk_sales_cust FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id),
    CONSTRAINT fk_sales_promo FOREIGN KEY (promo_id) REFERENCES dim_promotions(promo_id)
);

-- 11. Fact Inventory (Another Fact Table sharing dimensions)
CREATE TABLE fact_inventory (
    inventory_id BIGINT PRIMARY KEY,
    time_id INT,
    store_id INT,
    product_id INT,
    quantity_on_hand INT,
    quantity_reserved INT,
    reorder_level INT,
    
    CONSTRAINT fk_inv_time FOREIGN KEY (time_id) REFERENCES dim_time(time_id),
    CONSTRAINT fk_inv_store FOREIGN KEY (store_id) REFERENCES dim_stores(store_id),
    CONSTRAINT fk_inv_prod FOREIGN KEY (product_id) REFERENCES dim_products(product_id)
);

-- 12. Product Tags (Many-to-Many Relationship)
CREATE TABLE tags (
    tag_id INT PRIMARY KEY,
    tag_name VARCHAR(50)
);

CREATE TABLE product_tags_bridge (
    product_id INT,
    tag_id INT,
    PRIMARY KEY (product_id, tag_id),
    
    CONSTRAINT fk_bridge_prod FOREIGN KEY (product_id) REFERENCES dim_products(product_id),
    CONSTRAINT fk_bridge_tag FOREIGN KEY (tag_id) REFERENCES tags(tag_id)
);

-- 13. Employee Hierarchy (Self-Referencing + One-to-Many to Stores)
CREATE TABLE dim_employees (
    employee_id INT PRIMARY KEY,
    store_id INT,
    manager_id INT, -- Self-referencing
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    job_title VARCHAR(50),
    
    CONSTRAINT fk_emp_store FOREIGN KEY (store_id) REFERENCES dim_stores(store_id),
    CONSTRAINT fk_emp_manager FOREIGN KEY (manager_id) REFERENCES dim_employees(employee_id)
);
