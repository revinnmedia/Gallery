"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { Dictionary } from "@/lib/i18n";

export function CategoryForm({ dict }: { dict: Dictionary }) {
  const router = useRouter();
  const [form, setForm] = useState({ slug: "", nameAr: "", nameEn: "" });
  const [err, setErr] = useState("");
  const [loading, setLoading] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setErr("");
    setLoading(true);
    const r = await fetch("/api/admin/categories", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(form),
    });
    setLoading(false);
    if (!r.ok) {
      const d = await r.json();
      setErr(d.error || "Failed");
      return;
    }
    setForm({ slug: "", nameAr: "", nameEn: "" });
    router.refresh();
  }

  return (
    <form onSubmit={submit} className="card p-4 space-y-3">
      <h3 className="font-semibold">{dict.common.add}</h3>
      <div className="grid md:grid-cols-3 gap-3">
        <input
          className="input"
          placeholder="slug"
          value={form.slug}
          onChange={(e) => setForm({ ...form, slug: e.target.value })}
          required
        />
        <input
          className="input"
          placeholder="Name (Arabic)"
          value={form.nameAr}
          onChange={(e) => setForm({ ...form, nameAr: e.target.value })}
          required
        />
        <input
          className="input"
          placeholder="Name (English)"
          value={form.nameEn}
          onChange={(e) => setForm({ ...form, nameEn: e.target.value })}
          required
        />
      </div>
      {err && <p className="text-sm text-red-600">{err}</p>}
      <button type="submit" disabled={loading} className="btn btn-primary">
        {loading ? dict.common.loading : dict.common.add}
      </button>
    </form>
  );
}
