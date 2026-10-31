# Google Play Data Safety answers for DoseAlert

Use these answers in Play Console under **App content → Data safety**. They describe
the release build: no ads, an optional Firebase account, and Google Play purchases
through RevenueCat.

## Overview questions

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (HTTPS/TLS) |
| Which account creation methods does your app support? | **Username and password** (email), plus **OAuth** (Google; Apple on iOS). Account creation is optional. |
| Do you provide a way for users to request that their data be deleted? | **Yes**. In the app: Manage → Account → Delete account. On the web: `https://hubert24hrs.github.io/DoseTime/delete-account.html` |

## Data types collected

Medication and health data stays on the device and is never sent off it, so it is
**not** "collected" in Play's sense. Don't declare it.

| Category → type | Collected | Shared | Optional? | Purposes |
|---|---|---|---|---|
| Personal info → **Email address** | Yes | No | Optional (only if the user creates an account) | Account management |
| Personal info → **Name** | Yes | No | Optional | Account management |
| Personal info → **User IDs** | Yes | No | Optional | Account management |
| Financial info → **Purchase history** | Yes | No | Optional (only if the user buys Pro) | App functionality (verifying Pro) |
| App activity → **App interactions** | Yes | No | Required | Analytics |
| App info and performance → **Crash logs** | Yes | No | Required | App functionality, Analytics |
| App info and performance → **Diagnostics** | Yes | No | Required | App functionality, Analytics |
| Device or other IDs → **Device or other IDs** | Yes | No | Required | Analytics |

"Shared" is **No** throughout. Firebase (Google) and RevenueCat act as service
providers processing data on our behalf, which Play does not count as sharing.

Answer **"No"** for advertising and marketing. The release build has no ads SDK, and the advertising-ID permissions that Firebase Analytics adds are removed in the manifest (ad-ID collection is off). Play Console → App content → **Advertising ID**: answer **No**.

## App content declarations (Play Console → App content)

- **Ads:** No, the app does not contain ads.
- **Target audience:** 18 and over is simplest (not designed for children).
- **Health apps declaration:** Medication or treatment management (reminders only).
  The app is not a medical device.
- **Exact alarm permission (`SCHEDULE_EXACT_ALARM`):** the user grants it. No
  declaration is needed. `USE_EXACT_ALARM` has been removed.
- **Full-screen intent (`USE_FULL_SCREEN_INTENT`):** if Play asks, choose "Alarm" and
  explain that medication dose alarms ring and show on the lock screen at dose time.
- **Financial features:** None.
- **Government app:** No.

## Third-party SDKs

| SDK | Purpose | Data |
|---|---|---|
| Firebase Authentication | Optional accounts | Email, name, user ID |
| Firebase Analytics | Usage analytics | App interactions, device/app instance IDs |
| Firebase Crashlytics | Crash reporting | Crash logs, diagnostics |
| RevenueCat | Google Play purchases | Purchase history, anonymous app user ID |

## Policy URLs

- Privacy policy: `https://hubert24hrs.github.io/DoseTime/`
- Terms of service: `https://hubert24hrs.github.io/DoseTime/terms.html`
- Account deletion: `https://hubert24hrs.github.io/DoseTime/delete-account.html`

