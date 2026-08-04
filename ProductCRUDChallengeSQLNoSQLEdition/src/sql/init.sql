-- SQL equivalent of the Mongoose Product schema.
-- id             -> auto-increment integer PK
-- name           -> NOT NULL
-- price          -> NOT NULL, decimal for currency precision
-- category       -> nullable
-- in_stock       -> defaults to TRUE
-- created_at / updated_at mirror Mongoose's { timestamps: true }.

CREATE TABLE IF NOT EXISTS products (
  id          INT            AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(255)   NOT NULL,
  price       DECIMAL(10, 2) NOT NULL,
  category    VARCHAR(255)   DEFAULT NULL,
  in_stock    BOOLEAN        NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
