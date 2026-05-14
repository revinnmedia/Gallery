import Link from "next/link";
import { getCurrentUser } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { getDict } from "@/lib/i18n";

export default async function VendorOrders() {
  const user = await getCurrentUser();
  const dict = await getDict();
  if (!user?.vendor) return null;

  const orders = await prisma.order.findMany({
    where: { vendorId: user.vendor.id },
    include: { customer: true, items: true },
    orderBy: { createdAt: "desc" },
  });

  return (
    <div className="space-y-3">
      <h2 className="text-xl font-bold">{dict.vendor.myOrders}</h2>
      {orders.length === 0 ? (
        <div className="card p-10 text-center text-gray-500">{dict.order.noOrders}</div>
      ) : (
        <div className="card divide-y">
          {orders.map((o) => (
            <Link
              key={o.id}
              href={`/vendor/orders/${o.id}`}
              className="p-4 flex flex-wrap items-center justify-between gap-3 hover:bg-gray-50"
            >
              <div>
                <div className="text-xs text-gray-500">{o.code}</div>
                <div className="font-semibold">{o.customer.name}</div>
                <div className="text-sm text-gray-500">
                  {o.items.length} items — {o.total.toFixed(2)} {dict.common.sar}
                </div>
              </div>
              <div className="flex gap-2">
                <span className={`badge status-${o.paymentStatus}`}>{o.paymentStatus}</span>
                <span className={`badge status-${o.status}`}>
                  {dict.order.status[o.status]}
                </span>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
