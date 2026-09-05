"use client";

import { APIProvider, Map as GoogleMap, Marker } from "@vis.gl/react-google-maps";
import { env } from "@/lib/env";
import type { GymType } from "@/lib/api/types";

/** DESIGN.md「Map」: 暗いカスタムスタイル（水面 #0F1114・道路 crack・ラベル dust）。色はトークンの値のみ */
const DARK_STYLE: google.maps.MapTypeStyle[] = [
  { elementType: "geometry", stylers: [{ color: "#1E2126" }] },
  { elementType: "labels.text.fill", stylers: [{ color: "#9AA0AA" }] },
  { elementType: "labels.text.stroke", stylers: [{ color: "#15171B" }] },
  { elementType: "labels.icon", stylers: [{ visibility: "off" }] },
  { featureType: "administrative", elementType: "geometry.stroke", stylers: [{ color: "#2D313A" }] },
  { featureType: "landscape.man_made", elementType: "geometry", stylers: [{ color: "#1E2126" }] },
  { featureType: "poi", stylers: [{ visibility: "off" }] },
  { featureType: "road", elementType: "geometry", stylers: [{ color: "#2D313A" }] },
  { featureType: "road", elementType: "geometry.stroke", stylers: [{ color: "#15171B" }] },
  { featureType: "road.highway", elementType: "geometry", stylers: [{ color: "#5F6570" }] },
  { featureType: "road", elementType: "labels.text.fill", stylers: [{ color: "#9AA0AA" }] },
  { featureType: "transit", stylers: [{ visibility: "off" }] },
  { featureType: "transit.station.rail", elementType: "labels.text.fill", stylers: [{ visibility: "on" }, { color: "#9AA0AA" }] },
  { featureType: "water", elementType: "geometry", stylers: [{ color: "#0F1114" }] },
  { featureType: "water", elementType: "labels.text.fill", stylers: [{ color: "#5F6570" }] },
];

/** 種別色（DESIGN.md）。SVG に埋めるため hex 直値 */
const TYPE_HEX: Record<GymType, string> = { bouldering: "#FF7264", lead: "#3FCF8E", speed: "#3EC6E0" };

function pinIcon(color: string): string {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="30" height="40" viewBox="0 0 30 40"><path d="M15 39C13.5 32 2 25.5 2 15a13 13 0 1 1 26 0c0 10.5-11.5 17-13 24z" fill="${color}" stroke="#15171B" stroke-width="2"/><circle cx="15" cy="15" r="5" fill="#15171B"/></svg>`;
  return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`;
}

interface Props {
  name: string;
  lat: number;
  lng: number;
  types: GymType[];
  address: string;
  mapsUrl: string;
  className?: string;
}

const OpenInMaps = ({ href }: { href: string }) => (
  <a
    href={href}
    target="_blank"
    rel="noopener noreferrer"
    className="flex h-11 items-center justify-between px-4 text-[14px] text-dust hover:bg-ledge hover:text-chalk"
  >
    <span>Google マップで開く</span>
    <span className="text-eyebrow text-wall">MAP ↗</span>
  </a>
);

/**
 * 右レールの小さな地図（1 マーカー・zoom 15）。
 * Maps キーが未設定なら同寸の joint パネル（住所と Google マップへのリンク）を出してレイアウトを崩さない。
 */
export function GymMap({ name, lat, lng, types, address, mapsUrl, className = "" }: Props) {
  const key = env.googleMapsApiKey;
  const color = TYPE_HEX[types[0] ?? "bouldering"];

  if (!key) {
    return (
      <div className={`overflow-hidden rounded-card border border-crack bg-joint ${className}`}>
        <div className="grain relative flex h-[240px] flex-col items-start justify-end gap-1 p-4">
          <span className="text-eyebrow text-ash">MAP · 準備中</span>
          <p className="text-small text-dust">{address}</p>
        </div>
        <div className="border-t border-crack">
          <OpenInMaps href={mapsUrl} />
        </div>
      </div>
    );
  }

  return (
    <div className={`overflow-hidden rounded-card border border-crack bg-joint ${className}`}>
      <APIProvider apiKey={key} language="ja" region="JP">
        <GoogleMap
          defaultCenter={{ lat, lng }}
          defaultZoom={15}
          styles={DARK_STYLE}
          backgroundColor="#15171B"
          disableDefaultUI
          zoomControl
          gestureHandling="cooperative"
          clickableIcons={false}
          className="h-[240px] w-full"
          aria-label={`${name} の地図`}
        >
          <Marker position={{ lat, lng }} title={name} icon={{ url: pinIcon(color) }} />
        </GoogleMap>
      </APIProvider>
      <div className="border-t border-crack">
        <OpenInMaps href={mapsUrl} />
      </div>
    </div>
  );
}
