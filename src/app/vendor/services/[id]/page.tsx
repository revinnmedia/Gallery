import { notFound, redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { getDict, getLocale } from "@/lib/i18n";
import { ServiceForm } from "@/components/vendor/ServiceForm";

export default async function EditService({ params }: { params: { id: string } }) {
  const user = await getCurrentUser();
  if (!user?.vendor) redirect("/vendor");
  const dict = await getDict();
  const locale = await getLocale();
  const service = await prisma.service.findUnique({ where: { id: params.id } });
  if (!service || service.vendorId !== user.vendor.id) notFound();
  const categories = await prisma.category.findMany({ orderBy: { order: "asc" } });

  return (
    <div className="card p-6 max-w-2xl">
      <h2 className="text-xl font-bold mb-4">{dict.common.edit}</h2>
      <ServiceForm
        dict={dict}
        locale={locale}
        categories={categories.map((c) => ({ id: c.id, name: locale === "ar" ? c.nameAr : c.nameEn }))}
        initial={{
          id: service.id,
          categoryId: service.categoryId,
          titleAr: service.titleAr,
          titleEn: service.titleEn || undefined,
          descAr: service.descAr || undefined,
          descEn: service.descEn || undefined,
          basePrice: service.basePrice,
          leadTimeDays: service.leadTimeDays,
          minQty: service.minQty,
          active: service.active,
        }}
      />
    </div>
  );
}
