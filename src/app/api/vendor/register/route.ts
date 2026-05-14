import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { createSession, hashPassword } from "@/lib/auth";
import { z } from "zod";

const schema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  phone: z.string().optional(),
  password: z.string().min(6),
  shopName: z.string().min(2),
  shopNameEn: z.string().optional(),
  city: z.string().min(2),
  address: z.string().optional(),
  description: z.string().optional(),
});

export async function POST(req: Request) {
  const body = await req.json().catch(() => null);
  const parsed = schema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid input" }, { status: 400 });
  }
  const d = parsed.data;

  const exists = await prisma.user.findUnique({ where: { email: d.email.toLowerCase() } });
  if (exists) {
    return NextResponse.json({ error: "Email already in use" }, { status: 409 });
  }

  const user = await prisma.user.create({
    data: {
      name: d.name,
      email: d.email.toLowerCase(),
      phone: d.phone,
      password: await hashPassword(d.password),
      role: "VENDOR",
      vendor: {
        create: {
          shopName: d.shopName,
          shopNameEn: d.shopNameEn,
          city: d.city,
          address: d.address,
          description: d.description,
          status: "PENDING_APPROVAL",
        },
      },
    },
  });

  await createSession({ uid: user.id, role: user.role, name: user.name });
  return NextResponse.json({ ok: true, redirect: "/vendor" });
}
