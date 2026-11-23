// End-to-end smoke test for index.html: fill the form, generate a site,
// and verify every download the app produces.
// Run from the repo root: node tests/smoke.mjs  (after `npm ci` in tests/)
import { chromium } from "playwright";
import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { pathToFileURL } from "node:url";
import assert from "node:assert/strict";

const ROOT = resolve(import.meta.dirname, "..");
const DEPLOY_SH = readFileSync(join(ROOT, "deploy.sh"), "utf8");
const TMP = mkdtempSync(join(tmpdir(), "papertiger-smoke-"));

const browser = await chromium.launch();
const page = await browser.newPage({ acceptDownloads: true });
const pageErrors = [];
page.on("pageerror", e => pageErrors.push(e.message));

let failed = 0;
async function test(name, fn) {
  try { await fn(); console.log(`ok   ${name}`); }
  catch (e) { failed++; console.log(`FAIL ${name}\n     ${e.message.split("\n").join("\n     ")}`); }
}

async function download(selector) {
  const [dl] = await Promise.all([page.waitForEvent("download"), page.click(selector)]);
  const path = join(TMP, dl.suggestedFilename());
  await dl.saveAs(path);
  return { name: dl.suggestedFilename(), path };
}

async function fillAndGenerate({ canary = "" } = {}) {
  await page.fill("#name", "Northgate Holdings");
  await page.fill("#city", "Austin");
  await page.fill("#region", "TX");
  await page.fill("#email", "contact@example.com");
  await page.fill("#canary", canary);
  await page.click("#f button[type=submit]");
}

await page.goto(pathToFileURL(join(ROOT, "index.html")).href);
await page.waitForFunction(() => typeof window.JSZip === "function");

await test("page checkboxes render", async () => {
  assert.ok(await page.locator("input[name=page]").count() > 0, "no page checkboxes");
});

await test("invalid canary URL is rejected", async () => {
  await fillAndGenerate({ canary: "https://evil.example.com/x" });
  assert.equal(await page.isVisible("#canaryErr"), true, "canary error not shown");
  assert.equal(await page.isHidden("#deploy"), true, "site generated despite invalid canary");
});

await page.check("input[name=page]", { force: true }); // ensure at least one optional page
const checked = await page.locator("input[name=page]:checked").count();

await test("generating shows preview, tabs and deploy panel", async () => {
  await fillAndGenerate();
  assert.equal(await page.isVisible("#frame"), true, "preview hidden");
  assert.match(await page.getAttribute("#frame", "srcdoc"), /Northgate Holdings/);
  assert.equal(await page.locator("#tabs button").count(), checked + 1, "tab count != pages + Home");
  assert.equal(await page.isVisible("#deploy"), true, "deploy panel hidden");
  assert.equal(await page.textContent("#dRun"), "bash ~/Downloads/deploy-northgate-holdings.sh");
});

await test("site ZIP contains every generated page", async () => {
  const { name, path } = await download("#dl");
  assert.equal(name, "northgate-holdings.zip");
  const files = await page.evaluate(async b64 => Object.keys((await JSZip.loadAsync(b64, { base64: true })).files),
    readFileSync(path).toString("base64"));
  for (const f of ["index.html", "styles.css"]) assert.ok(files.includes(f), `${f} missing from ZIP`);
  assert.equal(files.filter(f => f.endsWith(".html")).length, checked + 1, "HTML file count != pages + Home");
});

await test("Download deploy.sh matches deploy.sh", async () => {
  await page.click("#deploy summary:has-text('Advanced')");
  const { path } = await download("#dScript");
  assert.equal(readFileSync(path, "utf8"), DEPLOY_SH);
});

await test("one-file deploy script is valid bash and bundles deploy.sh + site", async () => {
  const { name, path } = await download("#dGet");
  assert.equal(name, "deploy-northgate-holdings.sh");
  const text = readFileSync(path, "utf8");
  execFileSync("bash", ["-n", path]);
  const [, afterRemote] = text.split("\n#__REMOTE_BEGIN__\n");
  assert.ok(afterRemote, "missing #__REMOTE_BEGIN__ marker");
  const [remote, b64] = afterRemote.split("\n#__ZIP_BEGIN__\n");
  assert.ok(b64, "missing #__ZIP_BEGIN__ marker");
  assert.equal(remote + "\n", DEPLOY_SH, "embedded remote installer differs from deploy.sh");
  assert.doesNotMatch(text, /__SLUG__/, "slug placeholder not substituted");
  writeFileSync(join(TMP, "site.zip"), Buffer.from(b64.trim(), "base64"));
  execFileSync("unzip", ["-tq", join(TMP, "site.zip")]);
});

await test("no uncaught page errors", async () => {
  assert.deepEqual(pageErrors, []);
});

await browser.close();
console.log(failed ? `\n${failed} failed` : "\nall passed");
process.exit(failed ? 1 : 0);
