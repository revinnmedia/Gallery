"use client";

import { useEffect, useRef, useState } from "react";
import type { Dictionary } from "@/lib/i18n";

type Msg = {
  id: string;
  body: string;
  createdAt: string;
  senderId: string;
  senderName: string;
};

export function OrderChat({
  orderId,
  initialMessages,
  currentUserId,
  dict,
}: {
  orderId: string;
  initialMessages: Msg[];
  currentUserId: string;
  dict: Dictionary;
}) {
  const [messages, setMessages] = useState<Msg[]>(initialMessages);
  const [body, setBody] = useState("");
  const [loading, setLoading] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight });
  }, [messages]);

  useEffect(() => {
    const t = setInterval(async () => {
      const r = await fetch(`/api/orders/${orderId}/messages`, { cache: "no-store" });
      if (r.ok) {
        const data = await r.json();
        setMessages(data.messages);
      }
    }, 6000);
    return () => clearInterval(t);
  }, [orderId]);

  async function send(e: React.FormEvent) {
    e.preventDefault();
    if (!body.trim()) return;
    setLoading(true);
    const r = await fetch(`/api/orders/${orderId}/messages`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ body: body.trim() }),
    });
    setLoading(false);
    if (r.ok) {
      const data = await r.json();
      setMessages((m) => [...m, data.message]);
      setBody("");
    }
  }

  return (
    <div className="card p-5">
      <h3 className="font-semibold mb-3">{dict.nav.messages}</h3>
      <div ref={scrollRef} className="max-h-72 overflow-y-auto space-y-2 mb-3">
        {messages.length === 0 ? (
          <p className="text-sm text-gray-500 text-center py-6">—</p>
        ) : (
          messages.map((m) => {
            const mine = m.senderId === currentUserId;
            return (
              <div
                key={m.id}
                className={`flex ${mine ? "justify-end" : "justify-start"}`}
              >
                <div
                  className={`max-w-[80%] rounded-lg px-3 py-2 text-sm ${
                    mine ? "bg-brand-600 text-white" : "bg-gray-100 text-gray-900"
                  }`}
                >
                  {!mine && <div className="text-xs font-medium opacity-70 mb-0.5">{m.senderName}</div>}
                  <div className="whitespace-pre-wrap">{m.body}</div>
                </div>
              </div>
            );
          })
        )}
      </div>
      <form onSubmit={send} className="flex gap-2">
        <input
          value={body}
          onChange={(e) => setBody(e.target.value)}
          placeholder={dict.common.writeMessage}
          className="input flex-1"
        />
        <button type="submit" disabled={loading || !body.trim()} className="btn btn-primary">
          {dict.common.send}
        </button>
      </form>
    </div>
  );
}
