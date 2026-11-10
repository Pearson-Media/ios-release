# ios-release

The one release path for Pearson Media's iOS apps: archive, export, upload to TestFlight. Each app calls it from a short workflow of its own, so a fix made here reaches every app on its next release.

This repo is public because GitHub only lets a private shared workflow be used by repos with the same owner, and the apps are split between two owners. It holds build steps only. Keys and passwords stay in each app's own GitHub secrets or Infisical.

## Calling it

```yaml
name: Release iOS
on:
  push:
    tags: ["v*"]
  workflow_dispatch:
    inputs:
      version:
        description: "X.Y.Z (blank keeps the project's version)"
        default: ""

permissions:
  contents: read

jobs:
  release:
    uses: Pearson-Media/ios-release/.github/workflows/ios-release.yml@v1
    with:
      working-directory: ios
      project: MyApp.xcodeproj
      scheme: MyApp
      marketing-version: ${{ inputs.version }}
    secrets:
      APP_STORE_CONNECT_API_KEY_ID: ${{ secrets.IOS_ASC_KEY_ID }}
      APP_STORE_CONNECT_API_ISSUER_ID: ${{ secrets.IOS_ASC_ISSUER_ID }}
      APP_STORE_CONNECT_API_KEY_BASE64: ${{ secrets.IOS_ASC_KEY_BASE64 }}
      BUILD_CERTIFICATE_BASE64: ${{ secrets.IOS_DEV_CERT_BASE64 }}
      P12_PASSWORD: ${{ secrets.IOS_DEV_CERT_PASSWORD }}
      APPLE_TEAM_ID: ${{ secrets.IOS_TEAM_ID }}
      BUILD_ENV: |
        SUPABASE_URL=${{ secrets.SUPABASE_URL }}
        SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
```

The `IOS_*` secrets are the same in every app (one Apple team, Pearson Media LLC). `scripts/sync-signing-secrets.sh` copies them from Infisical into each app repo; run it again after renewing the certificate or the API key.

Apps that keep secrets in Infisical pass `infisical-project-slug` and the three `INFISICAL_*` secrets instead.

`@v1` moves forward with compatible fixes. A change that would break a caller gets `v2`.

## What it needs

| Secret | What it is |
|---|---|
| `APP_STORE_CONNECT_API_KEY_ID` / `_ISSUER_ID` / `_KEY_BASE64` | App Store Connect API key (Admin or App Manager), the .p8 base64-encoded |
| `BUILD_CERTIFICATE_BASE64`, `P12_PASSWORD` | An **Apple Development** certificate with its private key, exported as .p12 and base64-encoded |
| `APPLE_TEAM_ID` | The 10-character team id |
| `BUILD_ENV` (optional) | `NAME=value` lines exported to every step, for app config such as a Supabase URL |
| `SENTRY_AUTH_TOKEN` (optional) | With `SENTRY_ORG` and `SENTRY_PROJECT` in `BUILD_ENV`, uploads debug symbols |

## How signing works

Automatic signing, no profiles to manage:

1. The archive signs with the Development certificate, imported into a keychain the job creates and deletes. A runner that runs as a background service cannot use the login keychain's private key (`errSecInteractionNotAllowed`), which is why the job brings its own.
2. The export re-signs with Apple's cloud-managed Distribution certificate and an App Store profile that Xcode fetches with the API key.

Nothing rewrites the project file. Each app's targets must have `CODE_SIGN_STYLE = Automatic` and the right bundle ids; the workflow sets the team.

## Inputs

See the `inputs:` block at the top of [`.github/workflows/ios-release.yml`](.github/workflows/ios-release.yml). Each one says what it does.

## Runners

`runs-on` defaults to GitHub's `macos-15`. Public repos build there free. Private repos pass the Mac mini: `runs-on: '"pearson-mac"'`. Release build files go in the job's temp folder and are deleted afterwards, and the job stops early with a plain message when the disk is too full.
