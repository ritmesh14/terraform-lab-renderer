-- schema.sql — run this against sqldb-app from lab 58.
-- Creates a Products table and seeds three rows; used as the manual data
-- upload in lab 63. Safe to re-run only on a fresh database.
CREATE TABLE dbo.Products (
    Id          INT IDENTITY(1,1) PRIMARY KEY,
    Name        NVARCHAR(100) NOT NULL,
    Price       DECIMAL(10,2) NOT NULL,
    CreatedAt   DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

INSERT INTO dbo.Products (Name, Price) VALUES
    ('Widget',  9.99),
    ('Gadget', 19.99),
    ('Gizmo',  29.99);
