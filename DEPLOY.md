# Dugsi – Production Build & Deployment

## Build outputs

| Platform | Command | Output |
|----------|---------|--------|
| Android APK | `flutter build apk --release` | `build/app/outputs/flutter-apk/app-release.apk` |
| Web PWA | `flutter build web --release` | `build/web/` |

## Deploy web to https://dugsi.so

### 1. Build (if not already done)

```bash
flutter clean
flutter pub get
flutter build web --release
```

For a custom base path (e.g. if app is at `https://dugsi.so/app/`):

```bash
flutter build web --release --base-href "/app/"
```

For root (`https://dugsi.so/`), default base href `/` is correct.

### 2. Backup current site (on server)

```bash
ssh user@server "cp -r /var/www/dugsi.so /var/www/dugsi.so.backup.$(date +%Y%m%d)"
```

(Adjust user, host, and path to your setup.)

### 3. Upload new build

**Option A – SCP**

```bash
scp -r build/web/* user@server:/var/www/dugsi.so/
```

**Option B – rsync (recommended)**

```bash
rsync -avz --delete build/web/ user@server:/var/www/dugsi.so/
```

`--delete` removes files on the server that are no longer in `build/web/`.

**Option C – FTP/SFTP**  
Upload everything inside `build/web/` to the site root (e.g. `/var/www/dugsi.so/` or your docroot).

### 4. Server: recommended HTTP settings

- **HTTPS** only (required for PWA and service worker).
- **Compression**: enable gzip (or Brotli) for `.js`, `.json`, `.wasm`, `.html`, `.css`.
- **Caching**:
  - `index.html`: short or no cache (e.g. `Cache-Control: no-cache` or max-age 0) so users get updates.
  - `flutter_service_worker.js`: same as `index.html` (version in URL helps; avoid long cache).
  - Assets (e.g. under `assets/`, `canvaskit/`): long cache (e.g. 1 year) is fine; service worker and hashed filenames handle updates.

### 5. Cache invalidation (PWA updates)

- Each build gets a new **service worker version** (in `flutter_bootstrap.js` / `flutter.js`). New deployments register a new worker; when it activates, old caches are replaced.
- After deploy, ask users to:
  - **Hard refresh**: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (macOS).
  - Or **clear site data** for dugsi.so in browser settings.
- For “Install app” to show the new version, a hard refresh or clearing site data may be needed once.

### 6. Verify live site

- Open https://dugsi.so
- Check: app loads, login, student creation, EMIS number behavior.
- In DevTools (F12): Application → Service Workers – confirm worker is registered and no errors.
- Test “Add to Home Screen” / “Install” if available.

## Android APK

- **Path**: `build/app/outputs/flutter-apk/app-release.apk`
- Distribute via Play Store, direct download, or your chosen channel.
- For Play Store you may want App Bundles: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`.

## Quick pre-deploy checklist

- [ ] `flutter doctor` OK for Android and Chrome
- [ ] `flutter pub get` and `flutter clean` then `flutter pub get`
- [ ] `flutter build apk --release` and `flutter build web --release` succeed
- [ ] Backup current site before uploading
- [ ] Upload full `build/web/` contents to dugsi.so docroot
- [ ] HTTPS, compression, and cache headers configured
- [ ] Hard refresh / clear site data after deploy
- [ ] Smoke test: load, login, student create, EMIS, PWA install
