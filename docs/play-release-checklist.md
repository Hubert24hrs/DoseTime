# DoseAlert: Google Play release checklist

Play Console app: **Dose Tracker** (`dev.hubert.dosetime`), developer account
**Hubert.dev** (personal). Latest upload: version code 3 (1.1.0), internal testing.
This release: **2.0.0 (10)**.

## Already done in code and Firebase (PR #6)

- [x] Test modes removed: no simulated purchases, no RevenueCat `test_` key, no AdMob
  test IDs.
- [x] Ads removed for launch.
- [x] Pro comes only from verified Google Play purchases (RevenueCat entitlement
  `DoseAlert Pro`).
- [x] Restricted permissions removed (`USE_EXACT_ALARM`, foreground service, battery
  optimization).
- [x] Privacy policy, terms, account-deletion page, Data Safety answers
  (`docs/data_safety.md`) and store listing (`docs/store_listing.md`) updated.
- [x] Play app-signing and upload key fingerprints registered in Firebase, so Google
  Sign-In works for Play installs.

## You need to do these (they need your accounts, money or secrets)

### 1. Merchant account and bank payout (required to sell Pro)
Play Console → **Setup → Payments profile** (or Monetize with Play → Set up a merchant
account):
- Create the payments profile with your legal name and address, and add your
  **Nigerian bank account** for payouts. You enter these details yourself; never share
  them in chat.
- Complete tax information.
- Payouts are in the currency of your bank account. Check Google's list of supported
  merchant countries and payout currencies when you add the account.

### 2. Create the Pro products (USD prices)
After the merchant account is active, open Play Console → **Monetize with Play →
Products**:

| Product | Type | Product ID | Default price |
|---|---|---|---|
| DoseAlert Pro Monthly | Subscription, base plan monthly auto-renewing | `dosealert_pro_monthly` (base plan `monthly`) | **USD 2.99** |
| DoseAlert Pro Yearly | Subscription, base plan yearly auto-renewing | `dosealert_pro_yearly` (base plan `yearly`) | **USD 24.99** |
| DoseAlert Pro Lifetime | One-time product | `dosealert_pro_lifetime` | **USD 49.99** |

Set the default price in **US dollars**. Google Play converts it for each country and
charges local currency where required (for example ₦ in Nigeria). The app always shows
the exact price Google Play returns.

### 3. RevenueCat (connects the products to the app)
At <https://app.revenuecat.com>:
1. Create a project and add a **Google Play** app with package `dev.hubert.dosetime`.
2. Upload a **Google Play service account JSON** credential. Follow RevenueCat's
   "Google Play service credentials" guide, which covers Google Cloud and Play Console
   API access.
3. Import the three products.
4. Create an entitlement with identifier **`DoseAlert Pro`**, exactly as written, and
   attach all three products.
5. Create a **current offering** with packages Monthly (`$rc_monthly`), Annual
   (`$rc_annual`) and Lifetime (`$rc_lifetime`).
6. Copy the **Google public API key** (`goog_…`) and add it as a GitHub secret
   (step 5).

### 4. Upload key (needed to publish 2.0.0)
Play only accepts bundles signed with the upload key whose
SHA-1 is `CC:C0:FE:7F:9B:A6:A9:6D:EB:84:3C:D6:86:80:54:3D:22:F2:BB:0B`.
- **If you find the `.jks`:** keep it and its passwords safe and go to step 5.
- **If it's lost:** Play Console → **Protected with Play → App signing → Upload key
  → Request reset**. Create a new upload key:

  ```bash
  keytool -genkeypair -v -keystore dosealert-upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
  ```

  Then export its certificate and upload it in the reset request:

  ```bash
  keytool -export -rfc -keystore dosealert-upload.jks -alias upload -file upload_certificate.pem
  ```

  Google usually approves this within a few days. After that, add the new key's
  SHA-1 and SHA-256 in Firebase as well.

### 5. GitHub secrets (lets CI build the signed AAB)
In PowerShell, from the folder that holds your upload keystore, run each command and
type the values when prompted:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("dosealert-upload.jks")) | gh secret set KEYSTORE_BASE64 -R Hubert24hrs/DoseTime
gh secret set KEYSTORE_PASSWORD -R Hubert24hrs/DoseTime
gh secret set KEY_ALIAS -R Hubert24hrs/DoseTime
gh secret set KEY_PASSWORD -R Hubert24hrs/DoseTime
gh secret set REVENUECAT_GOOGLE_API_KEY -R Hubert24hrs/DoseTime
```

Every push to `main` then produces a signed `release-aab` artifact in the
**DoseTime CI/CD → Release Android** job.

### 6. Closed test (Google requirement for personal accounts)
The Play dashboard requires a **closed test with at least 12 opted-in testers for at
least 14 days** before you can apply for production. Currently 0 testers have opted in.
1. Test and release → Closed testing: upload the 2.0.0 AAB and roll it out.
2. Add at least 12 testers (an email list or Google Group) and share the opt-in link.
3. Keep it running for 14 days, then click **Apply for production**.

### 7. Store listing and app content
- Main store listing: use `docs/store_listing.md`. The app name in Play is currently
  "Dose Tracker"; change it to "DoseAlert: Pill Reminder" if you like.
- App content: privacy policy URL `https://hubert24hrs.github.io/DoseTime/`, Data
  Safety from `docs/data_safety.md`, account deletion URL
  `https://hubert24hrs.github.io/DoseTime/delete-account.html`, ads = No, target
  audience, content rating, and the health apps declaration.
