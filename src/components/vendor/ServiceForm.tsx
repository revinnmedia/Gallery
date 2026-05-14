"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { Dictionary, Locale } from "@/lib/i18n";

type Initial = {
  id?: string;
  categoryId?: string;
  titleAr?: string;
  titleEn?: string;
  descAr?: string;
  descEn?: string;
  basePrice?: number;
  leadTimeDays?: number;
  minQty?: number;
  active?: boolean;
};

export function ServiceForm({
  initial,
  categories,
  dict,
  locale,
}: {
  initial?: Initial;
  categories: { id: string; name: string }[];
  dict: Dictionary;
  locale: Locale;
}) {
  const router = useRouter();
  const [form, setForm] = useState({
    categoryId: initial?.categoryId || categories[0]?.id || "",
    titleAr: initial?.titleAr || "",
    titleEn: initial?.titleEn || "",
    descAr: initial?.descAr || "",
    descEn: initial?.descEn || "",
    basePrice: initial?.basePrice ?? 0,
    leadTimeDays: initial?.leadTimeDays ?? 2,
    minQty: initial?.minQty ?? 1,
    active: initial?.active ?? true,
  });
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError("");
    const url = initial?.id
      ? `/api/vendor/services/${initial.id}`
      : "/api/vendor/services";
    const method = initial?.id ? "PATCH" : "POST";
    const r = await fetch(url, {
      method,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(form),
    });
    setLoading(false);
    if (!r.ok) {
      const d = await r.json();
      setError(d.error || "Failed");
      return;
    }
    router.push("/vendor/services");
    router.refresh();
  }

  return (
    <form onSubmit={submit} className="space-y-4">
      <div>
        <label className="label">{dict.vendor.category}</label>
        <select
          className="select"
          value={form.categoryId}
          onChange={(e) => setForm({ ...form, categoryId: e.target.value })}
          required
        >
          {categories.map((c) => (
            <option key={c.id} value={c.id}>{c.name}</option>
          ))}
        </select>
      </div>
      <div className="grid md:grid-cols-2 gap-3">
        <div>
          <label className="label">{dict.vendor.titleAr}</label>
          <input
            className="input"
            value={form.titleAr}
            onChange={(e) => setForm({ ...form, titleAr: e.target.value })}
            required
          />
        </div>
        <div>
          <label className="label">{dict.vendor.titleEn}</label>
          <input
            className="input"
            value={form.titleEn}
            onChange={(e) => setForm({ ...form, titleEn: e.target.value })}
          />
        </div>
      </div>
      <div>
        <label className="label">{dict.vendor.descAr}</label>
        <textarea
          rows={3}
          className="textarea"
          value={form.descAr}
          onChange={(e) => setForm({ ...form, descAr: e.target.value })}
        />
      </div>
      <div className="grid grid-cols-3 gap-3">
        <div>
          <label className="label">{dict.vendor.basePrice}</label>
          <input
            type="number"
            step="0.01"
            min={0}
            className="input"
            value={form.basePrice}
            onChange={(e) => setForm({ ...form, basePrice: parseFloat(e.target.value) || 0 })}
            required
          />
        </div>
        <div>
          <label className="label">{dict.vendor.leadTime}</label>
          <input
            type="number"
            min={1}
            className="input"
            value={form.leadTimeDays}
            onChange={(e) => setForm({ ...form, leadTimeDays: parseInt(e.target.value, 10) || 1 })}
          />
        </div>
        <div>
          <label className="label">{locale === "ar" ? "أقل كمية" : "Min qty"}</label>
          <input
            type="number"
            min={1}
            className="input"
            value={form.minQty}
            onChange={(e) => setForm({ ...form, minQty: parseInt(e.target.value, 10) || 1 })}
          />
        </div>
      </div>
      <label className="flex items-center gap-2">
        <input
          type="checkbox"
          checked={form.active}
          onChange={(e) => setForm({ ...form, active: e.target.checked })}
        />
        <span>{locale === "ar" ? "نشطة" : "Active"}</span>
      </label>
      {error && <p className="text-sm text-red-600">{error}</p>}
      <button type="submit" disabled={loading} className="btn btn-primary">
        {loading ? dict.common.loading : dict.common.save}
      </button>
    </form>
  );
}
