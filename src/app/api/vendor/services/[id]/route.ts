import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { getSession } from "@/lib/auth";
import { z } from "zod";

const schema = z.object({
  categoryId: z.string().optional(),
  titleAr: z.string().min(2).optional(),
  titleEn: z.string().optional(),
  descAr: z.string().optional(),
  descEn: z.string().optional(),
  basePrice: z.number().nonnegative().optional(),
  leadTimeDays: z.number().int().min(1).optional(),
  minQty: z.number().int().min(1).optional(),
  active: z.boolean().optional(),
});

async function authorize(uid: string, id: string) {
  const vendor = await prisma.vendor.findUnique({ where: { userId: uid } });
  if (!vendor) return null;
  const s = await prisma.service.findUnique({ where: { id } });
  if (!s || s.vendorId !== vendor.id) return null;
  return s;
}

export async function PATCH(req: Request, { params }: { params: { id: string } }) {
  const session = await getSession();
  if (!session || session.role !== "VENDOR") {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  const s = await authorize(session.uid, params.id);
  if (!s) return NextResponse.json({ error: "Not found" }, { status: 404 });

  const parsed = schema.safeParse(await req.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: "Invalid" }, { status: 400 });

  await prisma.service.update({
    where: { id: s.id },
    data: parsed.data,
  });
  return NextResponse.json({ ok: true });
}

export async function DELETE(_req: Request, { params }: { params: { id: string } }) {
  const session = await getSession();
  if (!session || session.role !== "VENDOR") {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  const s = await authorize(session.uid, params.id);
  if (!s) return NextResponse.json({ error: "Not found" }, { status: 404 });
  await prisma.service.delete({ where: { id: s.id } });
  return NextResponse.json({ ok: true });
}
