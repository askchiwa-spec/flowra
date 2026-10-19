# FlowrA Technology Africa Limited — Website

Where business flows and Africa grows.

## Project structure

```
FlowrA Website/
├── index.html          ← main entry point
├── css/
│   ├── styles.css      ← all styles + dark/light mode tokens
│   └── animations.css  ← keyframes + scroll-reveal classes
├── js/
│   └── main.js         ← all interactivity
├── images/
│   ├── flowra-logo.png ← logo (exists)
│   └── ...             ← add images listed below
├── 404.html            ← real not-found page
├── nginx.conf          ← production nginx vhost (single source of truth)
├── deploy.sh           ← idempotent VPS deploy + verify
├── scripts/smoke-check.sh ← post-deploy live checks
├── .gitignore
└── README.md
```

## Images to add

Replace all placeholder images before going live:

| File | Usage | Recommended size |
|---|---|---|
| `images/hero-bg.jpg` | Hero section background | 1920×1080 px, dark/moody tone |
| `images/founder-chiwambo.jpg` | CEO photo (Team section) | 400×500 px min |
| `images/founder-abdul.jpg` | CIO photo (Team section) | 400×500 px min |
| `images/about-team.jpg` | About section office photo | 800×500 px min |
| `images/og-image.jpg` | Social share / OG preview | 1200×630 px |
| `images/favicon.png` | Browser tab icon | 512×512 px (or use flowra-logo.png) |

To swap a photo, simply replace the `src` attribute in `index.html`.  
Search for `<!-- Replace` to find all placeholder comments.

## Git setup

```bash
cd "FlowrA Website"
git init
git add .
git commit -m "Initial commit: FlowrA website v2"
git remote add origin git@github.com:YOUR_USERNAME/flowra-website.git
git push -u origin main
```

## VPS deployment

`nginx.conf` in this repo is the **only** nginx config. `deploy.sh` installs it.
Never edit `/etc/nginx/sites-available/flowra` by hand on the server.

First time, on the VPS as root:

```bash
git clone https://github.com/askchiwa-spec/flowra.git /var/www/flowra
sudo bash /var/www/flowra/deploy.sh
```

Every later deploy (after `git push origin main`):

```bash
sudo bash /var/www/flowra/deploy.sh
```

The script is idempotent: it installs missing packages, resets the webroot to
`origin/main`, issues the Let's Encrypt certificate if absent, installs
`nginx.conf`, runs `nginx -t` before reloading, confirms the live `index.html`
matches the deployed commit, then runs `scripts/smoke-check.sh`.

From your laptop, after any deploy:

```bash
bash scripts/smoke-check.sh
```

### Cache busting

CSS and JS are cached for one year. When you change `css/*.css` or `js/main.js`,
bump the `?v=` value on the three asset links in `index.html` or returning
visitors will keep the old files.

### DNS

`flowratech.com` and `www.flowratech.com` A records point at the VPS.
`www` is canonical; apex and plain HTTP redirect to it.

## Features

- **Dark / Light mode** — system preference detected on first load, toggle saved to localStorage
- **Custom cursor** — gold dot + ring, hides on touch devices
- **Loading screen** — FlowrA logo pulse, 1.5s
- **Scroll progress bar** — gold bar across top of page
- **Floating words** — large translucent words drift across the hero
- **Phone mockup** — animated WhatsApp chat in hero, loops every 9s
- **Scroll reveal** — elements animate in as you scroll
- **Counter animation** — stat numbers count up on scroll
- **3D card tilt** — product and founder cards tilt on mouse hover
- **Wave dividers** — SVG waves between every section (dark-mode aware)
- **Floating WhatsApp button** — expands on hover, bottom-right
- **Form floating labels** — modern input UX
- **Toast notification** — success feedback on form submit

## What to update before launch

1. Replace all placeholder images (see table above)
2. WhatsApp number is already set to `+255 765 111131`
3. Emails are already set under `@flowratech.com`
4. Domain is already set to `flowratech.com` in `nginx.conf`
5. In the Web3Forms dashboard, set **Block Spam → hCaptcha** so the captcha is enforced server-side
6. Add Google Analytics or your preferred analytics script
