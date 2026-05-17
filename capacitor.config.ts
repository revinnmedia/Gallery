import type { CapacitorConfig } from "@capacitor/cli";

const config: CapacitorConfig = {
  appId: "com.matba3ah.app",
  appName: "مطبعة",
  webDir: "mobile/www",
  server: {
    // When set, the app loads the live website inside the native shell.
    // Replace with your deployed URL (e.g. Vercel) before running `cap sync`.
    url: process.env.CAPACITOR_SERVER_URL || "https://matba3ah.vercel.app",
    cleartext: false,
    androidScheme: "https",
  },
  android: {
    allowMixedContent: false,
  },
  ios: {
    contentInset: "always",
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 1200,
      backgroundColor: "#1f56e6",
      androidSplashResourceName: "splash",
      showSpinner: false,
    },
    StatusBar: {
      style: "DARK",
      backgroundColor: "#1f56e6",
    },
  },
};

export default config;
