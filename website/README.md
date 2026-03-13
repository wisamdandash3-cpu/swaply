# Swaply — Landing Website (getswaply.de)

Landing site for the Swaply dating app, inspired by [happn](https://www.happn.com/). Uses colors and branding from the Flutter app (`lib/app_colors.dart`).

## Structure

- `index.html` — Home: hero carousel, trust bar, App Store / Google Play CTAs, features, footer
- `css/style.css` — Styles (Warm Sand, Forest Green, Playfair Display)
- `js/main.js` — Hero carousel (4s), language toggle (EN / DE / AR), persisted in `localStorage`
- `legal/` — Terms, Privacy, Cookies, Safety, FAQ (short summaries + link to app for full text)

## Run locally

Serve the `website` folder with any static server, e.g.:

```bash
cd website
npx serve .
# or: python3 -m http.server 8080
```

Then open `http://localhost:3000` (or 8080).

## Deploy to getswaply.de

1. **Upload** the contents of `website/` to your host (FTP, SFTP, or Git-based deploy).
2. **Point the domain** getswaply.de to the root where `index.html` is (document root).
3. **Optional**: Enable HTTPS (Let’s Encrypt) on your hosting.

### Vercel / Netlify

- **Vercel (موصى به)**: انشر من داخل مجلد الموقع حتى تُنشر الملفات الصحيحة:
  ```bash
  cd ~/swaply/website
  vercel --prod
  ```
  إذا ربطت المشروع بـ GitHub، يمكن بدلاً من ذلك ضبط **Root Directory** على `website` في إعدادات المشروع على Vercel.
- **Netlify**: Publish directory = `website`, no build step.

### After app store links are ready

In `index.html`, replace the `#` in the CTA buttons:

- App Store: `href="https://apps.apple.com/app/swaply/..."`  
- Google Play: `href="https://play.google.com/store/apps/details?id=..."`

## Languages

EN, DE, AR are supported via the header language buttons. The choice is stored in `localStorage` under `swaply_website_lang`.
