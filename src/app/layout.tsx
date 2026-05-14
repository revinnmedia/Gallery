import "./globals.css";
import type { Metadata } from "next";
import { getDict, getLocale, isRTL } from "@/lib/i18n";
import { Header } from "@/components/Header";
import { getCurrentUser } from "@/lib/auth";

export const metadata: Metadata = {
  title: "مطبعة | Matba3ah",
  description: "منصة طباعة تربطك بأفضل المطابع — Uber for printing.",
};

export default async function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const locale = await getLocale();
  const dict = await getDict();
  const user = await getCurrentUser();
  return (
    <html lang={locale} dir={isRTL(locale) ? "rtl" : "ltr"}>
      <head>
        <link
          rel="preconnect"
          href="https://fonts.googleapis.com"
        />
        <link
          rel="stylesheet"
          href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;500;600;700;800&display=swap"
        />
      </head>
      <body>
        <Header
          locale={locale}
          dict={dict}
          user={
            user
              ? {
                  id: user.id,
                  name: user.name,
                  role: user.role,
                  hasVendor: !!user.vendor,
                }
              : null
          }
        />
        <main>{children}</main>
        <footer className="border-t border-gray-200 mt-16 py-8 text-center text-sm text-gray-500">
          <div className="container-app">
            © {new Date().getFullYear()} {dict.appName} — {dict.tagline}
          </div>
        </footer>
      </body>
    </html>
  );
}
