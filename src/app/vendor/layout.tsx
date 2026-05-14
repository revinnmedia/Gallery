import { redirect } from "next/navigation";
import Link from "next/link";
import { getCurrentUser } from "@/lib/auth";
import { getDict } from "@/lib/i18n";

export default async function VendorLayout({ children }: { children: React.ReactNode }) {
  const user = await getCurrentUser();
  if (!user) redirect("/login");
  if (user.role !== "VENDOR") redirect("/");
  const dict = await getDict();

  return (
    <div className="container-app py-6 grid md:grid-cols-[220px_1fr] gap-6">
      <aside className="card p-4 h-fit">
        <h2 className="font-bold mb-3 text-brand-700">{dict.vendor.dashboard}</h2>
        <nav className="flex md:flex-col gap-1 text-sm">
          <Link href="/vendor" className="px-3 py-2 rounded hover:bg-gray-100">
            {dict.admin.dashboard}
          </Link>
          <Link href="/vendor/services" className="px-3 py-2 rounded hover:bg-gray-100">
            {dict.vendor.myServices}
          </Link>
          <Link href="/vendor/orders" className="px-3 py-2 rounded hover:bg-gray-100">
            {dict.vendor.myOrders}
          </Link>
          <Link href="/vendor/profile" className="px-3 py-2 rounded hover:bg-gray-100">
            {dict.vendor.profile}
          </Link>
        </nav>
      </aside>
      <section>{children}</section>
    </div>
  );
}
