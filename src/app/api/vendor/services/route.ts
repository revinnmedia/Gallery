import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { getSession } from "@/lib/auth";
import { z } from "zod";

const schema = z.object({
  categoryId: z.string(),
  titleAr: z.string().min(2),
  titleEn: z.string().optional(),
  descAr: z.string().optional(),
  descEn: z.string().optional(),
  basePrice: z.number().nonnegative(),
  leadTimeDays: z.number().int().min(1),
  minQty: z.number().int().min(1),
  active: z.boolean().optional().default(true),
});

export async function POST(req: Request) {
  const session = await getSession();
  if (!session || session.role !== "VENDOR") {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  const vendor = await prisma.vendor.findUnique({ where: { userId: session.uid } });
  if (!vendor || vendor.status !== "APPROVED") {
    return NextResponse.json({ error: "Vendor not approved" }, { status: 403 });
  }
  const parsed = schema.safeParse(await req.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: "Invalid" }, { status: 400 });

  const s = await prisma.service.create({
    data: {
      vendorId: vendor.id,
      ...parsed.data,
    },
  });
  return NextResponse.json({ ok: true, id: s.id });
}
