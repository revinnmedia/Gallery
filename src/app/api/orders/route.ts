import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { getSession } from "@/lib/auth";
import { generateOrderCode } from "@/lib/utils";
import { z } from "zod";

const schema = z.object({
  serviceId: z.string(),
  qty: z.number().int().positive(),
  options: z.array(z.string()).optional().default([]),
  notes: z.string().optional(),
  address: z.string().optional(),
  city: z.string().optional(),
  phone: z.string().optional(),
  fileUrl: z.string().optional(),
});

export async function POST(req: Request) {
  const session = await getSession();
  if (!session || session.role !== "CUSTOMER") {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  const body = await req.json().catch(() => null);
  const parsed = schema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid input" }, { status: 400 });
  }
  const d = parsed.data;

  const service = await prisma.service.findUnique({
    where: { id: d.serviceId },
    include: { vendor: true, options: true },
  });
  if (!service || !service.active || service.vendor.status !== "APPROVED") {
    return NextResponse.json({ error: "Service unavailable" }, { status: 400 });
  }
  if (d.qty < service.minQty) {
    return NextResponse.json({ error: `Min qty is ${service.minQty}` }, { status: 400 });
  }

  const chosen = service.options.filter((o) => d.options.includes(o.id));
  const unitPrice =
    service.basePrice + chosen.reduce((sum, o) => sum + o.priceDelta, 0);
  const lineTotal = unitPrice * d.qty;
  const subtotal = lineTotal;
  const deliveryFee = 0;
  const total = subtotal + deliveryFee;

  const order = await prisma.order.create({
    data: {
      code: generateOrderCode(),
      customerId: session.uid,
      vendorId: service.vendorId,
      status: "PENDING",
      paymentStatus: "UNPAID",
      subtotal,
      deliveryFee,
      total,
      notes: d.notes,
      addressLine: d.address,
      city: d.city,
      phone: d.phone,
      fileUrl: d.fileUrl,
      items: {
        create: {
          serviceId: service.id,
          titleAr: service.titleAr,
          qty: d.qty,
          unitPrice,
          options: chosen.length ? chosen.map((o) => o.nameAr).join(", ") : null,
          lineTotal,
        },
      },
      timeline: {
        create: { status: "PENDING", note: "Order created" },
      },
    },
  });

  await prisma.notification.create({
    data: {
      userId: service.vendor.userId,
      titleAr: "طلب جديد",
      titleEn: "New order",
      bodyAr: `طلب جديد ${order.code}`,
      bodyEn: `New order ${order.code}`,
      link: `/vendor/orders/${order.id}`,
    },
  });

  return NextResponse.json({ ok: true, orderId: order.id });
}
