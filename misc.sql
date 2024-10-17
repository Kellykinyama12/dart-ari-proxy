-- Connect to the new database
USE my_new_database;

-- Create a table within the new database
CREATE TABLE system_errors (
    id SERIAL PRIMARY KEY,
    error_message TEXT NOT NULL,
    error_type VARCHAR(255) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status_code INT,
    additional_info TEXT
);


-- Create a table within the new database
CREATE TABLE recordings (
    id SERIAL PRIMARY KEY,
    filename VARCHAR(255) NOT NULL,   
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    additional_info TEXT
);