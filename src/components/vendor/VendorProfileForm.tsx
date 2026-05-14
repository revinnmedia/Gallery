"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { Dictionary } from "@/lib/i18n";

export function VendorProfileForm({
  initial,
  dict,
}: {
  initial: { shopName: string; shopNameEn: string; city: string; address: string; description: string };
  dict: Dictionary;
}) {
  const router = useRouter();
  const [form, setForm] = useState(initial);
  const [loading, setLoading] = useState(false);
  const [msg, setMsg] = useState("");
  const [err, setErr] = useState("");

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setErr("");
    setMsg("");
    const r = await fetch("/api/vendor/profile", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(form),
    });
    setLoading(false);
    if (!r.ok) {
      const d = await r.json();
      setErr(d.error || "Failed");
      return;
    }
    setMsg("Saved");
    router.refresh();
  }

  return (
    <form onSubmit={submit} className="space-y-4">
      <div className="grid md:grid-cols-2 gap-3">
        <div>
          <label className="label">{dict.auth.shopName}</label>
          <input
            className="input"
            value={form.shopName}
            onChange={(e) => setForm({ ...form, shopName: e.target.value })}
            required
          />
        </div>
        <div>
          <label className="label">Shop Name (EN)</label>
          <input
            className="input"
            value={form.shopNameEn}
            onChange={(e) => setForm({ ...form, shopNameEn: e.target.value })}
          />
        </div>
        <div>
          <label className="label">{dict.auth.city}</label>
          <input
            className="input"
            value={form.city}
            onChange={(e) => setForm({ ...form, city: e.target.value })}
            required
          />
        </div>
        <div>
          <label className="label">{dict.auth.address}</label>
          <input
            className="input"
            value={form.address}
            onChange={(e) => setForm({ ...form, address: e.target.value })}
          />
        </div>
      </div>
      <div>
        <label className="label">{dict.auth.description}</label>
        <textarea
          className="textarea"
          rows={3}
          value={form.description}
          onChange={(e) => setForm({ ...form, description: e.target.value })}
        />
      </div>
      {msg && <p className="text-sm text-green-700">{msg}</p>}
      {err && <p className="text-sm text-red-600">{err}</p>}
      <button type="submit" disabled={loading} className="btn btn-primary">
        {loading ? dict.common.loading : dict.common.save}
      </button>
    </form>
  );
}
