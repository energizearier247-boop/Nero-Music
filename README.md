# Nero Music – Stage 2 foundation

Flutter Android app for Nero Music. Branding: black with the launcher's bright red-to-pink gradient. Android launcher label must be **Nero Music**.

## Stage 2 features in this package

- Supabase Flutter initialization using the project URL and publishable client key.
- Listener and Artist Applicant email/password registration.
- Email/password sign-in, password reset email, and Supabase-managed persistent sessions.
- Dark and light appearance setting saved on the device.
- Post-email-verification routing to the sign-in screen when a pending registration is confirmed.
- User-provided banner image on Home and portrait image in Profile.
- Profile menu navigation to Settings and sign out.
- Navigation destinations and menu rows open their corresponding screen/feature placeholder.
- Supabase profile table, new-user trigger, and row-level security SQL in `supabase/schema.sql`.

## Supabase setup

1. Open the Nero Music Supabase project.
2. Open **SQL Editor** and run `supabase/schema.sql` from this repository.
3. In **Authentication → Providers → Email**, keep email confirmation enabled if you want users to verify their email before signing in.
4. In **Authentication → URL Configuration → Redirect URLs**, allow `com.neromusic://login-callback`. The app and workflow register this same callback. Keep the Supabase Site URL as your real website URL if you have one; the mobile callback belongs in Additional Redirect URLs.

The app uses only the Supabase publishable client key. Never place a Supabase secret/service-role key in the Flutter app or repository. `supabase_flutter` handles incoming auth deep links automatically on Android; the app listens for auth-state changes so the signed-in screen refreshes after a successful callback. Password recovery opens an in-app new-password form.

## Build

The separate GitHub Actions workflow is provided in the chat. It creates the Android platform folder, generates the launcher icon, runs formatting, analysis and tests, and builds the release APK. It sets the Android launcher label to `Nero Music`.

## Current scope

This is the Stage 2 authentication/theme foundation. Music upload, private storage policies/bucket, streaming playback, live music search, dynamic artist artwork, payments, artist verification, and production deep links are subsequent implementation milestones. The supplied Profile portrait is a static design image; it is not presented as an authenticated user's profile photo. Dynamic artist images cannot appear alongside worldwide search/playback until a real music catalogue and playback provider/API are connected. Rows currently navigate to feature landing screens where those features are not yet implemented; navigation is not the same as a completed backend feature.
