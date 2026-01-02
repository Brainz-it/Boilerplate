-- Migration 002: Seed Data
-- Initial data for boilerplate (customize for your project)

-- ============================================================================
-- DEFAULT ADMIN
-- Password hash is for 'changeme123' - CHANGE THIS IN PRODUCTION
-- Using PBKDF2-SHA256 format (compatible with Edge runtime)
-- ============================================================================

INSERT OR IGNORE INTO admins (id, email, password_hash, name, role) VALUES (
  'admin_001',
  'admin@example.com',
  '$pbkdf2-sha256$100000$f820a5ac06352af2b9e50be3ddfdaabd$361ca8dbffd98751dbaca5e17ffe67e41a37dd8c13202180fecd572d0f2de92e',
  'Admin',
  'super_admin'
);

-- NOTE: Add your domain-specific seed data below
-- Examples:
-- - Default categories
-- - Initial configuration values
-- - Sample content for development
