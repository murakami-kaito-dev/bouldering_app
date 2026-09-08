import type { Metadata } from "next";
import { loadLegal } from "@/lib/legal";
import { LegalDoc } from "@/components/legal/LegalDoc";

export async function generateMetadata(): Promise<Metadata> {
  const doc = await loadLegal("privacy");
  return {
    title: doc.title,
    description: doc.description,
    alternates: { canonical: "/privacy" },
  };
}

export default async function PrivacyPage() {
  const doc = await loadLegal("privacy");
  return <LegalDoc doc={doc} />;
}
