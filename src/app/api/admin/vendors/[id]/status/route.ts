import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { getSession } from "@/lib/auth";
import { z } from "zod";
import { VendorStatus } from "@/lib/constants";

const schema = z.object({
  status: z.enum(["PENDING_APPROVAL", "APPROVED", "SUSPENDED", "REJECTED"]),
});

export async function POST(req: Request, { params }: { params: { id: string } }) {
  const session = await getSession();
  if (!session || session.role !== "ADMIN") {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  const parsed = schema.safeParse(await req.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: "Invalid" }, { status: 400 });

  const vendor = await prisma.vendor.update({
    where: { id: params.id },
    data: { status: parsed.data.status },
  });
  await prisma.notification.create({
    data: {
      userId: vendor.userId,
      titleAr: "حالة المطبعة",
      titleEn: "Vendor status",
      bodyAr: `تم تحديث حالة مطبعتك: ${parsed.data.status}`,
      bodyEn: `Your shop status is: ${parsed.data.status}`,
      link: "/vendor",
    },
  });

  return NextResponse.json({ ok: true });
}
