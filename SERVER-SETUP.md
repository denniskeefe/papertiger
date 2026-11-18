# Server Setup Guide

A plain-language guide to getting a web server ready for a site made with Paper Tiger Site Generator. No prior server experience is needed.

## What you need

- A **Debian or Ubuntu** virtual server (a "VPS") from any hosting provider. The smallest plan is plenty for a static site.
- The server's **IP address** and a way to log in: a **root password** or an **SSH key**.
- A Mac or Linux computer. On Windows, use [WSL](https://learn.microsoft.com/windows/wsl/install).
- Optional: a **domain name**. Without one you can still test using a free address (see below).

## 1. Create the server

1. Sign up with a hosting provider and create a new server ("droplet", "instance", "Linode" and so on, depending on the provider).
2. Choose **Ubuntu** (a current LTS release) or **Debian** as the operating system.
3. Pick the cheapest size. Pick a region close to your audience.
4. Set a root password or add an SSH key when asked.
5. When it finishes, note the server's **IP address**. It looks like `203.0.113.10`.

## 2. Open the ports

Most providers allow web traffic by default. If the site does not load later, check any "firewall" setting in the provider's dashboard and allow:

- **Port 80** (HTTP)
- **Port 443** (HTTPS, only needed if you use a domain with HTTPS)
- **Port 22** (SSH, so you can log in)

## 3. Generate and deploy your site

1. Open the generator and fill in the form. Choose your pages and click **Generate**.
2. In the **Put it online** panel, click the download button to get the deploy file.
3. Open **Terminal** (Mac: press Cmd+Space, type "Terminal", press Enter).
4. Paste the line the panel shows, for example:

   ```bash
   bash ~/Downloads/deploy-your-site.sh
   ```

5. Answer the questions:
   - **Server IP address:** the address from step 1.
   - **Username:** press Enter to use `root`.
   - **Domain name:** leave blank for a free test address, or enter your domain.
   - **Email (only if you entered a domain):** used for a free HTTPS certificate. Leave blank to skip HTTPS.
6. If asked, type your server password. Nothing shows on screen while you type. That is normal.
7. When it finishes, it prints your site's address.

The first time you connect, your computer may ask whether to trust the server. The deploy file accepts it automatically for a new server.

## Testing without a domain

If you leave the domain blank and your server address is an IP, the deploy file uses a free test address such as:

```
your-site.203.0.113.10.nip.io
```

The `nip.io` service points any name ending in an IP address to that IP. It serves over plain HTTP, which is fine for testing. If the address does not load on your network, try a different DNS server (for example `8.8.8.8`) or add a line to your computer's hosts file.

## Using a real domain

1. Buy a domain from a registrar.
2. In the registrar's DNS settings, create an **A record** for your domain (and for `www`) pointing to your server's IP address.
3. Wait for DNS to update. This can take from a few minutes to a few hours. Check with:

   ```bash
   dig +short yourdomain.com
   ```

   It should print your server's IP.
4. Run the deploy file again. Enter the domain, then your email to get HTTPS. Running it again replaces the old site.

## Updating the site

Generate a new site in the app, download the new deploy file, and run it with the same server and domain. The old site is replaced.

## Troubleshooting

| Problem | What to try |
| --- | --- |
| "Could not connect" | Check the IP address and username. Confirm the server is running and port 22 is open. |
| Site does not load | Open port 80 in the provider's firewall. On the server, run `systemctl status apache2`. |
| HTTPS certificate fails | The domain must already point at the server's IP, and ports 80 and 443 must be open. |
| "Permission denied" | Wrong password, or the account has no sudo access. Use `root` or a user with sudo. |
| Shows the Apache default page | You opened the bare IP. Use the domain or test address you deployed with. |
| Deploy file says it is damaged | Download it again. Do not open or edit it in a text editor. |

## Good practice

- Use an **SSH key** instead of a password for the server, and consider a non-root user with sudo.
- Keep the server updated: `apt-get update && apt-get upgrade`.
- Only deploy sites for lawful, authorized purposes.

## Hosting on Vercel instead

Paper Tiger Site Generator itself is a static page. To publish the generator on Vercel, import this GitHub repository in the Vercel dashboard. Use the **Other** framework preset, leave the build command empty, and keep the output directory as the repository root. Generated sites can also be uploaded to any static host.
