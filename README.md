# RenditaLab — Analisi Finanziaria Immobiliare

> ROI, cashflow netto e break-even su affitti brevi (STR), flip e investimenti immobiliari. In tempo reale.

SaaS single-file per investitori immobiliari, host Airbnb e agenti. Calcolo con cedolare secca, mutuo, commissioni OTA e scenari di occupazione.

---

## Stack
- **Frontend**: HTML + CSS + JS vanilla, single-file (`index.html`)
- **DB + Auth**: Supabase (Postgres + RLS) — project `amzjefyegfxkpzjifynj`
- **Pagamenti**: Stripe (4 tier: Free / Pro / Pro+ / Agency)
- **Email**: Resend
- **Error tracking**: Sentry (SDK 8.55.0 — disattivo finché `SENTRY_DSN` è vuoto)
- **Hosting**: Vercel — dominio `rendimax.app`

---

## Struttura repo
```
/
├── index.html               # App completa (landing + calcolatore + auth + admin)
├── privacy-policy.html       # Legale
├── termini-e-condizioni.html # Legale
├── cookie-policy.html        # Legale
├── 404.html                  # Redirect alla root
├── robots.txt                # SEO + AI crawler
├── sitemap.xml               # SEO
├── llms.txt                  # GEO (citabilità da AI)
├── vercel.json               # Redirect + security headers
└── .gitignore
```

---

## Deploy (Vercel)
Push su `main` → deploy automatico. Il dominio `rendimax.app` è collegato dalla dashboard Vercel (NON serve `CNAME`).

---

## Configurazione richiesta (esterna al repo)
- **Supabase Auth**: Site URL e Redirect URLs → `https://rendimax.app/*` (rimuovere eventuali `/appnetto/`).
- **Stripe**: success/cancel URL → `https://rendimax.app/?success=1` / `?canceled=1`. Webhook → edge function `stripe-webhook`. Price ID: `PRM` (Pro mensile), `PRY` (Pro annuale), `PPM` (Pro+), `AGM` (Agency).
- **Email**: configurare provider per `@rendimax.app` (support@, privacy@) — al momento non attive.
- **Sentry**: impostare `SENTRY_DSN` in `index.html` per attivare l'error tracking.

---

## Nota legale
I calcoli hanno scopo informativo e non costituiscono consulenza finanziaria (art. 21 e 94 TUF, D.Lgs. 58/1998). Rendimax non è intermediario finanziario autorizzato.
