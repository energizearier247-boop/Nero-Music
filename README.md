# Nero Music – Stage 2 foundation

Flutter Android app for Nero Music. Branding: black with the launcher's bright red-to-pink gradient. Android launcher label must be **Nero Music**.

## Stage 2 features in this package

- Supabase Flutter initialization using the project URL and publishable client key.
- Listener and Artist Applicant email/password registration.
- Email/password sign-in, password reset email, and Supabase-managed persistent sessions.
- Dark and light appearance setting saved on the device.
- Profile menu navigation to Settings and sign out.
- Navigation destinations and menu rows open their corresponding screen/feature placeholder.
- Supabase profile table, new-user trigger, and row-level security SQL in `supabase/schema.sql`.

## Supabase setup

1. Open the Nero Music Supabase project.
2. Open **SQL Editor** and run `supabase/schema.sql` from this repository.
3. In **Authentication → Providers → Email**, keep email confirmation enabled if you want users to verify their email before signing in.
4. In **Authentication → URL Configuration**, configure the production redirect/deep-link URLs before enabling password recovery links for release builds.

The app uses only the Supabase publishable client key. Never place a Supabase secret/service-role key in the Flutter app or repository.

## Build

The separate GitHub Actions workflow is provided in the chat. It creates the Android platform folder, generates the launcher icon, runs formatting, analysis and tests, and builds the release APK. It sets the Android launcher label to `Nero Music`.

## Current scope

This is the Stage 2 authentication/theme foundation. Music upload, private storage policies/bucket, streaming playback, payments, artist verification, and production deep links are subsequent implementation milestones. Rows currently navigate to feature landing screens where those features are not yet implemented; navigation is not the same as a completed backend feature.
