import type { OrderStatus } from "./constants";

export const FLOW_STAGES = ["NEW", "PREPARING", "PRINTING", "DELIVERY"] as const;
export type FlowStage = (typeof FLOW_STAGES)[number];

export const TERMINAL_STATUSES = ["COMPLETED", "CANCELLED"] as const;

const LEGACY_MAP: Record<string, OrderStatus> = {
  PENDING: "NEW",
  ACCEPTED: "PREPARING",
  IN_PRODUCTION: "PRINTING",
  READY: "DELIVERY",
  DELIVERING: "DELIVERY",
  REJECTED: "CANCELLED",
};

export function normalizeStatus(raw: string): OrderStatus {
  if (raw in LEGACY_MAP) return LEGACY_MAP[raw];
  return raw as OrderStatus;
}

export const NEXT_STATUS: Record<OrderStatus, OrderStatus[]> = {
  NEW: ["PREPARING", "CANCELLED"],
  PREPARING: ["PRINTING", "CANCELLED"],
  PRINTING: ["DELIVERY", "CANCELLED"],
  DELIVERY: ["COMPLETED"],
  COMPLETED: [],
  CANCELLED: [],
};

export function stageIndex(status: string): number {
  const s = normalizeStatus(status);
  if (s === "COMPLETED") return FLOW_STAGES.length;
  return FLOW_STAGES.indexOf(s as FlowStage);
}

export function isActive(status: string): boolean {
  const s = normalizeStatus(status);
  return s !== "COMPLETED" && s !== "CANCELLED";
}
