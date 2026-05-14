"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { Dictionary } from "@/lib/i18n";

export function VendorRegisterForm({ dict }: { dict: Dictionary }) {
  const router = useRouter();
  const [form, setForm] = useState({
    name: "",
    email: "",
    phone: "",
    password: "",
    shopName: "",
    shopNameEn: "",
    city: "",
    address: "",
    description: "",
  });
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  function field<K extends keyof typeof form>(k: K, v: string) {
    setForm((f) => ({ ...f, [k]: v }));
  }

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    const res = await fetch("/api/vendor/register", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(form),
    });
    const data = await res.json();
    setLoading(false);
    if (!res.ok) {
      setError(data.error || "Failed");
      return;
    }
    router.push(data.redirect || "/vendor");
    router.refresh();
  }

  return (
    <form onSubmit={submit} className="space-y-4">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label className="label">{dict.auth.name}</label>
          <input className="input" value={form.name} onChange={(e) => field("name", e.target.value)} required />
        </div>
        <div>
          <label className="label">{dict.auth.email}</label>
          <input className="input" type="email" value={form.email} onChange={(e) => field("email", e.target.value)} required />
        </div>
        <div>
          <label className="label">{dict.auth.phone}</label>
          <input className="input" value={form.phone} onChange={(e) => field("phone", e.target.value)} />
        </div>
        <div>
          <label className="label">{dict.auth.password}</label>
          <input className="input" type="password" value={form.password} onChange={(e) => field("password", e.target.value)} required minLength={6} />
        </div>
        <div>
          <label className="label">{dict.auth.shopName}</label>
          <input className="input" value={form.shopName} onChange={(e) => field("shopName", e.target.value)} required />
        </div>
        <div>
          <label className="label">Shop Name (EN)</label>
          <input className="input" value={form.shopNameEn} onChange={(e) => field("shopNameEn", e.target.value)} />
        </div>
        <div>
          <label className="label">{dict.auth.city}</label>
          <input className="input" value={form.city} onChange={(e) => field("city", e.target.value)} required />
        </div>
        <div>
          <label className="label">{dict.auth.address}</label>
          <input className="input" value={form.address} onChange={(e) => field("address", e.target.value)} />
        </div>
      </div>
      <div>
        <label className="label">{dict.auth.description}</label>
        <textarea className="textarea" rows={3} value={form.description} onChange={(e) => field("description", e.target.value)} />
      </div>
      {error && <p className="text-sm text-red-600">{error}</p>}
      <button type="submit" disabled={loading} className="btn btn-primary">
        {loading ? dict.common.loading : dict.auth.registerBtn}
      </button>
    </form>
  );
}
