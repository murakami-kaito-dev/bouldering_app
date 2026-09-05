import type { Gym } from "@/lib/api/types";
import { env } from "@/lib/env";
import { PREFECTURE_SLUGS } from "@/lib/gym/prefectures";

const DAY_URI = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"].map((d) => `https://schema.org/${d}`);

/** `</script>` での抜け出しを防ぐ */
function safeJson(v: unknown): string {
  return JSON.stringify(v).replace(/</g, "\\u003c");
}

/** JSON-LD: SportsActivityLocation（営業時間つき。aggregateRating は付けない）＋ BreadcrumbList */
export function GymJsonLd({ gym }: { gym: Gym }) {
  const base = env.siteUrl.replace(/\/$/, "");
  const url = `${base}/gyms/${gym.id}`;
  const slug = (PREFECTURE_SLUGS as Record<string, string | undefined>)[gym.prefecture];

  const openingHours = gym.hours.flatMap((d, i) =>
    d.open && d.close ? [{ "@type": "OpeningHoursSpecification", dayOfWeek: DAY_URI[i], opens: d.open, closes: d.close }] : [],
  );

  const place = {
    "@context": "https://schema.org",
    "@type": "SportsActivityLocation",
    "@id": url,
    name: gym.name,
    url,
    address: {
      "@type": "PostalAddress",
      addressCountry: "JP",
      addressRegion: gym.prefecture,
      addressLocality: gym.city,
      streetAddress: gym.addressLine,
    },
    geo: { "@type": "GeoCoordinates", latitude: gym.lat, longitude: gym.lng },
    ...(gym.tel ? { telephone: gym.tel } : {}),
    ...(gym.hpLink ? { sameAs: gym.hpLink } : {}),
    ...(openingHours.length > 0 ? { openingHoursSpecification: openingHours } : {}),
  };

  const crumbs = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: [
      { "@type": "ListItem", position: 1, name: "ジムを探す", item: `${base}/gyms` },
      { "@type": "ListItem", position: 2, name: gym.prefecture, ...(slug ? { item: `${base}/gyms/area/${slug}` } : {}) },
      { "@type": "ListItem", position: 3, name: gym.name, item: url },
    ],
  };

  return (
    <>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: safeJson(place) }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: safeJson(crumbs) }} />
    </>
  );
}
