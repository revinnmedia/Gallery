import { prisma } from "@/lib/prisma";
import { getDict } from "@/lib/i18n";
import { VendorActions } from "@/components/admin/VendorActions";

export default async function AdminVendors() {
  const dict = await getDict();
  const vendors = await prisma.vendor.findMany({
    include: { user: true, _count: { select: { services: true, orders: true } } },
    orderBy: { createdAt: "desc" },
  });

  return (
    <div className="space-y-3">
      <h2 className="text-xl font-bold">{dict.admin.vendors}</h2>
      <div className="card divide-y">
        {vendors.map((v) => (
          <div key={v.id} className="p-4 flex flex-wrap items-center justify-between gap-3">
            <div>
              <div className="font-semibold">{v.shopName}</div>
              <div className="text-sm text-gray-500">
                {v.user.name} — {v.user.email} — {v.city}
              </div>
              <div className="text-xs text-gray-500">
                {v._count.services} services · {v._count.orders} orders · ★ {v.rating.toFixed(1)}
              </div>
            </div>
            <div className="flex items-center gap-2">
              <span className={`badge status-${v.status}`}>{v.status}</span>
              <VendorActions id={v.id} status={v.status} />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
