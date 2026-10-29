# Firebase Authentication setup (DoseAlert)

Sign-in in DoseAlert is **optional**. Medications, schedules, history and alarms stay
in the on-device SQLite database and work offline whether or not the user signs in.
This guide covers the console steps the code can't do for you.

Everything below works on the free **Spark** plan. Authentication (email/password,
Google, Apple) needs no billing. Don't upgrade to Blaze for this feature.

## 1. Create the DoseAlert Firebase project

The app is still configured for `fast-delivery-d8d5c`, which also hosts
`com.example.fast_delivery`. Give DoseAlert its own project:

1. Go to <https://console.firebase.google.com>, then **Add project**. Name it something like `dosealert`. Keep the Spark plan.
2. Register the apps:
   - **Android**: package name `dev.hubert.dosetime`.
   - **iOS**: bundle ID `dev.hubert.dosetime` (changed from the old `com.example.doseTime` placeholder).
3. Regenerate the config files from the project root:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=<your-new-project-id> --platforms=android,ios --android-package-name=dev.hubert.dosetime --ios-bundle-id=dev.hubert.dosetime
   ```

   This rewrites `lib/firebase_options.dart`, `android/app/google-services.json` and
   `firebase.json`, and adds `ios/Runner/GoogleService-Info.plist`. These files hold
   public client configuration, not secrets. Security comes from Firebase rules and
   Auth settings, not from hiding them.

Analytics and Crashlytics move to the new project along with Auth. Until you run
`flutterfire configure`, the app still talks to `fast-delivery-d8d5c`. Don't create
DoseAlert accounts there.

## 2. Enable sign-in providers

Firebase Console, then **Authentication**, then **Sign-in method**:

- **Email/Password**: enable it. Leave "Email link (passwordless)" off.
- **Google**: enable it and set a support email.
- **Apple**: enable it. See section 4 for the Apple values.

Under **Settings**, then **User account linking**, keep **"Link accounts that use the same
email"**. That's the default. The app expects one account per email and links a
second provider only after the user signs in with their original method.

Under **Settings**, then **Email enumeration protection**, leave it **on**. The app's
messages never reveal whether an email is registered.

## 3. Android: SHA fingerprints for Google Sign-In

Google Sign-In fails with `ApiException: 10` until your signing certificates are
registered. In Firebase Console, open **Project settings**, then the Android app,
then **Add fingerprint**:

- **Debug key** (local `flutter run`, read from `~/.android/debug.keystore` on this PC):
  - SHA-1 `0E:0C:D9:8F:0C:47:98:47:90:20:6A:00:3D:A3:86:D7:99:A6:67:F3`
  - SHA-256 `46:DD:D2:0B:C7:67:D2:56:9B:5E:17:33:CE:F2:61:96:1F:08:3E:DA:E1:7D:C7:96:AB:69:72:87:6C:3E:7F:4B`
- **Release/upload key** (the keystore in `android/key.properties`):

  ```bash
  keytool -list -v -keystore <path-to-your-upload-keystore.jks> -alias <your-key-alias>
  ```

- **Play App Signing key**: if Google Play signs your app, copy the SHA-1/SHA-256 from
  Play Console, then **Setup**, then **App signing**.

After adding fingerprints, download `google-services.json` again, or re-run
`flutterfire configure`.

The CI test APKs (`test-apk.yml`) are signed with a throwaway key generated on each
run, so Google Sign-In won't work in those builds. Email/password will.

## 4. Apple: Sign in with Apple (iOS only)

The Apple button only appears on iOS devices that support it. Android shows Google and
email only.

In the Apple Developer account (<https://developer.apple.com/account>):

1. **Identifiers**, then App IDs: register `dev.hubert.dosetime` and tick **Sign in with Apple**.
2. **Keys**: create a key with **Sign in with Apple** enabled and download the `.p8` file
   (you can download it once). Note the **Key ID** and your **Team ID**.
3. In Firebase Console, open **Authentication**, then **Apple**, and enter the Team ID,
   Key ID and the `.p8` contents. They live only in the Firebase Console. Never commit
   the `.p8` file or paste it into the app.
4. A Services ID and return URL are only needed for web or Android Apple sign-in, which
   this app doesn't use.

In Xcode (on a Mac), open `ios/Runner.xcworkspace`. Then, under **Runner**, open
**Signing & Capabilities**:

- Select your team. The bundle ID is already `dev.hubert.dosetime`.
- Confirm the **Sign in with Apple** capability. `ios/Runner/Runner.entitlements` is
  already added and referenced.

## 5. iOS: Google Sign-In URL scheme

After `flutterfire configure` adds `ios/Runner/GoogleService-Info.plist`, copy its
`REVERSED_CLIENT_ID` value into `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.XXXXXXXX</string> <!-- REVERSED_CLIENT_ID -->
    </array>
  </dict>
</array>
```

This value is left out on purpose: it only exists once the iOS app is registered in your
new project.

## 6. Email templates (optional)

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
