# Book Management Project

## Description

This is a Java project for managing book details. It includes functionalities like adding, updating, deleting books, and interacting with Kafka for book-related operations.

# Table of Contents

* Project Structure
* Installation
* Usage
* Authentication
* Endpoints
* Kafka Integration
* Security
* Caching
* Scheduled Tasks
* Health Check

## Project Structure

The project is organized into several packages:

* authentication: Contains classes related to JWT authentication.
* config: Configuration classes for Jackson, Kafka, and Swagger.
* controller: Controllers handling book operations and user authentication.
* entity: Entity classes representing the data model.
* entitydto: Data Transfer Objects (DTOs) for entities.
* kafka: Classes for Kafka message consumption and production.
* repository: Spring Data JPA repositories for database operations.
* service: Business logic and services for book management, user, and JWT.
* utils: Utility classes like AOP for sending emails, health indicators, and schedulers.

# Installation


# Usage

The application exposes RESTful endpoints for book management and user authentication. Swagger documentation is available at __'/swagger-ui.html.'__

# Authentication

The project uses JWT (JSON Web Token) for authentication. To authenticate, use the __'/auth/authenticate'__ endpoint with valid credentials.

# Endpoints

* __GET /books:__ Get all books (requires user role).
* __GET /books/{id}:__ Get a book by ID (requires user role).
* __POST /books:__ Save a new book (requires user role).
* __PUT /books/{id}:__ Update a book by ID (requires user role).
* __DELETE /books/{id}:__ Delete a book by ID (requires user role).
* __POST /books/kafka:__ Save a new book and publish to Kafka (requires user role).

# Kafka Integration

The project integrates with Kafka for asynchronous book processing. New books are sent to the Kafka queue __'/book-queue'__ for further processing.

# Security

Security is implemented using Spring Security. JWT is used for user authentication. The application supports role-based access control.

# Caching

Caching is implemented for the __'/books'__ endpoint to improve performance. Cache is invalidated on save or update operations.

# Scheduled Tasks

The project includes scheduled tasks for sending emails and health check.

# Health Check

Health check endpoints are provided for monitoring the application's health. The project includes custom health indicators, including a database connection health check.