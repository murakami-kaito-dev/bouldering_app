import type { Metadata } from "next";
import { loadLegal } from "@/lib/legal";
import { LegalDoc } from "@/components/legal/LegalDoc";

export async function generateMetadata(): Promise<Metadata> {
  const doc = await loadLegal("terms");
  return {
    title: doc.title,
    description: doc.description,
    alternates: { canonical: "/terms" },
  };
}

export default async function TermsPage() {
  const doc = await loadLegal("terms");
  return <LegalDoc doc={doc} />;
}
