# Data Migrations

A Rails application for migrating a clinic's patient demographics from a CSV export into a PostgreSQL database.

Upload a CSV through the web interface and the app cleans each row, imports the patients idempotently (uploading the same file again does not create duplicates), and records statistics for every migration.

## Requirements

- Docker and Docker Compose

Nothing else needs to be installed locally: Ruby, Rails and PostgreSQL run in containers.

## Running the app

```bash
docker compose up --build
```

On the first start this builds the image, creates the database, runs the migrations and creates a demo user.

Open **http://localhost:3001** and sign in with:

| Email | Password |
|---|---|
| `demo@example.com` | `development-only-password` |

These credentials and the encryption keys in `docker-compose.yml` are for local development only.

To stop the app:

```bash
docker compose down
```

## Using the app

1. **Upload** a patient CSV on the home page. The migration runs in the background and the page refreshes until it finishes.
2. **Review the migration**: outcome counts, rejection reasons, data issues, field completeness, and every row with its outcome and issues.
3. **Download the issue report** (CSV) to send rejected rows and rows with warnings back to the clinic.
4. **Upload the same file again**: rows are reported as unchanged and no duplicate patients are created.
5. **Browse patients** and open a patient to see which migrations created or changed them.

The expected CSV columns are listed in `config/data_migration.yml`. A file from a clinic with different column names can be supported by adding the header names there.

## Useful commands

Run these while the app is running:

| Task | Command |
|---|---|
| Rails console | `docker compose exec web bin/rails console` |
| Create the demo user | `docker compose exec web bin/rails db:seed` |
| Wipe raw row data older than the retention period (also runs daily) | `docker compose exec web bin/rails patient_import:purge_raw_data` |
| Style check | `docker compose exec web bin/rubocop` |
| Security scan | `docker compose exec web bin/brakeman` |
| Gem vulnerability check | `docker compose exec web bin/bundler-audit` |
| Follow the logs | `docker compose logs -f web` |

To start again from an empty database:

```bash
docker compose down -v
docker compose up
```

## Stack

- Ruby 3.3, Rails 8.1
- PostgreSQL 16
- Solid Queue for background jobs (runs inside the web process)
- Active Storage for uploaded files (deleted after each migration)
- Server-rendered views with Turbo and Stimulus
