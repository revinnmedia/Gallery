"use client";

import { useRouter } from "next/navigation";
import { useTransition } from "react";

export function LogoutBtn({ label }: { label: string }) {
  const router = useRouter();
  const [pending, start] = useTransition();

  function logout() {
    start(async () => {
      await fetch("/api/auth/logout", { method: "POST" });
      router.refresh();
      router.push("/");
    });
  }

  return (
    <button onClick={logout} disabled={pending} className="btn btn-secondary text-sm">
      {label}
    </button>
  );
}
