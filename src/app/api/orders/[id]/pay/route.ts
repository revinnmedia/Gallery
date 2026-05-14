import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { getSession } from "@/lib/auth";

export async function POST(_req: Request, { params }: { params: { id: string } }) {
  const session = await getSession();
  if (!session) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const order = await prisma.order.findUnique({
    where: { id: params.id },
    include: { vendor: true },
  });
  if (!order) return NextResponse.json({ error: "Not found" }, { status: 404 });
  if (order.customerId !== session.uid) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }
  if (order.paymentStatus === "PAID") {
    return NextResponse.json({ ok: true });
  }

  await prisma.order.update({
    where: { id: order.id },
    data: { paymentStatus: "PAID" },
  });
  await prisma.notification.create({
    data: {
      userId: order.vendor.userId,
      titleAr: "تم الدفع",
      titleEn: "Payment received",
      bodyAr: `طلب ${order.code} تم دفعه`,
      link: `/vendor/orders/${order.id}`,
    },
  });

  return NextResponse.json({ ok: true });
}
