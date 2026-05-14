import Link from "next/link";
import { notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getDict, getLocale } from "@/lib/i18n";

export default async function VendorPublic({ params }: { params: { id: string } }) {
  const dict = await getDict();
  const locale = await getLocale();
  const vendor = await prisma.vendor.findUnique({
    where: { id: params.id },
    include: {
      services: {
        where: { active: true },
        include: { category: true },
      },
      reviews: { include: { user: true }, orderBy: { createdAt: "desc" }, take: 10 },
    },
  });
  if (!vendor || vendor.status !== "APPROVED") notFound();

  return (
    <div className="container-app py-8 space-y-6">
      <div className="card p-6">
        <div className="flex items-start gap-4">
          <div className="w-16 h-16 rounded-xl bg-brand-50 text-brand-700 grid place-items-center text-2xl font-bold">
            {(locale === "ar" ? vendor.shopName : vendor.shopNameEn || vendor.shopName).charAt(0)}
          </div>
          <div className="flex-1">
            <h1 className="text-2xl font-bold">
              {locale === "ar" ? vendor.shopName : vendor.shopNameEn || vendor.shopName}
            </h1>
            <p className="text-sm text-gray-500">{vendor.city}</p>
            <p className="text-yellow-600 text-sm">
              ★ {vendor.rating.toFixed(1)} ({vendor.reviewCount} {dict.common.reviews})
            </p>
          </div>
        </div>
        {vendor.description && (
          <p className="text-gray-700 mt-4 whitespace-pre-line">{vendor.description}</p>
        )}
      </div>

      <div>
        <h2 className="text-xl font-bold mb-3">{dict.vendor.myServices}</h2>
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-3">
          {vendor.services.map((s) => (
            <Link key={s.id} href={`/services/${s.id}`} className="card p-5 hover:border-brand-400">
              <div className="text-xs text-gray-500 mb-1">
                {locale === "ar" ? s.category.nameAr : s.category.nameEn}
              </div>
              <h3 className="font-semibold">{locale === "ar" ? s.titleAr : s.titleEn || s.titleAr}</h3>
              <div className="text-brand-700 font-bold mt-1">
                {dict.common.from} {s.basePrice.toFixed(2)} {dict.common.sar}
              </div>
            </Link>
          ))}
        </div>
      </div>

      {vendor.reviews.length > 0 && (
        <div>
          <h2 className="text-xl font-bold mb-3">{locale === "ar" ? "التقييمات" : "Reviews"}</h2>
          <ul className="space-y-3">
            {vendor.reviews.map((r) => (
              <li key={r.id} className="card p-4">
                <div className="flex justify-between">
                  <strong className="text-sm">{r.user.name}</strong>
                  <span className="text-yellow-600 text-sm">★ {r.rating}</span>
                </div>
                {r.comment && <p className="text-sm text-gray-600 mt-1">{r.comment}</p>}
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
