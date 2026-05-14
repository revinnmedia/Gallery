"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { Dictionary } from "@/lib/i18n";

export function PayButton({
  orderId,
  amount,
  dict,
}: {
  orderId: string;
  amount: number;
  dict: Dictionary;
}) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState("");

  async function pay() {
    setLoading(true);
    setErr("");
    const r = await fetch(`/api/orders/${orderId}/pay`, { method: "POST" });
    const d = await r.json();
    setLoading(false);
    if (!r.ok) {
      setErr(d.error || "Failed");
      return;
    }
    router.refresh();
  }

  return (
    <div className="card p-5">
      <h3 className="font-semibold mb-1">{dict.order.total}</h3>
      <div className="text-2xl font-extrabold mb-4">
        {amount.toFixed(2)} {dict.common.sar}
      </div>
      <button onClick={pay} disabled={loading} className="btn btn-primary w-full">
        {loading ? dict.common.loading : "Pay (demo)"}
      </button>
      {err && <p className="text-sm text-red-600 mt-2">{err}</p>}
      <p className="text-xs text-gray-500 mt-2">
        Demo payment — integrate Stripe/Tap/PayTabs in production.
      </p>
    </div>
  );
}
