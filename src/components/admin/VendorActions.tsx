"use client";

import { useRouter } from "next/navigation";
import { useTransition } from "react";
import type { VendorStatus } from "@/lib/constants";

export function VendorActions({ id, status }: { id: string; status: string }) {
  const router = useRouter();
  const [pending, start] = useTransition();

  function update(next: string) {
    start(async () => {
      await fetch(`/api/admin/vendors/${id}/status`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: next }),
      });
      router.refresh();
    });
  }

  return (
    <div className="flex gap-2">
      {status !== "APPROVED" && (
        <button onClick={() => update("APPROVED")} disabled={pending} className="btn btn-success text-sm">
          Approve
        </button>
      )}
      {status !== "SUSPENDED" && status !== "REJECTED" && (
        <button onClick={() => update("SUSPENDED")} disabled={pending} className="btn btn-secondary text-sm">
          Suspend
        </button>
      )}
      {status === "PENDING_APPROVAL" && (
        <button onClick={() => update("REJECTED")} disabled={pending} className="btn btn-danger text-sm">
          Reject
        </button>
      )}
    </div>
  );
}
