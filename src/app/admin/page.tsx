import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { getDict } from "@/lib/i18n";

export default async function AdminHome() {
  const dict = await getDict();
  const [users, vendors, pendingVendors, orders, revenue, latest] = await Promise.all([
    prisma.user.count(),
    prisma.vendor.count({ where: { status: "APPROVED" } }),
    prisma.vendor.count({ where: { status: "PENDING_APPROVAL" } }),
    prisma.order.count(),
    prisma.order.aggregate({ where: { paymentStatus: "PAID" }, _sum: { total: true } }),
    prisma.order.findMany({
      include: { customer: true, vendor: true },
      orderBy: { createdAt: "desc" },
      take: 10,
    }),
  ]);

  const stats = [
    [dict.admin.stats.users, users],
    [dict.admin.stats.vendors, `${vendors} (+${pendingVendors})`],
    [dict.admin.stats.orders, orders],
    [dict.admin.stats.revenue, `${(revenue._sum.total || 0).toFixed(2)} ${dict.common.sar}`],
  ] as const;

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        {stats.map(([label, val]) => (
          <div key={label} className="card p-4">
            <div className="text-sm text-gray-500">{label}</div>
            <div className="text-2xl font-bold mt-1">{val}</div>
          </div>
        ))}
      </div>

      <div className="card p-5">
        <div className="flex justify-between items-center mb-3">
          <h3 className="font-semibold">{dict.admin.orders}</h3>
          <Link href="/admin/orders" className="text-sm text-brand-700">→</Link>
        </div>
        {latest.length === 0 ? (
          <p className="text-sm text-gray-500 text-center py-4">{dict.order.noOrders}</p>
        ) : (
          <ul className="divide-y">
            {latest.map((o) => (
              <li key={o.id} className="py-3 flex justify-between items-center gap-3">
                <div>
                  <div className="text-xs text-gray-500">{o.code}</div>
                  <div className="text-sm">{o.customer.name} → {o.vendor.shopName}</div>
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-sm">{o.total.toFixed(2)} {dict.common.sar}</span>
                  <span className={`badge status-${o.status}`}>
                    {dict.order.status[o.status]}
                  </span>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
