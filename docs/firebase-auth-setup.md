# Firebase Authentication setup (DoseAlert)

Sign-in in DoseAlert is **optional**. Medications, schedules, history and alarms stay
in the on-device SQLite database and work offline whether or not the user signs in.
This guide covers the console steps the code can't do for you.

Everything below works on the free **Spark** plan. Authentication (email/password,
Google, Apple) needs no billing. Don't upgrade to Blaze for this feature.

## Status (done in the Firebase Console)

- **Project:** `DoseAlert` (`dosealert-42199`), Spark plan, Google Analytics linked to
  the default account, Gemini in Firebase off.
- **Apps:** Android `dev.hubert.dosetime` and iOS `dev.hubert.dosetime` are registered.
- **Config in the repo:**
  - `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`,
    `lib/firebase_options.dart` and `firebase.json` all point at `dosealert-42199`.
  - `Info.plist` has `GIDClientID` and the Google `REVERSED_CLIENT_ID` URL scheme.
  - The old `fast-delivery-d8d5c` project is no longer used.
- **Sign-in providers:** Email/Password, Google and Apple are enabled. Passwordless
  email links are off, and Google's public-facing name is "DoseAlert".
- **Debug key fingerprints:** this PC's `~/.android/debug.keystore` is registered.
  - SHA-1 `0E:0C:D9:8F:0C:47:98:47:90:20:6A:00:3D:A3:86:D7:99:A6:67:F3`
  - SHA-256 `46:DD:D2:0B:C7:67:D2:56:9B:5E:17:33:CE:F2:61:96:1F:08:3E:DA:E1:7D:C7:96:AB:69:72:87:6C:3E:7F:4B`

Firebase client config (API keys, app IDs, OAuth client IDs) is public by design and ships
inside every app. Security comes from Auth settings and security rules.

## Still to do

### Release and Play signing fingerprints (Android)

Google Sign-In only works in builds signed by a registered key. In Firebase Console,
open **Project settings**, then **DoseAlert Android**, then **Add fingerprint**, and add:

- **Release/upload key** (the keystore in `android/key.properties`):

  ```bash
  keytool -list -v -keystore <path-to-your-upload-keystore.jks> -alias <your-key-alias>
  ```

- **Play App Signing key**: copy it from Play Console, then **Setup**, then **App signing**.

After adding fingerprints, download `google-services.json` again and replace
`android/app/google-services.json`. Only the `oauth_client` list changes.

CI test APKs (`test-apk.yml`) are signed with a dedicated test key stored in the
`CI_TEST_KEYSTORE_BASE64` repository secret. Its fingerprints are registered in Firebase
(SHA-1 `E3:6E:3A:6F:CF:02:52:CE:EE:35:45:9D:DA:B3:DB:56:48:DF:5F:F8`), so Google Sign-In
works in those builds. If the secret is missing, CI falls back to a throwaway key; the build
still works, but Google Sign-In won't.

### Sign in with Apple (iOS only)

The Apple button only appears on iOS devices that support it. Android shows Google and
email only.

In the Apple Developer account (<https://developer.apple.com/account>):

1. **Identifiers**, then App IDs: register `dev.hubert.dosetime` and tick **Sign in with Apple**.
2. **Keys**: create a key with **Sign in with Apple** enabled and download the `.p8` file
   (you can download it once). Note the **Key ID** and your **Team ID**.
3. Apple is already enabled in Firebase, which is enough for sign-in on iPhone. For
   account deletion to revoke Apple tokens (App Store guideline 5.1.1(v)), open
   **Authentication**, then **Sign-in method**, then **Apple**, then
   **OAuth code flow configuration**. Enter the Team ID, Key ID and `.p8` contents
   yourself. They live only in the Firebase Console. Never commit the `.p8` file or
   paste it into the app.
4. A Services ID and return URL are only needed for web or Android Apple sign-in, which
   this app doesn't use.

In Xcode (on a Mac), open `ios/Runner.xcworkspace`. Then, under **Runner**, open
**Signing & Capabilities**:

- Select your team. The bundle ID is already `dev.hubert.dosetime`.
- Confirm the **Sign in with Apple** capability. `ios/Runner/Runner.entitlements` is
  already added and referenced.

### Email templates (optional)

Under **Authentication**, then **Templates**, set the sender name to "DoseAlert" for the
verification and password-reset emails. The Spark plan has a daily email quota, which
is plenty for normal use.

## Account behaviour

- **Sign out** clears only the auth session. Local medications and reminders stay on
  the phone.
- **Delete account** asks the user to sign in again first, then deletes the Firebase
  user:
  - Email accounts confirm with their password.
  - Google accounts confirm through Google.
  - Apple accounts confirm through Apple, and the Apple token is revoked as App Store
    guideline 5.1.1(v) requires.
  - Local data is not deleted.
- **Linking accounts**: if Google or Apple sign-in hits an existing account with the same
  email, the app doesn't merge them automatically. It asks the user to sign in with their
  original method, then links the new provider to that account.
- **Apple "Hide My Email"**: private relay addresses (`…@privaterelay.appleid.com`) are
  stored as-is and work for email. Apple shares the user's name only on the first sign-in,
  so the app saves it to the Firebase profile at that moment.

## Not included yet

The app has no cloud sync, Firestore or caregiver features today. When cloud sync is
added, store each user's data under their Firebase UID with Firestore rules like this:

```
match /users/{uid}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
```

Caregiver access should be a separate, consent-based share. Sign-in alone does not
protect Firestore data.
