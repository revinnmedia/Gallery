import { getCurrentUser } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { getDict, getLocale } from "@/lib/i18n";
import Link from "next/link";
import { normalizeStatus } from "@/lib/orderStages";

export default async function VendorHome() {
  const user = await getCurrentUser();
  const dict = await getDict();
  const locale = await getLocale();
  if (!user || !user.vendor) return null;
  const vendorId = user.vendor.id;

  const [total, pending, completed, revenue, latestOrders] = await Promise.all([
    prisma.order.count({ where: { vendorId } }),
    prisma.order.count({ where: { vendorId, status: { in: ["NEW", "PENDING"] } } }),
    prisma.order.count({ where: { vendorId, status: "COMPLETED" } }),
    prisma.order.aggregate({
      where: { vendorId, paymentStatus: "PAID" },
      _sum: { total: true },
    }),
    prisma.order.findMany({
      where: { vendorId },
      orderBy: { createdAt: "desc" },
      take: 5,
      include: { customer: true },
    }),
  ]);

  if (user.vendor.status !== "APPROVED") {
    return (
      <div className="card p-6">
        <h2 className="text-xl font-bold mb-2">{dict.auth.vendorTitle}</h2>
        <p className="text-gray-700">{dict.auth.vendorPending}</p>
        <span className={`badge status-${user.vendor.status} mt-3 inline-block`}>
          {user.vendor.status}
        </span>
      </div>
    );
  }

  const stats = [
    [dict.vendor.stats.totalOrders, total],
    [dict.vendor.stats.pending, pending],
    [dict.vendor.stats.completed, completed],
    [
      dict.vendor.stats.revenue,
      `${(revenue._sum.total || 0).toFixed(2)} ${dict.common.sar}`,
    ],
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
        <h3 className="font-semibold mb-3">{dict.vendor.myOrders}</h3>
        {latestOrders.length === 0 ? (
          <p className="text-sm text-gray-500 text-center py-4">{dict.order.noOrders}</p>
        ) : (
          <ul className="divide-y">
            {latestOrders.map((o) => (
              <li key={o.id}>
                <Link
                  href={`/vendor/orders/${o.id}`}
                  className="flex items-center justify-between py-3 hover:bg-gray-50 px-2 rounded"
                >
                  <div>
                    <div className="text-xs text-gray-500">{o.code}</div>
                    <div className="text-sm">{o.customer.name}</div>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="text-sm">{o.total.toFixed(2)} {dict.common.sar}</span>
                    <span className={`badge status-${normalizeStatus(o.status)}`}>
                      {dict.order.status[normalizeStatus(o.status)]}
                    </span>
                  </div>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
