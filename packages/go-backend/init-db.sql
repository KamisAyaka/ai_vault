-- Initialize AI Vault Database
-- This script runs when the PostgreSQL container starts for the first time

-- Create database if it doesn't exist (though it should already exist from POSTGRES_DB)
-- SELECT 'CREATE DATABASE ai_vault' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ai_vault')\gexec

-- Connect to the database
\c ai_vault;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create a function to generate UUIDs (for older PostgreSQL versions)
CREATE OR REPLACE FUNCTION gen_random_uuid() RETURNS uuid AS $$
BEGIN
    RETURN uuid_generate_v4();
END;
$$ LANGUAGE plpgsql;

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE ai_vault TO ai_vault;
GRANT ALL PRIVILEGES ON SCHEMA public TO ai_vault;

-- Create indexes for better performance (these will be created by GORM migrations)
-- But we can create some additional ones here if needed

-- Log the initialization
DO $$
BEGIN
    RAISE NOTICE 'AI Vault database initialized successfully';
END $$;
