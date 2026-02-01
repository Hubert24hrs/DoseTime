# Data Safety Form Answers for Google Play Store

This document contains the answers for the Google Play Store Data Safety questionnaire.

## Data Collection Overview

| Data Type | Collected | Shared | Required | Purpose |
|-----------|-----------|--------|----------|---------|
| Health info (Medication) | ✅ Yes | ❌ No | ✅ Yes | App functionality |
| Device identifiers | ✅ Yes | ✅ Yes (Analytics) | ❌ No | Analytics, Crash reports |
| Crash logs | ✅ Yes | ✅ Yes (Firebase) | ❌ No | App stability |

## Detailed Responses

### 1. Does your app collect or share any of the required user data types?
**Yes**

### 2. Is all of the user data collected by your app encrypted in transit?
**Yes** - All network communications use HTTPS/TLS

### 3. Do you provide a way for users to request that their data be deleted?
**Yes** - Users can delete all data by:
- Using "Delete All Data" option in Settings
- Uninstalling the app (all local data is removed)

---

## Data Types Collected

### Health Information
- **Type**: Medications, dosages, schedule times
- **Purpose**: App functionality (medication reminders)
- **Collection**: Required for app to function
- **Processing**: Stored locally only, never transmitted
- **Sharing**: Not shared with any third parties

### Device or Other IDs
- **Type**: Anonymous device identifier (Firebase)
- **Purpose**: Analytics and crash reporting
- **Collection**: Optional (can disable analytics)
- **Processing**: Processed by Firebase
- **Sharing**: Shared with Google (Firebase)

### App Activity
- **Type**: Pages visited, features used
- **Purpose**: Analytics to improve app
- **Collection**: Optional
- **Processing**: Processed by Firebase Analytics
- **Sharing**: Shared with Google (Firebase)

### App Diagnostics
- **Type**: Crash logs, performance data
- **Purpose**: App stability and performance
- **Collection**: Automatic on crash
- **Processing**: Processed by Firebase Crashlytics
- **Sharing**: Shared with Google (Firebase)

---

## Third-Party Libraries

| Library | Purpose | Data Accessed |
|---------|---------|---------------|
| Firebase Analytics | Usage analytics | Device ID, app activity |
| Firebase Crashlytics | Crash reporting | Crash logs, device info |
| RevenueCat | In-app purchases | Purchase receipts |

---

## Security Measures

- ✅ Data encrypted at rest (AES-256)
- ✅ Secure key storage (Android Keystore)
- ✅ No cloud transmission of health data
- ✅ HTTPS for all API calls

---

## Privacy Policy URL
`https://hubert24hrs.github.io/DoseTime/privacy-policy`
