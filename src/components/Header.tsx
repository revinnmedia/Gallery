import Link from "next/link";
import type { Dictionary, Locale } from "@/lib/i18n";
import { LocaleSwitch } from "./LocaleSwitch";
import { LogoutBtn } from "./LogoutBtn";

type Props = {
  locale: Locale;
  dict: Dictionary;
  user: { id: string; name: string; role: string; hasVendor: boolean } | null;
};

export function Header({ locale, dict, user }: Props) {
  const dashboardHref =
    user?.role === "ADMIN"
      ? "/admin"
      : user?.role === "VENDOR"
      ? "/vendor"
      : "/orders";

  return (
    <header className="bg-white border-b border-gray-200 sticky top-0 z-30">
      <div className="container-app flex items-center justify-between gap-4">
        <Link href="/" className="flex items-center gap-2 text-brand-700 font-extrabold text-xl">
          <span className="inline-block w-8 h-8 rounded-lg bg-brand-600 text-white grid place-items-center">
            م
          </span>
          {dict.appName}
        </Link>

        <nav className="hidden md:flex items-center gap-5 text-sm text-gray-700">
          <Link href="/" className="hover:text-brand-700">{dict.nav.home}</Link>
          <Link href="/browse" className="hover:text-brand-700">{dict.nav.browse}</Link>
          {user && user.role === "CUSTOMER" && (
            <Link href="/orders" className="hover:text-brand-700">{dict.nav.orders}</Link>
          )}
          {!user && (
            <Link href="/become-vendor" className="hover:text-brand-700">{dict.nav.vendorRegister}</Link>
          )}
        </nav>

        <div className="flex items-center gap-2">
          <LocaleSwitch current={locale} />
          {user ? (
            <>
              <Link href={dashboardHref} className="btn btn-secondary text-sm">
                {dict.nav.dashboard}
              </Link>
              <LogoutBtn label={dict.nav.logout} />
            </>
          ) : (
            <>
              <Link href="/login" className="btn btn-secondary text-sm">{dict.nav.login}</Link>
              <Link href="/register" className="btn btn-primary text-sm">{dict.nav.register}</Link>
            </>
          )}
        </div>
      </div>
    </header>
  );
}
