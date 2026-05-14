import { chromium } from "playwright";
import fs from "node:fs/promises";
import path from "node:path";

const OUT = "/tmp/screens";
await fs.mkdir(OUT, { recursive: true });

const BASE = "http://127.0.0.1:3000";

const pages = [
  { name: "01-home-ar", url: "/", locale: "ar" },
  { name: "02-browse-ar", url: "/browse", locale: "ar" },
  { name: "03-service-detail-ar", url: null, locale: "ar", findFirstService: true },
  { name: "04-login-ar", url: "/login", locale: "ar" },
  { name: "05-register-ar", url: "/register", locale: "ar" },
  { name: "06-become-vendor-ar", url: "/become-vendor", locale: "ar" },

  { name: "07-customer-orders", url: "/orders", locale: "ar", login: { email: "customer@matba3ah.test", password: "customer123" } },

  { name: "08-vendor-dashboard", url: "/vendor", locale: "ar", login: { email: "press1@matba3ah.test", password: "vendor123" } },
  { name: "09-vendor-services", url: "/vendor/services", locale: "ar", login: { email: "press1@matba3ah.test", password: "vendor123" } },
  { name: "10-vendor-orders", url: "/vendor/orders", locale: "ar", login: { email: "press1@matba3ah.test", password: "vendor123" } },
  { name: "11-vendor-add-service", url: "/vendor/services/new", locale: "ar", login: { email: "press1@matba3ah.test", password: "vendor123" } },
  { name: "12-vendor-profile", url: "/vendor/profile", locale: "ar", login: { email: "press1@matba3ah.test", password: "vendor123" } },

  { name: "13-admin-overview", url: "/admin", locale: "ar", login: { email: "admin@matba3ah.test", password: "admin123" } },
  { name: "14-admin-vendors", url: "/admin/vendors", locale: "ar", login: { email: "admin@matba3ah.test", password: "admin123" } },
  { name: "15-admin-users", url: "/admin/users", locale: "ar", login: { email: "admin@matba3ah.test", password: "admin123" } },
  { name: "16-admin-orders", url: "/admin/orders", locale: "ar", login: { email: "admin@matba3ah.test", password: "admin123" } },
  { name: "17-admin-categories", url: "/admin/categories", locale: "ar", login: { email: "admin@matba3ah.test", password: "admin123" } },

  { name: "18-home-en", url: "/", locale: "en" },
  { name: "19-browse-en", url: "/browse", locale: "en" },
];

const browser = await chromium.launch({ args: ["--no-sandbox"] });

async function shot(p) {
  const ctx = await browser.newContext({
    viewport: { width: 1280, height: 900 },
    deviceScaleFactor: 1.5,
    locale: p.locale === "ar" ? "ar-SA" : "en-US",
  });
  await ctx.addCookies([
    {
      name: "locale",
      value: p.locale,
      domain: "127.0.0.1",
      path: "/",
    },
  ]);

  const page = await ctx.newPage();

  if (p.login) {
    const res = await page.request.post(`${BASE}/api/auth/login`, {
      data: p.login,
      headers: { "Content-Type": "application/json" },
    });
    if (!res.ok()) {
      console.log(`  login fail for ${p.name}`);
    }
  }

  let url = p.url;
  if (p.findFirstService) {
    await page.goto(`${BASE}/browse`, { waitUntil: "networkidle" });
    const href = await page.locator("a[href^='/services/']").first().getAttribute("href");
    url = href;
  }

  await page.goto(`${BASE}${url}`, { waitUntil: "networkidle", timeout: 20000 });
  await page.waitForTimeout(800);
  await page.screenshot({
    path: path.join(OUT, `${p.name}.png`),
    fullPage: true,
  });
  await ctx.close();
  console.log(`  ✓ ${p.name}`);
}

for (const p of pages) {
  try {
    await shot(p);
  } catch (e) {
    console.log(`  ✗ ${p.name}: ${e.message}`);
  }
}

await browser.close();
console.log("done");
