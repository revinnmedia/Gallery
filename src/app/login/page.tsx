import { getDict } from "@/lib/i18n";
import { LoginForm } from "@/components/auth/LoginForm";
import Link from "next/link";

export default async function LoginPage() {
  const dict = await getDict();
  return (
    <div className="container-app max-w-md mt-10">
      <div className="card p-6">
        <h1 className="text-2xl font-bold mb-4">{dict.auth.loginTitle}</h1>
        <LoginForm dict={dict} />
        <p className="text-sm text-gray-600 mt-4">
          {dict.auth.noAccount}{" "}
          <Link href="/register" className="text-brand-700 underline">
            {dict.auth.registerBtn}
          </Link>
        </p>
      </div>
    </div>
  );
}
