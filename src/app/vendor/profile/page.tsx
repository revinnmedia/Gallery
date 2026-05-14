import { getCurrentUser } from "@/lib/auth";
import { getDict } from "@/lib/i18n";
import { VendorProfileForm } from "@/components/vendor/VendorProfileForm";

export default async function VendorProfile() {
  const user = await getCurrentUser();
  const dict = await getDict();
  if (!user?.vendor) return null;

  return (
    <div className="card p-6 max-w-2xl">
      <h2 className="text-xl font-bold mb-4">{dict.vendor.profile}</h2>
      <VendorProfileForm
        dict={dict}
        initial={{
          shopName: user.vendor.shopName,
          shopNameEn: user.vendor.shopNameEn || "",
          city: user.vendor.city,
          address: user.vendor.address || "",
          description: user.vendor.description || "",
        }}
      />
    </div>
  );
}
