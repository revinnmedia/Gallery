import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { getSession } from "@/lib/auth";
import { z } from "zod";
const schema = z.object({
  status: z.enum([
    "PENDING",
    "ACCEPTED",
    "IN_PRODUCTION",
    "READY",
    "DELIVERING",
    "COMPLETED",
    "CANCELLED",
    "REJECTED",
  ]),
});

export async function POST(req: Request, { params }: { params: { id: string } }) {
  const session = await getSession();
  if (!session || session.role !== "VENDOR") {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  const vendor = await prisma.vendor.findUnique({ where: { userId: session.uid } });
  if (!vendor) return NextResponse.json({ error: "Vendor not found" }, { status: 404 });

  const order = await prisma.order.findUnique({ where: { id: params.id } });
  if (!order || order.vendorId !== vendor.id) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }
  const parsed = schema.safeParse(await req.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: "Invalid" }, { status: 400 });

  await prisma.order.update({
    where: { id: order.id },
    data: {
      status: parsed.data.status,
      timeline: { create: { status: parsed.data.status } },
    },
  });

  await prisma.notification.create({
    data: {
      userId: order.customerId,
      titleAr: "تحديث طلب",
      titleEn: "Order update",
      bodyAr: `طلبك ${order.code} ${parsed.data.status}`,
      bodyEn: `Your order ${order.code} is ${parsed.data.status}`,
      link: `/orders/${order.id}`,
    },
  });

  return NextResponse.json({ ok: true });
}
