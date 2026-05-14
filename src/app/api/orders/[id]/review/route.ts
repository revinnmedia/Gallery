import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { getSession } from "@/lib/auth";
import { z } from "zod";

const schema = z.object({
  rating: z.number().int().min(1).max(5),
  comment: z.string().optional(),
});

export async function POST(req: Request, { params }: { params: { id: string } }) {
  const session = await getSession();
  if (!session) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const body = await req.json().catch(() => null);
  const parsed = schema.safeParse(body);
  if (!parsed.success) return NextResponse.json({ error: "Invalid" }, { status: 400 });

  const order = await prisma.order.findUnique({ where: { id: params.id } });
  if (!order || order.customerId !== session.uid) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }
  if (order.status !== "COMPLETED") {
    return NextResponse.json({ error: "Order not completed" }, { status: 400 });
  }
  const existing = await prisma.review.findUnique({ where: { orderId: order.id } });
  if (existing) return NextResponse.json({ error: "Already reviewed" }, { status: 409 });

  await prisma.review.create({
    data: {
      orderId: order.id,
      vendorId: order.vendorId,
      userId: session.uid,
      rating: parsed.data.rating,
      comment: parsed.data.comment,
    },
  });

  const agg = await prisma.review.aggregate({
    where: { vendorId: order.vendorId },
    _avg: { rating: true },
    _count: true,
  });
  await prisma.vendor.update({
    where: { id: order.vendorId },
    data: {
      rating: agg._avg.rating || 0,
      reviewCount: agg._count,
    },
  });

  return NextResponse.json({ ok: true });
}
