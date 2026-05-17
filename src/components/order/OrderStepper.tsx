import type { Dictionary } from "@/lib/i18n";
import { FLOW_STAGES, normalizeStatus, stageIndex } from "@/lib/orderStages";

export function OrderStepper({
  status,
  dict,
}: {
  status: string;
  dict: Dictionary;
}) {
  const normalized = normalizeStatus(status);
  const cancelled = normalized === "CANCELLED";
  const idx = stageIndex(status);

  if (cancelled) {
    return (
      <div className="text-sm">
        <span className="badge status-CANCELLED">{dict.order.status.CANCELLED}</span>
      </div>
    );
  }

  return (
    <div>
      <div className="text-xs text-gray-500 mb-2">{dict.tracker.stagesLabel}</div>
      <ol className="flex items-center gap-1 sm:gap-2 w-full overflow-x-auto">
        {FLOW_STAGES.map((stage, i) => {
          const done = i < idx || normalized === "COMPLETED";
          const current = i === idx && normalized !== "COMPLETED";
          return (
            <li key={stage} className="flex-1 min-w-[80px]">
              <div className="flex items-center gap-1">
                <div
                  className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold border-2 ${
                    done
                      ? "bg-emerald-500 border-emerald-500 text-white"
                      : current
                      ? "bg-brand-600 border-brand-600 text-white"
                      : "bg-white border-gray-300 text-gray-400"
                  }`}
                >
                  {done ? "✓" : i + 1}
                </div>
                {i < FLOW_STAGES.length - 1 && (
                  <div
                    className={`h-0.5 flex-1 ${
                      i < idx ? "bg-emerald-500" : "bg-gray-200"
                    }`}
                  />
                )}
              </div>
              <div
                className={`mt-1 text-xs ${
                  current ? "font-bold text-brand-700" : "text-gray-600"
                }`}
              >
                {dict.order.status[stage]}
              </div>
            </li>
          );
        })}
      </ol>
    </div>
  );
}
