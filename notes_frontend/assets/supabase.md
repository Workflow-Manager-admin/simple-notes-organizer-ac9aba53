# Supabase Integration for Notes Frontend

This Flutter app connects to Supabase for backend note storage.

## Setup

- Uses the `supabase_flutter` package.
- Environment (hard coded for simplicity — for higher security and environments, consider a .env loader):
  - SUPABASE_URL: https://mzxyorlnbfdkneiezgjz.supabase.co
  - SUPABASE_KEY: [Project's anon key]

**Troubleshooting Connectivity (ClientException/SocketException):**
If you see "ClientException with SocketException: Failed host lookup", check these points:
1. The physical device/emulator must have network access.
2. On Android, <uses-permission android:name="android.permission.INTERNET"/> must be present in AndroidManifest.xml under `android/app/src/main/`.
3. The SUPABASE_URL must start with https:// and be correct.
4. If running on an Android emulator, be aware of special hostnames:
   - Localhost URLs (127.0.0.1 or localhost) will not work; use your machine IP if connecting to a local Supabase instance.
   - For public Supabase (cloud), ensure the device can resolve DNS and access the URL via browser.
5. If running on a simulator, try accessing the Supabase URL in the device browser to confirm connectivity.
6. Proxy, firewall, or VPN issues may also block outgoing requests.
7. Network may be restricted if running on certain CI/CD or containerized environments.
8. Double-check the app's Supabase key is correct.
If all else fails, try a physical device with WiFi/mobile data.

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
