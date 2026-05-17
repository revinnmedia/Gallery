import { notFound, redirect } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getCurrentUser } from "@/lib/auth";
import { getDict, getLocale } from "@/lib/i18n";
import { formatDate } from "@/lib/utils";
import { OrderChat } from "@/components/order/OrderChat";
import { PayButton } from "@/components/order/PayButton";
import { ReviewForm } from "@/components/order/ReviewForm";
import { OrderStepper } from "@/components/order/OrderStepper";
import { normalizeStatus } from "@/lib/orderStages";

export default async function OrderDetail({ params }: { params: { id: string } }) {
  const user = await getCurrentUser();
  if (!user) redirect("/login");
  const dict = await getDict();
  const locale = await getLocale();

  const order = await prisma.order.findUnique({
    where: { id: params.id },
    include: {
      vendor: true,
      items: true,
      timeline: { orderBy: { createdAt: "asc" } },
      messages: { include: { sender: true }, orderBy: { createdAt: "asc" } },
      reviews: true,
    },
  });
  if (!order) notFound();
  if (order.customerId !== user.id && user.role !== "ADMIN") notFound();

  return (
    <div className="container-app py-8 grid lg:grid-cols-3 gap-6">
      <div className="lg:col-span-2 space-y-4">
        <div className="card p-6">
          <div className="flex items-center justify-between flex-wrap gap-3">
            <div>
              <div className="text-xs text-gray-500">{dict.order.orderCode}</div>
              <div className="text-xl font-bold">{order.code}</div>
            </div>
            <div className="flex flex-wrap gap-2">
              <span className={`badge status-${normalizeStatus(order.status)}`}>
                {dict.order.status[normalizeStatus(order.status)]}
              </span>
              <span className={`badge status-${order.paymentStatus}`}>
                {order.paymentStatus}
              </span>
            </div>
          </div>

          <div className="mt-5 border-t pt-4">
            <OrderStepper status={order.status} dict={dict} />
          </div>

          <div className="mt-5 border-t pt-4">
            <h3 className="font-semibold mb-2">
              {locale === "ar" ? "تفاصيل الطلب" : "Items"}
            </h3>
            <ul className="divide-y">
              {order.items.map((it) => (
                <li key={it.id} className="py-2 flex justify-between text-sm">
                  <span>
                    {it.titleAr}
                    <span className="text-gray-500"> ×{it.qty}</span>
                    {it.options && <span className="block text-xs text-gray-500">{it.options}</span>}
                  </span>
                  <span>{it.lineTotal.toFixed(2)} {dict.common.sar}</span>
                </li>
              ))}
            </ul>
            <div className="border-t pt-2 mt-2 text-sm space-y-1">
              <div className="flex justify-between"><span>Subtotal</span><span>{order.subtotal.toFixed(2)}</span></div>
              <div className="flex justify-between"><span>Delivery</span><span>{order.deliveryFee.toFixed(2)}</span></div>
              <div className="flex justify-between font-bold text-base"><span>{dict.order.total}</span><span>{order.total.toFixed(2)} {dict.common.sar}</span></div>
            </div>
          </div>

          {(order.addressLine || order.notes) && (
            <div className="mt-5 border-t pt-4 text-sm">
              {order.addressLine && <p><strong>{dict.order.address}:</strong> {order.addressLine}, {order.city}</p>}
              {order.phone && <p><strong>{dict.auth.phone}:</strong> {order.phone}</p>}
              {order.notes && <p className="mt-1"><strong>{dict.order.notes}:</strong> {order.notes}</p>}
              {order.fileUrl && <p className="mt-1"><a href={order.fileUrl} target="_blank" rel="noreferrer" className="text-brand-700 underline">{dict.order.file}</a></p>}
            </div>
          )}
        </div>

        <div className="card p-6">
          <h3 className="font-semibold mb-3">{dict.order.timeline}</h3>
          <ol className="relative border-s-2 border-gray-200 ms-2 space-y-4">
            {order.timeline.map((t) => (
              <li key={t.id} className="ms-4">
                <div className="absolute w-3 h-3 rounded-full bg-brand-600 -start-[7px] mt-1.5" />
                <div className="text-xs text-gray-500">{formatDate(t.createdAt, locale)}</div>
                <div className="font-medium">{dict.order.status[normalizeStatus(t.status)]}</div>
                {t.note && <p className="text-sm text-gray-600">{t.note}</p>}
              </li>
            ))}
          </ol>
        </div>

        <OrderChat
          orderId={order.id}
          dict={dict}
          currentUserId={user.id}
          initialMessages={order.messages.map((m) => ({
            id: m.id,
            body: m.body,
            createdAt: m.createdAt.toISOString(),
            senderId: m.senderId,
            senderName: m.sender.name,
          }))}
        />

        {order.status === "COMPLETED" && order.reviews.length === 0 && (
          <ReviewForm orderId={order.id} dict={dict} />
        )}
      </div>

      <aside className="space-y-4">
        <div className="card p-5">
          <h3 className="font-semibold mb-2">
            {locale === "ar" ? "المطبعة" : "Vendor"}
          </h3>
          <p>{locale === "ar" ? order.vendor.shopName : order.vendor.shopNameEn || order.vendor.shopName}</p>
          <p className="text-sm text-gray-500">{order.vendor.city}</p>
        </div>
        {order.paymentStatus === "UNPAID" && order.status !== "CANCELLED" && (
          <PayButton orderId={order.id} amount={order.total} dict={dict} />
        )}
      </aside>
    </div>
  );
}
