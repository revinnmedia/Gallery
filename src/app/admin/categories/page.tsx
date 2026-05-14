import { prisma } from "@/lib/prisma";
import { getDict, getLocale } from "@/lib/i18n";
import { CategoryForm } from "@/components/admin/CategoryForm";

export default async function AdminCategories() {
  const dict = await getDict();
  const locale = await getLocale();
  const categories = await prisma.category.findMany({
    include: { _count: { select: { services: true } } },
    orderBy: { order: "asc" },
  });

  return (
    <div className="space-y-4">
      <h2 className="text-xl font-bold">{dict.admin.categories}</h2>
      <div className="card divide-y">
        {categories.map((c) => (
          <div key={c.id} className="p-4 flex justify-between items-center">
            <div>
              <div className="font-semibold">{locale === "ar" ? c.nameAr : c.nameEn}</div>
              <div className="text-xs text-gray-500">/{c.slug}</div>
            </div>
            <div className="text-sm text-gray-500">{c._count.services} services</div>
          </div>
        ))}
      </div>
      <CategoryForm dict={dict} />
    </div>
  );
}
