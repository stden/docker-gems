# Create the database.
CREATE DATABASE IF NOT EXISTS my_db;
# create schema my_db;

# Select the database.
use my_db;

# Create the table.
create table user
(
    id            int auto_increment primary key,
    login         varchar(1024) not null,
    password_hash varchar(1024) not null
);

# Add records to the database.
# Use SHA-256 for password hashes.
INSERT INTO user (login, password_hash)
    VALUE ('admin', sha2('admin', 256));
INSERT INTO user (login, password_hash)
    VALUE ('user', sha2('user', 256));
