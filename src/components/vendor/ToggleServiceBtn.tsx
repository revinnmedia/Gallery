"use client";

import { useRouter } from "next/navigation";
import { useTransition } from "react";

export function ToggleServiceBtn({ id, active }: { id: string; active: boolean }) {
  const router = useRouter();
  const [pending, start] = useTransition();

  function toggle() {
    start(async () => {
      await fetch(`/api/vendor/services/${id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ active: !active }),
      });
      router.refresh();
    });
  }

  return (
    <button onClick={toggle} disabled={pending} className="btn btn-secondary text-sm">
      {active ? "Disable" : "Enable"}
    </button>
  );
}
