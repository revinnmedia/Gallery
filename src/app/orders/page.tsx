import Link from "next/link";
import { redirect } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getCurrentUser } from "@/lib/auth";
import { getDict, getLocale } from "@/lib/i18n";
import { OrderStepper } from "@/components/order/OrderStepper";
import { normalizeStatus } from "@/lib/orderStages";

export default async function OrdersPage() {
  const user = await getCurrentUser();
  if (!user) redirect("/login");
  const dict = await getDict();
  const locale = await getLocale();

  const orders = await prisma.order.findMany({
    where: { customerId: user.id },
    include: { vendor: true, items: true },
    orderBy: { createdAt: "desc" },
  });

  return (
    <div className="container-app py-8">
      <h1 className="text-2xl font-bold mb-6">{dict.nav.orders}</h1>
      {orders.length === 0 ? (
        <div className="card p-10 text-center text-gray-500">{dict.order.noOrders}</div>
      ) : (
        <div className="space-y-3">
          {orders.map((o) => (
            <Link
              key={o.id}
              href={`/orders/${o.id}`}
              className="card p-4 hover:border-brand-400 block space-y-3"
            >
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <div className="text-xs text-gray-500">{dict.order.orderCode}: {o.code}</div>
                  <div className="font-semibold">
                    {locale === "ar" ? o.vendor.shopName : o.vendor.shopNameEn || o.vendor.shopName}
                  </div>
                  <div className="text-sm text-gray-600">
                    {o.items.length} {locale === "ar" ? "صنف" : "items"} — {o.total.toFixed(2)} {dict.common.sar}
                  </div>
                </div>
                <span className={`badge status-${normalizeStatus(o.status)}`}>
                  {dict.order.status[normalizeStatus(o.status)]}
                </span>
              </div>
              <OrderStepper status={o.status} dict={dict} />
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
