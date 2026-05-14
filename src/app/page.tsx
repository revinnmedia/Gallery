import Link from "next/link";
import { getDict, getLocale } from "@/lib/i18n";
import { prisma } from "@/lib/prisma";

export default async function HomePage() {
  const dict = await getDict();
  const locale = await getLocale();
  const [categories, vendors] = await Promise.all([
    prisma.category.findMany({ orderBy: { order: "asc" } }),
    prisma.vendor.findMany({
      where: { status: "APPROVED" },
      orderBy: { rating: "desc" },
      take: 6,
    }),
  ]);

  return (
    <>
      <section className="bg-gradient-to-br from-brand-600 to-brand-800 text-white">
        <div className="container-app py-16 md:py-24">
          <div className="max-w-3xl">
            <h1 className="text-3xl md:text-5xl font-extrabold leading-tight">
              {dict.home.heroTitle}
            </h1>
            <p className="mt-4 text-lg text-brand-100">{dict.home.heroSubtitle}</p>
            <div className="mt-6 flex flex-wrap gap-3">
              <Link href="/browse" className="btn btn-primary bg-white text-brand-700 hover:bg-gray-100">
                {dict.home.browseCta}
              </Link>
              <Link href="/become-vendor" className="btn btn-secondary bg-transparent text-white border-white hover:bg-white/10">
                {dict.home.vendorCta}
              </Link>
            </div>
          </div>
        </div>
      </section>

      <section className="container-app py-12">
        <h2 className="text-2xl font-bold mb-6">{dict.home.categoriesTitle}</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-3">
          {categories.map((c) => (
            <Link
              key={c.id}
              href={`/browse?cat=${c.slug}`}
              className="card p-4 hover:border-brand-400 hover:shadow-sm transition text-center"
            >
              <div className="w-12 h-12 rounded-full bg-brand-50 text-brand-700 grid place-items-center mx-auto mb-2 text-xl font-bold">
                {(locale === "ar" ? c.nameAr : c.nameEn).charAt(0)}
              </div>
              <div className="text-sm font-medium">{locale === "ar" ? c.nameAr : c.nameEn}</div>
            </Link>
          ))}
        </div>
      </section>

      <section className="container-app py-12">
        <h2 className="text-2xl font-bold mb-6">{dict.home.stepsTitle}</h2>
        <div className="grid md:grid-cols-3 gap-4">
          {[
            [dict.home.step1, dict.home.step1Desc],
            [dict.home.step2, dict.home.step2Desc],
            [dict.home.step3, dict.home.step3Desc],
          ].map(([t, d], i) => (
            <div key={i} className="card p-6">
              <div className="w-10 h-10 rounded-lg bg-brand-600 text-white grid place-items-center font-bold mb-3">
                {i + 1}
              </div>
              <h3 className="font-semibold mb-1">{t}</h3>
              <p className="text-sm text-gray-600">{d}</p>
            </div>
          ))}
        </div>
      </section>

      {vendors.length > 0 && (
        <section className="container-app py-12">
          <h2 className="text-2xl font-bold mb-6">{dict.home.featuredTitle}</h2>
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
            {vendors.map((v) => (
              <Link key={v.id} href={`/vendors/${v.id}`} className="card p-5 hover:border-brand-400 transition">
                <div className="flex items-start gap-3">
                  <div className="w-14 h-14 rounded-lg bg-brand-50 text-brand-700 grid place-items-center font-bold text-xl">
                    {(locale === "ar" ? v.shopName : v.shopNameEn || v.shopName).charAt(0)}
                  </div>
                  <div className="flex-1">
                    <h3 className="font-semibold">
                      {locale === "ar" ? v.shopName : v.shopNameEn || v.shopName}
                    </h3>
                    <div className="text-sm text-gray-500">{v.city}</div>
                    <div className="text-sm text-yellow-600 mt-1">
                      ★ {v.rating.toFixed(1)} ({v.reviewCount} {dict.common.reviews})
                    </div>
                  </div>
                </div>
                {v.description && (
                  <p className="text-sm text-gray-600 mt-3 line-clamp-2">{v.description}</p>
                )}
              </Link>
            ))}
          </div>
        </section>
      )}
    </>
  );
}
