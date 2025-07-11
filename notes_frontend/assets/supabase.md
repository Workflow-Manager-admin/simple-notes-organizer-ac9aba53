# Supabase Integration for Notes Frontend

This Flutter app connects to Supabase for backend note storage.

## Setup

- Uses the `supabase_flutter` package.
- Environment (hard coded for simplicity — for higher security and environments, consider a .env loader):
  - SUPABASE_URL: https://mzxyorlnbfdkneiezgjz.supabase.co
  - SUPABASE_KEY: [Project's anon key]

## Modifying Credentials
- For production, replace `supabaseUrl` and `supabaseKey` in `main.dart` with env variable loaders or use a `.env` style package.

## Supabase Table Schema (for reference)
- Table: `notes`
- Columns:
  - `id`: integer, primary key
  - `title`: text
  - `content`: text
  - `created_at`: timestamp (set default now())
  - `updated_at`: timestamp (nullable)

## Basic Usage

- The app supports: list notes, create note, update note, delete note, search notes (by title).
- All interactions use Supabase REST via the `supabase_flutter` client.
