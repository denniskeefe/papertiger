# Paper Tiger Site Generator

A small, client-side generator for simple static landing pages. Fill in a short form, choose the pages you want, preview the result, and either download a ZIP or deploy it to your own Apache server with a single file.

Everything runs in the browser. Nothing you type is uploaded or stored.

## Features

- **Short form:** company name, city, state/region, country (optional), contact email, name suffix and visual style.
- **Selectable pages:** About, Approach, Services, FAQ, Contact, Privacy Policy and Terms of Use. Home is always included.
- **Four styles:** Slate, Sand, Forest and Ink (dark).
- **Live preview:** click through every generated page before downloading.
- **ZIP download:** a plain static site (HTML, CSS, `robots.txt`) that works on any static host.
- **Optional canary tripwire:** paste a Canarytoken URL you created and own, and the site gains a hidden honeypot page that notifies you if someone goes looking. Off unless you add a token.
- **One-file deploy:** download a single `deploy-<name>.sh` that contains the site and the installer. Run it in a terminal, answer a few questions, and it uploads and configures an Apache server over SSH. It can also obtain an HTTPS certificate from Let's Encrypt.
- **No domain needed to test:** leave the domain blank and the deploy file uses a free `nip.io` test address based on your server's IP.

## What a generated site contains

- **Home:** a tagline, a short welcome, "What we value", "How we work" and a "Get in touch" section. The welcome text and closing line vary with the company name and city.
- **Optional pages:** only the ones you tick. Navigation and footer links are built to match.
- **Generic copy only:** every page uses placeholder wording with no specific facts.
- **Optional honeypot:** if you supply a canary token, a hidden `private/` page and a matching `robots.txt` entry are added. It is not linked from the visible navigation.

## Canary tripwire

The generator can add a honeypot tripwire to a site so you learn when someone probes your infrastructure, without tracking ordinary visitors.

It uses [Canarytokens](https://canarytokens.org), the free tripwire project from Thinkst. You create and own the token; the generator only embeds the URL you paste.

1. At [canarytokens.org](https://canarytokens.org), create a **Web bug / URL token**. Give it a memo and the email or webhook where you want alerts. You control the alert address; it is never sent to this tool or any service it calls.
2. Copy the token URL and paste it into the **Canary tripwire** field in the form.
3. Generate and deploy as usual.

When a token is supplied, the site gains:

- A hidden page at `private/` that loads the token when opened.
- A `Disallow: /private/` line in `robots.txt`, which snoopers read precisely to find what is hidden.
- A non-rendered link to the path in the home page source, so a crawler or anyone viewing source also finds it.

None of this appears in the visible navigation or content, so an ordinary visitor never encounters it. The tripwire fires only when someone deliberately goes looking, and the only data captured is whatever Canarytokens records for your token (such as source IP and user agent) — there is no added fingerprinting. In the in-browser preview the honeypot page is shown inert, so reviewing your own site does not fire your alerts; the live token exists only in the downloaded ZIP and the deployed site.

This is a defensive tripwire for infrastructure you own, not a way to deanonymize or profile visitors to a page. The field accepts only a Canarytoken URL; it cannot be used to inject arbitrary scripts or tracking into the generated pages.

## Use cases and responsible use

- **Investigator opsec:** in authorized investigations, a contact address on a domain with no web presence is easy to dismiss or flag. A plain, generic landing page keeps research infrastructure separate from your real identity and employer, and gives a basic domain check something neutral to find. It is a thin layer, not anonymity. Use separate accounts, payments and hosting, and expect a determined person to see through it.
- **Authorized security testing:** red teams and researchers can use it for pretext infrastructure on engagements with written authorization and a defined scope.
- **Learning to spot thin fronts:** trust and safety staff, journalists and disinformation researchers can generate a page to see how little it takes to look superficially legitimate. Typical tells are generic copy, no verifiable people or registration, a recent domain, and no independent footprint.
- **Not for:** impersonating a real organization, inventing credentials, clients or reviews, deceiving people to cause harm, fraud, phishing, or running disinformation campaigns. These uses are outside the purpose of this tool and may be illegal. Check your local laws on pretexting and the terms of any platform you use.

## Content policy

The generator does not create fake testimonials, team members, licenses, certifications, client lists, awards, registration claims or payment forms. It will not be extended to do so. Use it only for lawful, authorized purposes, and do not use it to impersonate a real organization or to mislead people in order to harm them.

## Quick start

No build step and no dependencies to install. Open `index.html` in a browser.

1. Fill in the form and choose your pages.
2. Click **Generate** and review the preview.
3. Click **Download ZIP** to host it yourself, or use the **Put it online** panel to deploy.

## Deploy to your own server

Requirements: a Debian or Ubuntu server you can reach over SSH, a Mac or Linux computer (or WSL on Windows), and optionally a domain.

1. In **Put it online**, download the deploy file.
2. In Terminal, run:

   ```bash
   bash ~/Downloads/deploy-<name>.sh
   ```

3. Answer the prompts: server address, username and optional domain. Enter an email only if you want HTTPS.

If you use a domain, point its DNS A record at the server first. For a beginner-friendly walkthrough, see [SERVER-SETUP.md](SERVER-SETUP.md).

### What the installer does on the server

- Installs Apache (and certbot if you chose HTTPS).
- Puts the site in `/var/www/<domain>` with safe permissions.
- Creates an Apache virtual host with directory listing off, no server signature, basic security headers and per-site logs.
- Reloads Apache. Running it again with the same domain replaces the site.

### Using the installer directly

`deploy.sh` can be used on its own on the server:

```bash
sudo ./deploy.sh -z site.zip -d example.com [-e admin@example.com -s]
```

| Option | Meaning |
| --- | --- |
| `-z` | Path to the site ZIP (required) |
| `-d` | Domain to serve (required) |
| `-e` | Email for Let's Encrypt (required with `-s`) |
| `-s` | Get and install an HTTPS certificate |

## Deploy the generator itself on Vercel

1. In Vercel, choose **Add New... > Project** and import this repository.
2. Set the framework preset to **Other**. Leave the build command and output directory empty.
3. Deploy.

The whole repository is served as a static site.

## Project files

| File | Purpose |
| --- | --- |
| `index.html` | The whole app: form, site generator, preview and deploy-file builder |
| `deploy.sh` | Server-side installer for Apache on Debian/Ubuntu |
| `SERVER-SETUP.md` | Beginner guide to servers, domains and deploying |

A copy of `deploy.sh` is embedded in `index.html` so the app can build the one-file deploy. If you change `deploy.sh`, update the embedded copy as well.

## Limitations

- The browser cannot SSH into a server, so deployment always happens through the downloaded file in your own terminal.
- The deploy file supports Debian and Ubuntu with Apache only.
- Generated pages are intentionally simple and carry no analytics, forms or scripts. The one exception is the optional canary honeypot page, which loads the token URL you supply; it is hidden and off unless you add a token.
