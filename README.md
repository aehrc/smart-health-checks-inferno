# Smart Health Checks Inferno

A testing suite for validating FHIR servers against the [Smart Health Checks Implementation Guide](https://build.fhir.org/ig/aehrc/smart-forms-ig/index.html). This project is built on the [Inferno](https://inferno.healthit.gov/) testing framework and provides automated tests to ensure compliance with the Smart Health Checks IG.

## Overview

Smart Health Checks Inferno is designed to validate FHIR servers that implement the Smart Health Checks Implementation Guide. It tests various FHIR resources including:

- Patient
- Practitioner
- Observations (Blood Pressure, Body Height, Body Weight, etc.)
- Questionnaire Responses
- Conditions
- Immunizations
- Medication Statements
- Allergy Intolerances

The test suite validates resource conformance, search capabilities, and reference resolution according to the implementation guide specifications.

## Quick Start

1. Install Docker and Docker Compose.
2. From the project root, run:
   ```bash
   make setup
   make run
   ```
3. Open http://localhost/ in your browser.

## Prerequisites

- [Docker](https://www.docker.com/get-started)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Installation

### Using Docker (Recommended)

1. Clone the repository:
   ```bash
   git clone https://github.com/aehrc/smart-health-checks-inferno.git
   cd smart-health-checks-inferno
   ```

2. Set up the project:
   ```bash
   make setup
   ```

   This command will:
   - Pull the necessary Docker images
   - Build the project
   - Run database migrations

## Running the Application

### Using Docker

Start the application:
```bash
make run
```

This will build and start all the necessary services. Once running, you can access the application at [http://localhost](http://localhost).

### Stopping and Cleanup

To stop services:
```bash
make stop
```

To remove containers:
```bash
make down
```

## Development

### Generating Test Files

To generate or regenerate test files from the implementation guide (for local development):
```bash
make generate_local
```

Note: The Docker-based target `make generate` is intended for maintainers and may rely on internal tooling. For most contributors, use `make generate_local`.

### Running Tests

To run the test suite:
```bash
make tests
```

### Code Linting

To check code style:
```bash
make rubocop
```

To automatically fix code style issues:
```bash
make rubocop-fix
```

### Full Development Restart

To stop, rebuild, and restart the application with freshly generated files for local development, run:
```bash
make stop
make down
make generate_local
make setup
make run
```

Note: The convenience target `make full_develop_restart` uses the Docker-based generator and may rely on maintainer-only tooling. If it fails, use the sequence above.

## Configuration

The project configuration is stored in `config.json`. Key configuration options include:

- Implementation Guide (IG) details
- Terminology server URL
- Profile configurations
- Resource configurations

## Project Structure

- `lib/smart_health_checks_test_kit/`: Main test kit code
  - `generated/`: Generated test files based on the implementation guide
  - `version.rb`: Version information

## Docker Services

The project uses several Docker services:

- `inferno`: The main application
- `inferno-worker`: Background worker using Sidekiq
- `validator-api`: Dockerized official validator wrapper
- `nginx`: Web server that proxies requests
- `redis`: Used for caching and background job queuing
- `postgres`: Database for storing test results

## License

This project is licensed under the Apache License, Version 2.0 - see the [LICENSE](LICENSE) file for details.

## Links

- [Smart Health Checks Implementation Guide](https://build.fhir.org/ig/aehrc/smart-forms-ig/index.html)
- [Report Issues](https://github.com/aehrc/smart-health-checks-inferno/issues)
