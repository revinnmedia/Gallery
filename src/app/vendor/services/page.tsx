import Link from "next/link";
import { getCurrentUser } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { getDict, getLocale } from "@/lib/i18n";
import { ToggleServiceBtn } from "@/components/vendor/ToggleServiceBtn";

export default async function VendorServices() {
  const user = await getCurrentUser();
  const dict = await getDict();
  const locale = await getLocale();
  if (!user?.vendor) return null;

  const services = await prisma.service.findMany({
    where: { vendorId: user.vendor.id },
    include: { category: true },
    orderBy: { createdAt: "desc" },
  });

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-bold">{dict.vendor.myServices}</h2>
        <Link href="/vendor/services/new" className="btn btn-primary">
          {dict.vendor.addService}
        </Link>
      </div>

      {user.vendor.status !== "APPROVED" ? (
        <p className="card p-6 text-gray-600">{dict.auth.vendorPending}</p>
      ) : services.length === 0 ? (
        <div className="card p-10 text-center text-gray-500">—</div>
      ) : (
        <div className="card divide-y">
          {services.map((s) => (
            <div key={s.id} className="p-4 flex flex-wrap items-center justify-between gap-3">
              <div>
                <div className="text-xs text-gray-500">
                  {locale === "ar" ? s.category.nameAr : s.category.nameEn}
                </div>
                <div className="font-semibold">{locale === "ar" ? s.titleAr : s.titleEn || s.titleAr}</div>
                <div className="text-sm text-gray-500">
                  {s.basePrice.toFixed(2)} {dict.common.sar} — {s.leadTimeDays} {locale === "ar" ? "أيام" : "days"}
                </div>
              </div>
              <div className="flex items-center gap-2">
                <span className={`badge ${s.active ? "status-PAID" : "status-UNPAID"}`}>
                  {s.active ? (locale === "ar" ? "نشطة" : "Active") : (locale === "ar" ? "متوقفة" : "Inactive")}
                </span>
                <ToggleServiceBtn id={s.id} active={s.active} />
                <Link href={`/vendor/services/${s.id}`} className="btn btn-secondary text-sm">{dict.common.edit}</Link>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
