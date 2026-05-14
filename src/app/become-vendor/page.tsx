import { getDict } from "@/lib/i18n";
import { VendorRegisterForm } from "@/components/auth/VendorRegisterForm";

export default async function VendorRegisterPage() {
  const dict = await getDict();
  return (
    <div className="container-app max-w-xl mt-10">
      <div className="card p-6">
        <h1 className="text-2xl font-bold mb-2">{dict.auth.vendorTitle}</h1>
        <p className="text-sm text-gray-600 mb-5">{dict.auth.vendorPending}</p>
        <VendorRegisterForm dict={dict} />
      </div>
    </div>
  );
}
