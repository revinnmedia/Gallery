import { notFound } from "next/navigation";
import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { getDict, getLocale } from "@/lib/i18n";
import { OrderForm } from "@/components/order/OrderForm";
import { getCurrentUser } from "@/lib/auth";

export default async function ServiceDetail({ params }: { params: { id: string } }) {
  const dict = await getDict();
  const locale = await getLocale();
  const user = await getCurrentUser();

  const service = await prisma.service.findUnique({
    where: { id: params.id },
    include: {
      vendor: true,
      category: true,
      options: true,
    },
  });
  if (!service) notFound();

  const reviews = await prisma.review.findMany({
    where: { vendorId: service.vendorId },
    include: { user: true },
    orderBy: { createdAt: "desc" },
    take: 5,
  });

  return (
    <div className="container-app py-8 grid lg:grid-cols-3 gap-6">
      <div className="lg:col-span-2 space-y-4">
        <div className="card p-6">
          <div className="text-xs text-gray-500 mb-2">
            {locale === "ar" ? service.category.nameAr : service.category.nameEn}
          </div>
          <h1 className="text-2xl font-bold">
            {locale === "ar" ? service.titleAr : service.titleEn || service.titleAr}
          </h1>
          <Link
            href={`/vendors/${service.vendor.id}`}
            className="text-sm text-brand-700 mt-1 inline-block"
          >
            {locale === "ar" ? service.vendor.shopName : service.vendor.shopNameEn || service.vendor.shopName} — {service.vendor.city}
          </Link>
          {service.descAr && (
            <p className="text-gray-700 mt-4 whitespace-pre-line">
              {locale === "ar" ? service.descAr : service.descEn || service.descAr}
            </p>
          )}
          <div className="mt-5 pt-4 border-t border-gray-100 flex flex-wrap gap-4 text-sm">
            <div>
              <span className="text-gray-500">{dict.vendor.leadTime}: </span>
              <strong>{service.leadTimeDays}</strong>
            </div>
            <div>
              <span className="text-gray-500">{dict.common.from}: </span>
              <strong>{service.basePrice.toFixed(2)} {dict.common.sar}</strong>
            </div>
            <div>
              <span className="text-gray-500">{locale === "ar" ? "أقل كمية" : "Min qty"}: </span>
              <strong>{service.minQty}</strong>
            </div>
          </div>
        </div>

        {reviews.length > 0 && (
          <div className="card p-6">
            <h2 className="font-bold mb-3">
              {locale === "ar" ? "آخر التقييمات" : "Recent reviews"}
            </h2>
            <ul className="space-y-3">
              {reviews.map((r) => (
                <li key={r.id} className="border-b last:border-b-0 pb-3 last:pb-0">
                  <div className="flex items-center justify-between">
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

      <aside className="lg:col-span-1">
        <div className="card p-5 sticky top-20">
          <h3 className="font-bold mb-3">{dict.order.placeOrder}</h3>
          {user && user.role === "CUSTOMER" ? (
            <OrderForm
              dict={dict}
              service={{
                id: service.id,
                titleAr: service.titleAr,
                basePrice: service.basePrice,
                minQty: service.minQty,
                options: service.options.map((o) => ({
                  id: o.id,
                  nameAr: o.nameAr,
                  nameEn: o.nameEn,
                  priceDelta: o.priceDelta,
                })),
              }}
              locale={locale}
            />
          ) : (
            <div className="text-sm text-gray-600 space-y-3">
              <p>
                {locale === "ar"
                  ? "سجّل الدخول لتقديم الطلب"
                  : "Sign in to place an order"}
              </p>
              <Link href="/login" className="btn btn-primary w-full">
                {dict.nav.login}
              </Link>
            </div>
          )}
        </div>
      </aside>
    </div>
  );
}
