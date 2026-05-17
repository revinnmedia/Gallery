"use client";

import { useTransition } from "react";
import { useRouter } from "next/navigation";
import type { OrderStatus } from "@/lib/constants";
import type { Dictionary } from "@/lib/i18n";
import { NEXT_STATUS, normalizeStatus } from "@/lib/orderStages";

export function OrderStatusActions({
  orderId,
  status,
  dict,
}: {
  orderId: string;
  status: string;
  dict: Dictionary;
}) {
  const router = useRouter();
  const [pending, start] = useTransition();
  const normalized = normalizeStatus(status);
  const options = NEXT_STATUS[normalized] ?? [];

  if (!options.length) {
    return <p className="text-sm text-gray-500">—</p>;
  }

  function update(next: OrderStatus) {
    start(async () => {
      await fetch(`/api/vendor/orders/${orderId}/status`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: next }),
      });
      router.refresh();
    });
  }

  return (
    <div className="flex flex-wrap gap-2">
      {options.map((next) => (
        <button
          key={next}
          onClick={() => update(next)}
          disabled={pending}
          className={`btn ${next === "CANCELLED" ? "btn-danger" : "btn-primary"}`}
        >
          → {dict.order.status[next]}
        </button>
      ))}
    </div>
  );
}
