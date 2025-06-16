# Multi-Tenant Phoenix Application

An example of a multi-tenant application built with Elixir + Phoenix

## Features

### Core Functionality
- **Multi-tenant Architecture**: Tenant isolation using PostgreSQL schemas
- **User Authentication**: Complete user registration, login, and session management
- **Application Management**: Create and manage multiple applications per user
- **Inventory Management**: Product catalog with import/export capabilities
- **Subdomain Routing**: Visitor access via tenant-specific subdomains

### Technical Features
- **Background Jobs**: Oban for reliable job processing
- **Real-time Updates**: Phoenix LiveView for interactive UI
- **API Integration**: HTTP client for external inventory systems
- **Audit Trail**: PaperTrail for tracking changes
- **Email**: Swoosh for transactional emails
- **Pagination**: Flop for efficient data pagination
- **Validation**: JSON Schema validation

## Setup Instructions

### 1. Database Setup

Start PostgreSQL using Docker:
```bash
docker compose up -d
```

Setup the database:
```bash
mix ecto.setup
```

### 2. Start the Application

```bash
mix phx.server
```

The application will be available at [`localhost:4000`](http://localhost:4000).

## Development Workflow

### Running Tests

```bash
# Run all tests
mix test

# Run tests in watch mode
mix test.watch

# Run tests with coverage
mix test --cover
```

## Architecture Overview

### Multi-Tenancy

The application uses PostgreSQL schemas for tenant isolation:
- Each tenant gets its own database schema
- Tenant data is completely isolated
- Migrations are run per tenant using the `Tenants` module

### Authentication Flow

1. Users register and authenticate at the main domain
2. Users can create multiple applications (tenants)
3. Each application gets a unique subdomain
4. Visitors access tenant-specific content via subdomains

### Key Modules

- **`MainApp.Accounts`**: User and application management
- **`MainApp.Inventories`**: Product catalog management
- **`MainApp.ExternalInventories`**: External system integration
- **`MainApp.Tenants`**: Multi-tenant schema management
- **`MainApp.Workers`**: Background job processing

## Configuration

### Environment Variables

Create a `.env` file or set the following environment variables:

```bash
# Database
DATABASE_URL=ecto://postgres:postgres@localhost/app

# Phoenix
SECRET_KEY_BASE=your-secret-key-base
PHX_HOST=localhost
PHX_PORT=4000

# Email (if using external SMTP)
SMTP_HOST=your-smtp-host
SMTP_PORT=587
SMTP_USERNAME=your-username
SMTP_PASSWORD=your-password
```

## API Documentation

### Authentication Endpoints

- `POST /users/log-in` - User login
- `DELETE /users/log-out` - User logout
- `GET /users/register` - Registration form
- `POST /users/set-application` - Set current application context

### Application Management

- `GET /applications` - List user applications
- `POST /applications` - Create new application
- `GET /applications/:id` - View application details
- `PUT /applications/:id` - Update application

### Inventory Management

- `GET /products` - List products (tenant-scoped)
- `POST /products` - Create product
- `GET /products/:id` - View product
- `PUT /products/:id` - Update product

### Visitor Routes

- `GET /visitors/` - Tenant-specific visitor page (subdomain-based)

## Deployment

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Run code quality checks
6. Submit a pull request

---
