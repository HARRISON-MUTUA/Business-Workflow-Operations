-- Business Operations & Workflow Management Platform
-- Iteration 1 schema. Run in phpMyAdmin > Import.

CREATE DATABASE IF NOT EXISTS business_workflow
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE business_workflow;

-- Drop in dependency order so the script can be re-run during development
DROP TABLE IF EXISTS requests;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS businesses;
DROP TABLE IF EXISTS roles;

-- 1. ROLES -------------------------------------------------------------
CREATE TABLE roles (
  id          TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name        VARCHAR(30)  NOT NULL,
  description VARCHAR(150) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_roles_name (name)
) ENGINE=InnoDB;

INSERT INTO roles (name, description) VALUES
  ('super_admin',    'Platform owner. Manages the platform, not a single business.'),
  ('business_owner', 'Organization admin. Manages users and views requests for one business.'),
  ('manager',        'Reviews and updates requests within their business.'),
  ('employee',       'Submits and tracks their own requests.'),
  ('auditor',        'Read-only compliance access.');

-- 2. BUSINESSES (tenants) ----------------------------------------------
CREATE TABLE businesses (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name       VARCHAR(120) NOT NULL,
  email      VARCHAR(150) NULL,
  status     ENUM('active','suspended') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_businesses_name (name)
) ENGINE=InnoDB;

-- 3. USERS -------------------------------------------------------------
-- business_id is NULL only for the platform-level super_admin.
CREATE TABLE users (
  id                   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  business_id          INT UNSIGNED NULL,
  role_id              TINYINT UNSIGNED NOT NULL,
  full_name            VARCHAR(120) NOT NULL,
  email                VARCHAR(150) NOT NULL,
  password_hash        VARCHAR(255) NOT NULL,
  can_approve          TINYINT(1) NOT NULL DEFAULT 0,
  status               ENUM('active','disabled') NOT NULL DEFAULT 'active',
  must_change_password TINYINT(1) NOT NULL DEFAULT 0,
  last_login_at        DATETIME NULL,
  created_by           INT UNSIGNED NULL,
  created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email),
  KEY idx_users_business (business_id),
  KEY idx_users_role (role_id),
  CONSTRAINT fk_users_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE RESTRICT,
  CONSTRAINT fk_users_role     FOREIGN KEY (role_id)     REFERENCES roles(id)      ON DELETE RESTRICT,
  CONSTRAINT fk_users_creator  FOREIGN KEY (created_by)  REFERENCES users(id)      ON DELETE SET NULL
) ENGINE=InnoDB;

-- 4. REQUESTS ----------------------------------------------------------
CREATE TABLE requests (
  id               INT UNSIGNED NOT NULL AUTO_INCREMENT,
  business_id      INT UNSIGNED NOT NULL,
  submitted_by     INT UNSIGNED NOT NULL,
  assigned_to      INT UNSIGNED NULL,
  request_type     ENUM('purchase','maintenance','it_support') NOT NULL,
  title            VARCHAR(150) NOT NULL,
  description      TEXT NOT NULL,
  status           ENUM('submitted','in_progress','completed','rejected') NOT NULL DEFAULT 'submitted',
  rejection_reason VARCHAR(500) NULL,
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_requests_business_status (business_id, status),
  KEY idx_requests_submitter (submitted_by),
  KEY idx_requests_assignee (assigned_to),
  CONSTRAINT fk_requests_business  FOREIGN KEY (business_id)  REFERENCES businesses(id) ON DELETE RESTRICT,
  CONSTRAINT fk_requests_submitter FOREIGN KEY (submitted_by) REFERENCES users(id)      ON DELETE RESTRICT,
  CONSTRAINT fk_requests_assignee  FOREIGN KEY (assigned_to)  REFERENCES users(id)      ON DELETE SET NULL
) ENGINE=InnoDB;