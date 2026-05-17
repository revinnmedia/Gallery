import Link from "next/link";
import type { Dictionary } from "@/lib/i18n";
import { FLOW_STAGES, normalizeStatus } from "@/lib/orderStages";

type TrackerOrder = {
  id: string;
  code: string;
  status: string;
  total: number;
  customerName: string;
  createdAt: Date;
};

export function OrderTracker({
  orders,
  dict,
}: {
  orders: TrackerOrder[];
  dict: Dictionary;
}) {
  const buckets: Record<string, TrackerOrder[]> = {
    NEW: [],
    PREPARING: [],
    PRINTING: [],
    DELIVERY: [],
  };
  for (const o of orders) {
    const s = normalizeStatus(o.status);
    if (s in buckets) buckets[s].push(o);
  }

  return (
    <div className="card p-5">
      <div className="flex items-baseline justify-between flex-wrap gap-2 mb-4">
        <div>
          <h3 className="font-bold text-lg">{dict.tracker.title}</h3>
          <p className="text-sm text-gray-500">{dict.tracker.subtitle}</p>
        </div>
      </div>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
        {FLOW_STAGES.map((stage) => {
          const list = buckets[stage];
          return (
            <div
              key={stage}
              className={`rounded-lg border p-3 stage-col stage-col-${stage}`}
            >
              <div className="flex items-center justify-between mb-3">
                <div className="font-semibold text-sm">
                  {dict.order.status[stage]}
                </div>
                <span
                  className={`badge status-${stage} ${
                    list.length > 0 ? "ring-2 ring-offset-1 ring-brand-300" : ""
                  }`}
                >
                  {list.length}
                </span>
              </div>
              {list.length === 0 ? (
                <div className="text-xs text-gray-400 text-center py-6">
                  {dict.tracker.empty}
                </div>
              ) : (
                <ul className="space-y-2">
                  {list.map((o) => (
                    <li key={o.id}>
                      <Link
                        href={`/vendor/orders/${o.id}`}
                        className="block bg-white rounded-md border p-2 hover:border-brand-400 transition"
                      >
                        <div className="text-xs text-gray-500">{o.code}</div>
                        <div className="text-sm font-medium truncate">
                          {o.customerName}
                        </div>
                        <div className="flex items-center justify-between mt-1">
                          <span className="text-xs text-gray-500">
                            {o.total.toFixed(2)} {dict.common.sar}
                          </span>
                          <span className="text-[10px] px-2 py-0.5 rounded-full bg-amber-100 text-amber-800">
                            {dict.tracker.remind}
                          </span>
                        </div>
                      </Link>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
