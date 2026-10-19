#!/usr/bin/env python3
"""Build product pages from index.html's head/nav/footer + a body fragment.
Usage: python3 scripts/build-pages.py   (reads pages/*.body.html, writes *.html)
Keeps nav, footer, theme toggle and scripts identical to the homepage."""
import re, pathlib, html
root = pathlib.Path(__file__).resolve().parent.parent
idx = (root/'index.html').read_text()

head = idx[:idx.index('</head>')]
body_top = idx[idx.index('<body>'):idx.index('  <!-- ════════════════ HERO')]
footer = idx[idx.index('  <!-- ════════════════ FOOTER'):]
# drop the loader on subpages (no 1.5 s splash) and the floating-words/hero bits aren't included anyway
body_top = re.sub(r'  <!-- Loader -->\n  <div id="loader".*?</div>\n  </div>\n\n', '', body_top, flags=re.S)

def subpage(meta, body, name):
    h = head
    h = re.sub(r'<meta name="description" content="[^"]*">', f'<meta name="description" content="{html.escape(meta["desc"], quote=True)}">', h)
    h = re.sub(r'<meta property="og:title" content="[^"]*">', f'<meta property="og:title" content="{html.escape(meta["title"], quote=True)}">', h)
    h = re.sub(r'<meta property="og:description" content="[^"]*">', f'<meta property="og:description" content="{html.escape(meta["desc"], quote=True)}">', h)
    h = re.sub(r'<meta property="og:url" content="[^"]*">', f'<meta property="og:url" content="https://www.flowratech.com/{name}">', h)
    h = re.sub(r'<meta name="twitter:title" content="[^"]*">', f'<meta name="twitter:title" content="{html.escape(meta["title"], quote=True)}">', h)
    h = re.sub(r'<meta name="twitter:description" content="[^"]*">', f'<meta name="twitter:description" content="{html.escape(meta["desc"], quote=True)}">', h)
    h = re.sub(r'<link rel="canonical" href="[^"]*">', f'<link rel="canonical" href="https://www.flowratech.com/{name}">', h)
    h = re.sub(r'<title>[^<]*</title>', f'<title>{html.escape(meta["title"])}</title>', h)
    h = re.sub(r'  <link rel="preload" href="images/hero-bg[^\n]*\n', '', h)
    top = body_top.replace('href="#', 'href="index.html#')
    foot = footer.replace('href="#', 'href="index.html#')
    # on-page anchors inside the body stay as-is
    return h + '</head>\n' + top + body + '\n' + foot

pages = {
  'growth-engine.html': dict(title='AKILI Growth Engine — Grow your sales without growing your payroll | FlowrA',
      desc='AKILI Growth Engine turns the sales, receipts, orders and production data your business already has into clear monthly actions. No new hires. No new system to learn.'),
  'watu-hcm.html': dict(title='WATU HCM — HR, payroll and attendance for Tanzania | FlowrA',
      desc='WATU HCM: one monthly fee per company, every plan includes every module. Attendance, payroll with PAYE, NSSF, WCF, SDL and HESLB, leave, loans, recruitment and the employee app.'),
}
for name, meta in pages.items():
    body = (root/'pages'/(name.replace('.html','.body.html'))).read_text()
    (root/name).write_text(subpage(meta, body, name))
    print('built', name)
