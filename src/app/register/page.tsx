import { getDict } from "@/lib/i18n";
import { RegisterForm } from "@/components/auth/RegisterForm";
import Link from "next/link";

export default async function RegisterPage() {
  const dict = await getDict();
  return (
    <div className="container-app max-w-md mt-10">
      <div className="card p-6">
        <h1 className="text-2xl font-bold mb-4">{dict.auth.registerTitle}</h1>
        <RegisterForm dict={dict} />
        <p className="text-sm text-gray-600 mt-4">
          {dict.auth.hasAccount}{" "}
          <Link href="/login" className="text-brand-700 underline">
            {dict.auth.loginBtn}
          </Link>
        </p>
        <p className="text-sm text-gray-600 mt-2">
          <Link href="/become-vendor" className="text-brand-700 underline">
            {dict.nav.vendorRegister}
          </Link>
        </p>
      </div>
    </div>
  );
}
