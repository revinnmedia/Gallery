import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { getSession } from "@/lib/auth";
import { z } from "zod";

const schema = z.object({
  shopName: z.string().min(2),
  shopNameEn: z.string().optional(),
  city: z.string().min(2),
  address: z.string().optional(),
  description: z.string().optional(),
});

export async function PATCH(req: Request) {
  const session = await getSession();
  if (!session || session.role !== "VENDOR") {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  const parsed = schema.safeParse(await req.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: "Invalid" }, { status: 400 });
  await prisma.vendor.update({
    where: { userId: session.uid },
    data: parsed.data,
  });
  return NextResponse.json({ ok: true });
}
