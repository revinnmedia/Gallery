import { prisma } from "@/lib/prisma";
import { getDict } from "@/lib/i18n";

export default async function AdminUsers() {
  const dict = await getDict();
  const users = await prisma.user.findMany({
    include: { _count: { select: { orders: true } } },
    orderBy: { createdAt: "desc" },
  });

  return (
    <div className="space-y-3">
      <h2 className="text-xl font-bold">{dict.admin.users}</h2>
      <div className="card divide-y">
        {users.map((u) => (
          <div key={u.id} className="p-4 flex flex-wrap items-center justify-between gap-3">
            <div>
              <div className="font-semibold">{u.name}</div>
              <div className="text-sm text-gray-500">{u.email}</div>
              <div className="text-xs text-gray-500">{u.phone}</div>
            </div>
            <div className="flex items-center gap-3 text-sm">
              <span className="text-gray-500">{u._count.orders} orders</span>
              <span className="badge bg-gray-100 text-gray-800">{u.role}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
