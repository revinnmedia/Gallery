import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { getDict } from "@/lib/i18n";

export default async function AdminOrders() {
  const dict = await getDict();
  const orders = await prisma.order.findMany({
    include: { customer: true, vendor: true },
    orderBy: { createdAt: "desc" },
  });
  return (
    <div className="space-y-3">
      <h2 className="text-xl font-bold">{dict.admin.orders}</h2>
      <div className="card divide-y">
        {orders.map((o) => (
          <Link
            key={o.id}
            href={`/orders/${o.id}`}
            className="p-4 flex flex-wrap items-center justify-between gap-3 hover:bg-gray-50"
          >
            <div>
              <div className="text-xs text-gray-500">{o.code}</div>
              <div className="text-sm">{o.customer.name} → {o.vendor.shopName}</div>
            </div>
            <div className="flex items-center gap-3">
              <span className="text-sm">{o.total.toFixed(2)} {dict.common.sar}</span>
              <span className={`badge status-${o.paymentStatus}`}>{o.paymentStatus}</span>
              <span className={`badge status-${o.status}`}>
                {dict.order.status[o.status]}
              </span>
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
}
