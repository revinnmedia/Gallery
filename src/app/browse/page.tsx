import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { getDict, getLocale } from "@/lib/i18n";

export default async function BrowsePage({
  searchParams,
}: {
  searchParams: { cat?: string; q?: string; city?: string };
}) {
  const dict = await getDict();
  const locale = await getLocale();

  const [categories, services] = await Promise.all([
    prisma.category.findMany({ orderBy: { order: "asc" } }),
    prisma.service.findMany({
      where: {
        active: true,
        vendor: { status: "APPROVED" },
        ...(searchParams.cat ? { category: { slug: searchParams.cat } } : {}),
        ...(searchParams.q
          ? {
              OR: [
                { titleAr: { contains: searchParams.q } },
                { titleEn: { contains: searchParams.q } },
              ],
            }
          : {}),
        ...(searchParams.city ? { vendor: { city: searchParams.city, status: "APPROVED" } } : {}),
      },
      include: { vendor: true, category: true },
      orderBy: { createdAt: "desc" },
      take: 60,
    }),
  ]);

  const cities = await prisma.vendor.findMany({
    where: { status: "APPROVED" },
    select: { city: true },
    distinct: ["city"],
  });

  return (
    <div className="container-app py-8">
      <h1 className="text-2xl font-bold mb-4">{dict.home.categoriesTitle}</h1>

      <form className="flex flex-wrap gap-2 mb-6" action="/browse" method="get">
        <input
          name="q"
          defaultValue={searchParams.q || ""}
          placeholder={dict.common.search}
          className="input flex-1 min-w-[200px]"
        />
        <select name="city" defaultValue={searchParams.city || ""} className="select">
          <option value="">{dict.common.city}</option>
          {cities.map((c) => (
            <option key={c.city} value={c.city}>
              {c.city}
            </option>
          ))}
        </select>
        <button type="submit" className="btn btn-primary">{dict.common.search}</button>
      </form>

      <div className="flex flex-wrap gap-2 mb-6">
        <Link
          href="/browse"
          className={`badge ${!searchParams.cat ? "bg-brand-600 text-white" : "bg-gray-100 text-gray-700"}`}
        >
          {locale === "ar" ? "الكل" : "All"}
        </Link>
        {categories.map((c) => (
          <Link
            key={c.id}
            href={`/browse?cat=${c.slug}`}
            className={`badge ${searchParams.cat === c.slug ? "bg-brand-600 text-white" : "bg-gray-100 text-gray-700"}`}
          >
            {locale === "ar" ? c.nameAr : c.nameEn}
          </Link>
        ))}
      </div>

      {services.length === 0 ? (
        <div className="card p-10 text-center text-gray-500">—</div>
      ) : (
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
          {services.map((s) => (
            <Link key={s.id} href={`/services/${s.id}`} className="card p-5 hover:border-brand-400 transition">
              <div className="flex items-center justify-between text-xs text-gray-500 mb-2">
                <span>{locale === "ar" ? s.category.nameAr : s.category.nameEn}</span>
                <span>{s.leadTimeDays} {locale === "ar" ? "أيام" : "days"}</span>
              </div>
              <h3 className="font-semibold mb-1">{locale === "ar" ? s.titleAr : s.titleEn || s.titleAr}</h3>
              <div className="text-sm text-gray-500 mb-3">{locale === "ar" ? s.vendor.shopName : s.vendor.shopNameEn || s.vendor.shopName} — {s.vendor.city}</div>
              <div className="text-brand-700 font-bold">
                {dict.common.from} {s.basePrice.toFixed(2)} {dict.common.sar}
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
