# Nero Music

Nero Music is a Flutter Android-first music platform foundation.

## Confirmed product direction

- Android first; iPhone later.
- Black, red and pink identity.
- Private personal music storage and public music publishing.
- Anyone may apply for an artist account, subject to verification.
- Nigeria first, then worldwide.
- Platform revenue and artist earnings.

## Current Stage 1 scope

This starter includes the welcome screen, account-type selection, sign-in and registration interface, and five-section app navigation. Authentication forms are currently UI demonstrations only. Supabase authentication, music uploads, streaming, payments, artist verification and earnings are not yet active.

## Build

The GitHub Actions workflow `.github/workflows/build-android.yml` generates Android platform files, gets dependencies, formats, analyzes, tests and builds the release APK.

Run it from GitHub: Actions -> Build Nero Music Android APK -> Run workflow.

## Security

Do not put Supabase service-role keys, payment secret keys or other private credentials in Flutter source code. Server-side secrets belong in secure backend configuration.


## Android launcher icon

The supplied Nero Music logo is stored at `assets/nero_music_launcher.png`. The Android build workflow generates launcher icon sizes and adaptive icon resources using `flutter_launcher_icons`. No Flutter branding is used for the app icon.
