import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

const CATEGORIES = [
  { slug: "business-cards", nameAr: "كرت شخصي", nameEn: "Business Cards", order: 1 },
  { slug: "letterhead", nameAr: "ورق رسمي", nameEn: "Letterhead", order: 2 },
  { slug: "envelopes", nameAr: "ظرف", nameEn: "Envelopes", order: 3 },
  { slug: "folders", nameAr: "فولدر", nameEn: "Folders", order: 4 },
  { slug: "receipt-books", nameAr: "سند قبض", nameEn: "Receipt Books", order: 5 },
  { slug: "payment-vouchers", nameAr: "سند صرف", nameEn: "Payment Vouchers", order: 6 },
  { slug: "thank-you-cards", nameAr: "كرت شكر", nameEn: "Thank You Cards", order: 7 },
  { slug: "greeting-cards", nameAr: "بطاقة تهنئة", nameEn: "Greeting Cards", order: 8 },
  { slug: "invitations", nameAr: "بطاقة دعوة", nameEn: "Invitation Cards", order: 9 },
  { slug: "notebooks", nameAr: "دفتر ملاحظات", nameEn: "Notebooks", order: 10 },
  { slug: "stickers", nameAr: "استيكر", nameEn: "Stickers", order: 11 },
  { slug: "invoices", nameAr: "فواتير", nameEn: "Invoices", order: 12 },
  { slug: "certificates", nameAr: "شهادات", nameEn: "Certificates", order: 13 },
  { slug: "brochures", nameAr: "بروشور", nameEn: "Brochures", order: 14 },
  { slug: "catalogs", nameAr: "كتالوج", nameEn: "Catalogs", order: 15 },
  { slug: "menus", nameAr: "منيو", nameEn: "Menus", order: 16 },
  { slug: "calendars", nameAr: "روزنامة", nameEn: "Calendars", order: 17 },
  { slug: "id-cards", nameAr: "بطاقة تعريف", nameEn: "ID Cards", order: 18 },
  { slug: "books", nameAr: "كتب", nameEn: "Books", order: 19 },
  { slug: "dossiers", nameAr: "دوسيات", nameEn: "Dossiers", order: 20 },
  { slug: "paper-labels", nameAr: "ليبيل ورق", nameEn: "Paper Labels", order: 21 },
  { slug: "bookmarks", nameAr: "فواصل كتب", nameEn: "Bookmarks", order: 22 },
  { slug: "table-stands", nameAr: "ستاند طاولة", nameEn: "Table Stands", order: 23 },
];

async function main() {
  console.log("Seeding...");

  for (const c of CATEGORIES) {
    await prisma.category.upsert({
      where: { slug: c.slug },
      update: c,
      create: c,
    });
  }
  console.log(`Categories: ${CATEGORIES.length}`);

  const adminPass = await bcrypt.hash("admin123", 10);
  await prisma.user.upsert({
    where: { email: "admin@matba3ah.test" },
    update: {},
    create: {
      name: "Admin",
      email: "admin@matba3ah.test",
      password: adminPass,
      role: "ADMIN",
    },
  });

  const custPass = await bcrypt.hash("customer123", 10);
  await prisma.user.upsert({
    where: { email: "customer@matba3ah.test" },
    update: {},
    create: {
      name: "Demo Customer",
      email: "customer@matba3ah.test",
      phone: "+966500000000",
      password: custPass,
      role: "CUSTOMER",
    },
  });

  const vendorPass = await bcrypt.hash("vendor123", 10);

  const vendors = [
    {
      email: "press1@matba3ah.test",
      name: "Ahmed Al-Tabba",
      shopName: "مطبعة النور",
      shopNameEn: "Al-Noor Press",
      city: "الرياض",
      description: "مطبعة متخصصة في الطباعة الرقمية وطباعة الكروت والبروشورات بجودة عالية وأسعار منافسة.",
    },
    {
      email: "press2@matba3ah.test",
      name: "Khalid Al-Saeed",
      shopName: "مطابع السعيد",
      shopNameEn: "Al-Saeed Printing",
      city: "جدة",
      description: "خبرة ٢٠ عاماً في الطباعة التجارية والإعلانية. خدمة سريعة وتوصيل مجاني للطلبات الكبيرة.",
    },
    {
      email: "press3@matba3ah.test",
      name: "Fatimah Al-Otaibi",
      shopName: "مطبعة الإبداع",
      shopNameEn: "Creative Press",
      city: "الدمام",
      description: "طباعة إبداعية وتصاميم فريدة. متخصصون في بطاقات الزفاف والمناسبات الخاصة.",
    },
  ];

  for (const v of vendors) {
    await prisma.user.upsert({
      where: { email: v.email },
      update: {},
      create: {
        name: v.name,
        email: v.email,
        phone: "+966500000001",
        password: vendorPass,
        role: "VENDOR",
        vendor: {
          create: {
            shopName: v.shopName,
            shopNameEn: v.shopNameEn,
            city: v.city,
            description: v.description,
            status: "APPROVED",
          },
        },
      },
    });
  }

  const allCategories = await prisma.category.findMany();
  const allVendors = await prisma.vendor.findMany();

  const sample: Record<string, { titleAr: string; titleEn: string; descAr: string; basePrice: number; minQty: number; leadTimeDays: number }> = {
    "business-cards": {
      titleAr: "كروت شخصية فاخرة 250 جم",
      titleEn: "Premium Business Cards 250gsm",
      descAr: "كروت شخصية بطباعة فاخرة على ورق كوشيه 250 جرام، طباعة وجهين، يأتي مع تغليف بلاستيكي.",
      basePrice: 80,
      minQty: 100,
      leadTimeDays: 2,
    },
    "letterhead": {
      titleAr: "ورق رسمي A4 80 جم",
      titleEn: "A4 Letterhead 80gsm",
      descAr: "طباعة ورق رسمي بشعار الشركة، ورق أبيض 80 جرام.",
      basePrice: 120,
      minQty: 500,
      leadTimeDays: 3,
    },
    "envelopes": {
      titleAr: "أظرف A5 بشعار",
      titleEn: "A5 Envelopes with logo",
      descAr: "أظرف بمقاس A5 مع طباعة شعار وعنوان الشركة.",
      basePrice: 150,
      minQty: 250,
      leadTimeDays: 4,
    },
    "menus": {
      titleAr: "منيو مطعم لاميناتد",
      titleEn: "Laminated Restaurant Menu",
      descAr: "منيو مطعم بطباعة عالية الجودة مع تغليف لاميناتد ضد البقع.",
      basePrice: 25,
      minQty: 10,
      leadTimeDays: 2,
    },
    "stickers": {
      titleAr: "استيكرات دائرية مقطّعة",
      titleEn: "Die-cut Round Stickers",
      descAr: "استيكرات بأي شكل مع قص مخصص، فينيل مقاوم للماء.",
      basePrice: 40,
      minQty: 50,
      leadTimeDays: 3,
    },
    "invitations": {
      titleAr: "بطاقات دعوة زفاف فاخرة",
      titleEn: "Luxury Wedding Invitations",
      descAr: "بطاقات زفاف فاخرة مع طباعة هوت ستامب ذهبي وأظرف.",
      basePrice: 350,
      minQty: 50,
      leadTimeDays: 7,
    },
    "brochures": {
      titleAr: "بروشور ثلاثي الطي A4",
      titleEn: "A4 Tri-fold Brochure",
      descAr: "بروشور دعائي ثلاثي الطي ملون مزدوج الوجهين.",
      basePrice: 90,
      minQty: 100,
      leadTimeDays: 4,
    },
    "calendars": {
      titleAr: "روزنامة مكتبية",
      titleEn: "Desk Calendar",
      descAr: "روزنامة مكتبية بحامل ١٢ شهر، ورق مقوى.",
      basePrice: 35,
      minQty: 20,
      leadTimeDays: 5,
    },
  };

  for (const v of allVendors) {
    for (const cat of allCategories) {
      const conf = sample[cat.slug];
      if (!conf) continue;
      const existing = await prisma.service.findFirst({
        where: { vendorId: v.id, categoryId: cat.id, titleAr: conf.titleAr },
      });
      if (existing) continue;
      await prisma.service.create({
        data: {
          vendorId: v.id,
          categoryId: cat.id,
          titleAr: conf.titleAr,
          titleEn: conf.titleEn,
          descAr: conf.descAr,
          basePrice: conf.basePrice + Math.floor(Math.random() * 30),
          minQty: conf.minQty,
          leadTimeDays: conf.leadTimeDays,
          options: {
            create: [
              { nameAr: "تغليف فاخر", nameEn: "Premium packaging", priceDelta: 15 },
              { nameAr: "توصيل سريع", nameEn: "Express delivery", priceDelta: 25 },
            ],
          },
        },
      });
    }
  }

  console.log("Seed done.");
  console.log("\nDemo accounts:");
  console.log("  admin@matba3ah.test / admin123");
  console.log("  customer@matba3ah.test / customer123");
  console.log("  press1@matba3ah.test / vendor123");
  console.log("  press2@matba3ah.test / vendor123");
  console.log("  press3@matba3ah.test / vendor123");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
