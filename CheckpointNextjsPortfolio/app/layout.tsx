import type { Metadata } from "next";
import Navbar from "@/components/Navbar";
import "./globals.css";

export const metadata: Metadata = {
  title: "Birante Sy — Portfolio",
  description:
    "Portfolio site built with Next.js showcasing my skills, projects, and contact info.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>
        <Navbar />
        <main>{children}</main>
        <footer
          style={{
            textAlign: "center",
            padding: "2rem",
            color: "#6b7280",
            fontSize: "0.85rem",
            borderTop: "1px solid #e5e7eb",
            marginTop: "3rem",
          }}
        >
          © {new Date().getFullYear()} Birante Sy — Built with Next.js.
        </footer>
      </body>
    </html>
  );
}
