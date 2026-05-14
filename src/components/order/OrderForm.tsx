"use client";

import { useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import type { Dictionary, Locale } from "@/lib/i18n";

type Service = {
  id: string;
  titleAr: string;
  basePrice: number;
  minQty: number;
  options: { id: string; nameAr: string; nameEn: string | null; priceDelta: number }[];
};

export function OrderForm({
  service,
  dict,
  locale,
}: {
  service: Service;
  dict: Dictionary;
  locale: Locale;
}) {
  const router = useRouter();
  const [qty, setQty] = useState(service.minQty);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [notes, setNotes] = useState("");
  const [address, setAddress] = useState("");
  const [city, setCity] = useState("");
  const [phone, setPhone] = useState("");
  const [file, setFile] = useState<File | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const unitPrice = useMemo(() => {
    let p = service.basePrice;
    for (const o of service.options) if (selected.has(o.id)) p += o.priceDelta;
    return p;
  }, [service, selected]);
  const total = unitPrice * qty;

  function toggleOpt(id: string) {
    setSelected((s) => {
      const n = new Set(s);
      n.has(id) ? n.delete(id) : n.add(id);
      return n;
    });
  }

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    let fileUrl: string | undefined;
    if (file) {
      const fd = new FormData();
      fd.append("file", file);
      const up = await fetch("/api/upload", { method: "POST", body: fd });
      const upData = await up.json();
      if (!up.ok) {
        setError(upData.error || "Upload failed");
        setLoading(false);
        return;
      }
      fileUrl = upData.url;
    }
    const res = await fetch("/api/orders", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        serviceId: service.id,
        qty,
        options: Array.from(selected),
        notes,
        address,
        city,
        phone,
        fileUrl,
      }),
    });
    const data = await res.json();
    setLoading(false);
    if (!res.ok) {
      setError(data.error || "Failed");
      return;
    }
    router.push(`/orders/${data.orderId}`);
    router.refresh();
  }

  return (
    <form onSubmit={submit} className="space-y-3">
      <div>
        <label className="label">{dict.order.qty}</label>
        <input
          type="number"
          min={service.minQty}
          value={qty}
          onChange={(e) => setQty(Math.max(service.minQty, parseInt(e.target.value || "0", 10)))}
          className="input"
        />
      </div>

      {service.options.length > 0 && (
        <div>
          <label className="label">{locale === "ar" ? "الخيارات" : "Options"}</label>
          <ul className="space-y-1">
            {service.options.map((o) => (
              <li key={o.id} className="flex items-center justify-between text-sm">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={selected.has(o.id)}
                    onChange={() => toggleOpt(o.id)}
                  />
                  <span>{locale === "ar" ? o.nameAr : o.nameEn || o.nameAr}</span>
                </label>
                <span className="text-gray-500">+{o.priceDelta.toFixed(2)}</span>
              </li>
            ))}
          </ul>
        </div>
      )}

      <div>
        <label className="label">{dict.order.file}</label>
        <input type="file" onChange={(e) => setFile(e.target.files?.[0] || null)} className="input" />
      </div>
      <div>
        <label className="label">{dict.order.notes}</label>
        <textarea rows={2} value={notes} onChange={(e) => setNotes(e.target.value)} className="textarea" />
      </div>
      <div>
        <label className="label">{dict.order.address}</label>
        <input value={address} onChange={(e) => setAddress(e.target.value)} className="input" />
      </div>
      <div className="grid grid-cols-2 gap-2">
        <input value={city} placeholder={dict.common.city} onChange={(e) => setCity(e.target.value)} className="input" />
        <input value={phone} placeholder={dict.auth.phone} onChange={(e) => setPhone(e.target.value)} className="input" />
      </div>

      <div className="border-t pt-3">
        <div className="flex justify-between text-sm">
          <span>{locale === "ar" ? "السعر الواحد" : "Unit price"}</span>
          <strong>{unitPrice.toFixed(2)}</strong>
        </div>
        <div className="flex justify-between text-lg font-bold mt-1">
          <span>{dict.order.total}</span>
          <span>{total.toFixed(2)} {dict.common.sar}</span>
        </div>
      </div>

      {error && <p className="text-sm text-red-600">{error}</p>}
      <button type="submit" disabled={loading} className="btn btn-primary w-full">
        {loading ? dict.common.loading : dict.order.placeOrder}
      </button>
    </form>
  );
}
