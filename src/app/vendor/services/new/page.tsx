import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { getDict, getLocale } from "@/lib/i18n";
import { ServiceForm } from "@/components/vendor/ServiceForm";

export default async function NewServicePage() {
  const user = await getCurrentUser();
  if (!user?.vendor) redirect("/vendor");
  if (user.vendor.status !== "APPROVED") redirect("/vendor");

  const dict = await getDict();
  const locale = await getLocale();
  const categories = await prisma.category.findMany({ orderBy: { order: "asc" } });

  return (
    <div className="card p-6 max-w-2xl">
      <h2 className="text-xl font-bold mb-4">{dict.vendor.newService}</h2>
      <ServiceForm
        dict={dict}
        locale={locale}
        categories={categories.map((c) => ({ id: c.id, name: locale === "ar" ? c.nameAr : c.nameEn }))}
      />
    </div>
  );
}
