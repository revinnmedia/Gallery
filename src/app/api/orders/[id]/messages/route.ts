import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { getSession } from "@/lib/auth";

async function authOrderAccess(orderId: string, uid: string, role: string) {
  const order = await prisma.order.findUnique({
    where: { id: orderId },
    include: { vendor: true },
  });
  if (!order) return null;
  const isCustomer = order.customerId === uid;
  const isVendor = order.vendor.userId === uid;
  const isAdmin = role === "ADMIN";
  if (!isCustomer && !isVendor && !isAdmin) return null;
  return order;
}

export async function GET(_req: Request, { params }: { params: { id: string } }) {
  const session = await getSession();
  if (!session) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const order = await authOrderAccess(params.id, session.uid, session.role);
  if (!order) return NextResponse.json({ error: "Not found" }, { status: 404 });

  const messages = await prisma.message.findMany({
    where: { orderId: order.id },
    include: { sender: true },
    orderBy: { createdAt: "asc" },
  });
  return NextResponse.json({
    messages: messages.map((m) => ({
      id: m.id,
      body: m.body,
      createdAt: m.createdAt.toISOString(),
      senderId: m.senderId,
      senderName: m.sender.name,
    })),
  });
}

export async function POST(req: Request, { params }: { params: { id: string } }) {
  const session = await getSession();
  if (!session) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const order = await authOrderAccess(params.id, session.uid, session.role);
  if (!order) return NextResponse.json({ error: "Not found" }, { status: 404 });

  const { body } = (await req.json().catch(() => ({}))) as { body?: string };
  if (!body || !body.trim()) return NextResponse.json({ error: "Empty" }, { status: 400 });

  const message = await prisma.message.create({
    data: { orderId: order.id, senderId: session.uid, body: body.trim() },
    include: { sender: true },
  });

  const otherUserId =
    session.uid === order.customerId ? order.vendor.userId : order.customerId;
  await prisma.notification.create({
    data: {
      userId: otherUserId,
      titleAr: "رسالة جديدة",
      titleEn: "New message",
      bodyAr: `${session.name}: ${body.slice(0, 60)}`,
      link: `/orders/${order.id}`,
    },
  });

  return NextResponse.json({
    message: {
      id: message.id,
      body: message.body,
      createdAt: message.createdAt.toISOString(),
      senderId: message.senderId,
      senderName: message.sender.name,
    },
  });
}
