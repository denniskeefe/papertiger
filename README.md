# Paper Tiger Site Generator

A small, client-side generator for simple static landing pages. Fill in a short form, choose the pages you want, and download a ready-to-host site.

## Features

- Form for company name, location, contact email, style and suffix.
- Selectable pages: About, Approach, Services, FAQ, Contact, Privacy Policy, Terms of Use.
- Four visual styles, live preview with page tabs, ZIP download.
- One-file deploy: a generated `deploy-<name>.sh` that uploads the site to a Debian/Ubuntu Apache server over SSH and can set up HTTPS with Let's Encrypt.
- Runs entirely in the browser. Nothing is uploaded or stored.

## Content policy

Generated pages use generic placeholder text only. The generator does not create fake testimonials, team members, licenses, certifications, client lists or registration claims, and it does not collect payments. Use it only for lawful, authorized purposes.

## Run locally

No build step is needed. Open `index.html` in a browser.

## Deploy the generator on Vercel

1. Push this repository to GitHub.
2. In Vercel, choose **Add New... > Project** and import the repository.
3. Framework preset: **Other**. Leave the build command and output directory empty.
4. Deploy.

## Deploy a generated site to your own server

See [SERVER-SETUP.md](SERVER-SETUP.md) for a step-by-step guide. In short: generate a site, download the deploy file, run `bash ~/Downloads/deploy-<name>.sh`, and answer the questions.

`deploy.sh` is the installer that runs on the server. It is embedded into the generated deploy file, and can also be used on its own:

```bash
sudo ./deploy.sh -z site.zip -d example.com [-e admin@example.com -s]
```

## Files

| File | Purpose |
| --- | --- |
| `index.html` | The whole app (form, generator, deploy-file builder) |
| `deploy.sh` | Server-side installer for Apache on Debian/Ubuntu |
| `SERVER-SETUP.md` | Beginner guide to servers, domains and deploying |
