"use client";

import { useRouter } from "next/navigation";
import type { Locale } from "@/lib/i18n";

export function LocaleSwitch({ current }: { current: Locale }) {
  const router = useRouter();
  const next: Locale = current === "ar" ? "en" : "ar";

  function switchLocale() {
    document.cookie = `locale=${next}; path=/; max-age=${60 * 60 * 24 * 365}`;
    router.refresh();
  }

  return (
    <button
      onClick={switchLocale}
      className="btn btn-secondary text-sm"
      aria-label="Switch language"
      title={next === "ar" ? "العربية" : "English"}
    >
      {next === "ar" ? "ع" : "EN"}
    </button>
  );
}
