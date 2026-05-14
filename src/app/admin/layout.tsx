import { redirect } from "next/navigation";
import Link from "next/link";
import { getCurrentUser } from "@/lib/auth";
import { getDict } from "@/lib/i18n";

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const user = await getCurrentUser();
  if (!user) redirect("/login");
  if (user.role !== "ADMIN") redirect("/");
  const dict = await getDict();

  return (
    <div className="container-app py-6 grid md:grid-cols-[220px_1fr] gap-6">
      <aside className="card p-4 h-fit">
        <h2 className="font-bold mb-3 text-brand-700">{dict.admin.dashboard}</h2>
        <nav className="flex md:flex-col gap-1 text-sm">
          <Link href="/admin" className="px-3 py-2 rounded hover:bg-gray-100">Overview</Link>
          <Link href="/admin/vendors" className="px-3 py-2 rounded hover:bg-gray-100">{dict.admin.vendors}</Link>
          <Link href="/admin/users" className="px-3 py-2 rounded hover:bg-gray-100">{dict.admin.users}</Link>
          <Link href="/admin/orders" className="px-3 py-2 rounded hover:bg-gray-100">{dict.admin.orders}</Link>
          <Link href="/admin/categories" className="px-3 py-2 rounded hover:bg-gray-100">{dict.admin.categories}</Link>
        </nav>
      </aside>
      <section>{children}</section>
    </div>
  );
}
