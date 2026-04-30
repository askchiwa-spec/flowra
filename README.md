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
├── nginx.conf          ← VPS server config
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
| `images/founder-omar.jpg` | Sales lead photo (Team section) | 400×500 px min |
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

### 1. Upload files

```bash
# From your local machine:
rsync -avz --exclude '.git' "FlowrA Website/" user@YOUR_VPS_IP:/var/www/flowra/
```

Or clone directly on the server after pushing to GitHub:

```bash
sudo mkdir -p /var/www/flowra
sudo chown $USER:$USER /var/www/flowra
git clone git@github.com:YOUR_USERNAME/flowra-website.git /var/www/flowra
```

### 2. Configure nginx

```bash
sudo cp /var/www/flowra/nginx.conf /etc/nginx/sites-available/flowra
sudo ln -s /etc/nginx/sites-available/flowra /etc/nginx/sites-enabled/flowra
sudo nginx -t        # test config
sudo systemctl reload nginx
```

### 3. SSL certificate (free, via Let's Encrypt)

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d flowratech.com -d www.flowratech.com
```

Certbot auto-renews. Verify: `sudo certbot renew --dry-run`

### 4. Update DNS

Point your domain A records to the VPS IP:
- `flowratech.com` → `YOUR_VPS_IP`
- `www.flowratech.com` → `YOUR_VPS_IP`

### Deploying updates

```bash
# On the VPS:
cd /var/www/flowra
git pull origin main
```

Or push from local with rsync:

```bash
rsync -avz --exclude '.git' --exclude '.DS_Store' "FlowrA Website/" user@YOUR_VPS_IP:/var/www/flowra/
```

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
5. Connect contact form to a backend (Formspree, Netlify Forms, or custom API)
6. Add Google Analytics or your preferred analytics script
