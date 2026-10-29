import type { Metadata, Viewport } from "next";
import "./globals.css";
export const metadata: Metadata = { title: "FieldSales CRM", description: "A focused CRM for leads, follow-ups and projects.", applicationName: "FieldSales CRM", manifest: "/manifest.json" };
export const viewport: Viewport = { themeColor: "#10131a", width: "device-width", initialScale: 1 };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="en"><body>{children}</body></html>; }
