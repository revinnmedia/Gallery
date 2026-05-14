import { NextResponse } from "next/server";
import { getSession } from "@/lib/auth";
import { writeFile, mkdir } from "fs/promises";
import path from "path";
import crypto from "crypto";

const MAX = 20 * 1024 * 1024;
const ALLOWED = [
  "application/pdf",
  "image/png",
  "image/jpeg",
  "image/webp",
  "image/svg+xml",
];

export async function POST(req: Request) {
  const session = await getSession();
  if (!session) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const form = await req.formData();
  const file = form.get("file") as File | null;
  if (!file) return NextResponse.json({ error: "No file" }, { status: 400 });
  if (file.size > MAX) return NextResponse.json({ error: "File too large" }, { status: 400 });
  if (!ALLOWED.includes(file.type)) {
    return NextResponse.json({ error: "Unsupported file type" }, { status: 400 });
  }

  const buf = Buffer.from(await file.arrayBuffer());
  const ext = path.extname(file.name) || "";
  const name = `${Date.now()}-${crypto.randomBytes(6).toString("hex")}${ext}`;

  if (process.env.VERCEL) {
    return NextResponse.json({
      ok: true,
      url: `data:${file.type};name=${encodeURIComponent(file.name)};base64-omitted`,
      note: "File received (demo mode — not persisted on serverless)",
    });
  }

  const dir = path.join(process.cwd(), "public", "uploads");
  await mkdir(dir, { recursive: true });
  await writeFile(path.join(dir, name), buf);
  return NextResponse.json({ ok: true, url: `/uploads/${name}` });
}
