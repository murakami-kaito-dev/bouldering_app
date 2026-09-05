import type { ReactNode } from "react";
import type { Gym } from "@/lib/api/types";
import { Panel } from "@/components/ui/Primitives";
import { FeeText } from "./FeeText";
import { HoursTable } from "./HoursTable";

export function googleMapsSearchUrl(gym: Pick<Gym, "lat" | "lng">): string {
  return `https://www.google.com/maps/search/?api=1&query=${gym.lat},${gym.lng}`;
}

function hostOf(url: string): string {
  try {
    return new URL(url).hostname.replace(/^www\./, "");
  } catch {
    return url;
  }
}

function Row({ term, children }: { term: string; children: ReactNode }) {
  return (
    <div className="grid gap-2 py-5 md:grid-cols-[7em_minmax(0,1fr)] md:gap-6">
      <dt className="text-eyebrow text-dust md:pt-1.5">{term}</dt>
      <dd className="min-w-0">{children}</dd>
    </div>
  );
}

const ExternalMark = () => (
  <svg width="12" height="12" viewBox="0 0 12 12" aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="1.5" className="ml-1 inline-block align-[-1px]">
    <path d="M4 2h6v6M10 2 3 9" />
  </svg>
);

const NoInfo = () => <span className="text-small text-ash">情報がありません</span>;

/** 施設情報タブ: 住所・TEL・HP・営業時間・料金・レンタル */
export function FacilityInfo({ gym }: { gym: Gym }) {
  const telHref = gym.tel ? `tel:${gym.tel.replace(/[^\d+]/g, "")}` : null;
  return (
    <dl className="flex flex-col divide-y divide-crack">
      <Row term="住所">
        <a
          href={googleMapsSearchUrl(gym)}
          target="_blank"
          rel="noopener noreferrer"
          className="rounded-tape text-[15px] text-chalk hover:text-wall"
          aria-label={`${gym.fullAddress} を Google マップで開く（新しいタブ）`}
        >
          {gym.fullAddress}
          <span className="ml-2 whitespace-nowrap text-eyebrow text-wall">
            MAP
            <ExternalMark />
          </span>
        </a>
      </Row>

      <Row term="TEL">
        {gym.tel && telHref ? (
          <a href={telHref} className="rounded-tape font-numeric text-[18px] font-semibold tracking-[0.04em] text-chalk hover:text-wall">
            {gym.tel}
          </a>
        ) : (
          <NoInfo />
        )}
      </Row>

      <Row term="HP">
        {gym.hpLink ? (
          <a
            href={gym.hpLink}
            target="_blank"
            rel="noopener noreferrer"
            className="rounded-tape text-[15px] text-wall underline-offset-4 hover:underline"
            aria-label={`公式サイト ${hostOf(gym.hpLink)}（新しいタブ）`}
          >
            {hostOf(gym.hpLink)}
            <ExternalMark />
          </a>
        ) : (
          <NoInfo />
        )}
      </Row>

      <Row term="営業時間">
        <HoursTable gym={gym} />
      </Row>

      <Row term="料金">
        {gym.fee.trim() ? (
          <Panel className="p-4 md:p-5">
            <FeeText text={gym.fee} />
          </Panel>
        ) : (
          <NoInfo />
        )}
      </Row>

      <Row term="レンタル">{gym.rentalFee.trim() ? <FeeText text={gym.rentalFee} /> : <NoInfo />}</Row>
    </dl>
  );
}
