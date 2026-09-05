"use client";

import Link from "next/link";
import { useEffect, useMemo, useRef, useState } from "react";
import { APIProvider, InfoWindow, Map, Marker, useMap } from "@vis.gl/react-google-maps";
import type { GymType } from "@/lib/api/types";
import { env } from "@/lib/env";
import type { GeoPoint, GymSummary } from "@/lib/gym/search";
import { GymTypeTape, OpenTape } from "@/components/ui/Tape";

/**
 * 地図（DESIGN.md「Map」）。Google Maps JS を暗いカスタムスタイルで出す。
 * - mapId は使わない（styles 配列を効かせるため）→ マーカーは classic Marker に SVG の丸。
 * - マーカー色は第一種別（赤=ボルダリング／緑=リード／シアン=スピード）。選択中は拡大＋ wall のリング。
 * - 絞り込み結果に合わせて fitBounds（最大ズーム 15）。
 * - 選択中マーカーの上に ledge 面のカード（名前・テープ・詳細リンク）。
 * - キー未設定なら joint 面のパネルを出してレイアウトだけ保つ。
 */

/** DESIGN.md のトークン（Google Maps には CSS 変数を渡せないので実値） */
const HEX = {
  rock: "#15171B",
  joint: "#1E2126",
  ledge: "#262A31",
  crack: "#2D313A",
  chalk: "#F2F0EA",
  dust: "#9AA0AA",
  ash: "#5F6570",
  wall: "#5B8CFF",
  water: "#0F1114",
  holdRed: "#FF7264",
  holdGreen: "#3FCF8E",
  holdCyan: "#3EC6E0",
} as const;

const TYPE_HEX: Record<GymType, string> = { bouldering: HEX.holdRed, lead: HEX.holdGreen, speed: HEX.holdCyan };

/** 暗いスタイル: 水面 #0F1114・道路 #2D313A・ラベル dust */
const DARK_STYLES: google.maps.MapTypeStyle[] = [
  { elementType: "geometry", stylers: [{ color: HEX.rock }] },
  { elementType: "labels.text.fill", stylers: [{ color: HEX.dust }] },
  { elementType: "labels.text.stroke", stylers: [{ color: HEX.rock }, { weight: 2 }] },
  { elementType: "labels.icon", stylers: [{ visibility: "off" }] },
  { featureType: "administrative", elementType: "geometry.stroke", stylers: [{ color: HEX.crack }] },
  { featureType: "administrative.land_parcel", stylers: [{ visibility: "off" }] },
  { featureType: "administrative.locality", elementType: "labels.text.fill", stylers: [{ color: HEX.chalk }] },
  { featureType: "landscape", elementType: "geometry", stylers: [{ color: HEX.rock }] },
  { featureType: "landscape.man_made", elementType: "geometry.stroke", stylers: [{ color: HEX.joint }] },
  { featureType: "poi", stylers: [{ visibility: "off" }] },
  { featureType: "poi.park", elementType: "geometry", stylers: [{ color: HEX.joint }, { visibility: "on" }] },
  { featureType: "road", elementType: "geometry", stylers: [{ color: HEX.crack }] },
  { featureType: "road", elementType: "geometry.stroke", stylers: [{ color: HEX.joint }] },
  { featureType: "road", elementType: "labels.text.fill", stylers: [{ color: HEX.dust }] },
  { featureType: "road.highway", elementType: "geometry", stylers: [{ color: HEX.ledge }] },
  { featureType: "road.highway", elementType: "geometry.stroke", stylers: [{ color: HEX.crack }] },
  { featureType: "road.local", elementType: "labels", stylers: [{ visibility: "simplified" }] },
  { featureType: "transit", stylers: [{ visibility: "off" }] },
  { featureType: "transit.station.rail", stylers: [{ visibility: "on" }] },
  { featureType: "transit.station.rail", elementType: "labels.text.fill", stylers: [{ color: HEX.dust }] },
  { featureType: "transit.line", elementType: "geometry", stylers: [{ color: HEX.ledge }, { visibility: "on" }] },
  { featureType: "water", elementType: "geometry", stylers: [{ color: HEX.water }] },
  { featureType: "water", elementType: "labels.text.fill", stylers: [{ color: HEX.ash }] },
];

/** 日本全体（結果 0 件のときの初期表示） */
const JAPAN_CENTER = { lat: 36.2, lng: 138.25 };
const JAPAN_ZOOM = 5;
const MAX_FIT_ZOOM = 15;

/** 中心 (0,0) の円の SVG パス。半径 r */
const circlePath = (r: number) => `M -${r},0 a ${r},${r} 0 1,0 ${r * 2},0 a ${r},${r} 0 1,0 -${r * 2},0`;

function markerIcon(gym: GymSummary, mode: "normal" | "hover" | "selected"): google.maps.Symbol {
  const fill = gym.types[0] ? TYPE_HEX[gym.types[0]] : HEX.dust;
  if (mode === "selected") {
    return { path: circlePath(9), fillColor: fill, fillOpacity: 1, strokeColor: HEX.wall, strokeWeight: 4, scale: 1 };
  }
  if (mode === "hover") {
    return { path: circlePath(8), fillColor: fill, fillOpacity: 1, strokeColor: HEX.chalk, strokeWeight: 2, scale: 1 };
  }
  return { path: circlePath(6), fillColor: fill, fillOpacity: 0.95, strokeColor: HEX.rock, strokeWeight: 1.5, scale: 1 };
}

const originIcon: google.maps.Symbol = {
  path: circlePath(7),
  fillColor: HEX.wall,
  fillOpacity: 1,
  strokeColor: HEX.chalk,
  strokeWeight: 2,
  scale: 1,
};

export interface GymMapProps {
  gyms: GymSummary[];
  selectedId: number | null;
  hoveredId?: number | null;
  onSelect: (id: number | null) => void;
  /** 現在地（近い順のとき） */
  origin?: GeoPoint | null;
  /** 営業中のジム id。null なら OPEN/CLOSE を出さない */
  openIds?: Set<number> | null;
  /** 複数の地図が同じページにあるときの識別子 */
  id?: string;
  className?: string;
}

export function GymMap(props: GymMapProps) {
  const { className = "" } = props;
  if (!env.googleMapsApiKey) {
    return (
      <div className={`grain relative flex items-center justify-center rounded-card border border-crack bg-joint ${className}`} role="img" aria-label="地図（未設定）">
        <div className="flex flex-col items-center gap-2 px-6 text-center">
          <span className="text-eyebrow text-ash">MAP</span>
          <p className="text-small text-dust">地図はキー設定後に表示されます</p>
        </div>
      </div>
    );
  }
  return (
    <div
      className={`gym-map relative overflow-hidden rounded-card border border-crack bg-rock ${className} [&_.gm-style-iw-c]:rounded-card! [&_.gm-style-iw-c]:bg-ledge! [&_.gm-style-iw-c]:p-0! [&_.gm-style-iw-c]:shadow-none! [&_.gm-style-iw-d]:overflow-hidden! [&_.gm-style-iw-tc]:hidden [&_.gm-ui-hover-effect]:hidden! [&_.gm-style-iw-ch]:hidden`}
    >
      <APIProvider apiKey={env.googleMapsApiKey} language="ja" region="JP">
        <Map
          id={props.id}
          className="h-full w-full"
          defaultCenter={JAPAN_CENTER}
          defaultZoom={JAPAN_ZOOM}
          styles={DARK_STYLES}
          disableDefaultUI
          zoomControl
          gestureHandling="greedy"
          clickableIcons={false}
          backgroundColor={HEX.rock}
          onClick={() => props.onSelect(null)}
        >
          <MapContents {...props} />
        </Map>
      </APIProvider>
    </div>
  );
}

function MapContents({ gyms, selectedId, hoveredId = null, onSelect, origin = null, openIds = null }: GymMapProps) {
  const map = useMap();
  const markerRefs = useRef(new globalThis.Map<number, google.maps.Marker>());
  const [anchor, setAnchor] = useState<google.maps.Marker | null>(null);

  const selected = useMemo(() => (selectedId === null ? null : (gyms.find((g) => g.id === selectedId) ?? null)), [gyms, selectedId]);

  // 結果の集合が変わったときだけ fitBounds（選択の変更では動かさない）
  const fitKey = useMemo(() => gyms.map((g) => g.id).join(","), [gyms]);
  useEffect(() => {
    if (!map) return;
    const pts = gyms.filter((g) => Number.isFinite(g.lat) && Number.isFinite(g.lng) && (g.lat !== 0 || g.lng !== 0));
    if (pts.length === 0) {
      map.setCenter(JAPAN_CENTER);
      map.setZoom(JAPAN_ZOOM);
      return;
    }
    if (pts.length === 1 && !origin) {
      map.setCenter({ lat: pts[0].lat, lng: pts[0].lng });
      map.setZoom(14);
      return;
    }
    const bounds = new google.maps.LatLngBounds();
    for (const g of pts) bounds.extend({ lat: g.lat, lng: g.lng });
    if (origin) bounds.extend(origin);
    map.fitBounds(bounds, 48);
    const once = google.maps.event.addListenerOnce(map, "idle", () => {
      const z = map.getZoom();
      if (z !== undefined && z > MAX_FIT_ZOOM) map.setZoom(MAX_FIT_ZOOM);
    });
    return () => google.maps.event.removeListener(once);
    // fitKey は gyms の id 列。origin は現在地取得時の 1 回だけ変わる
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [map, fitKey, origin]);

  // 選択されたマーカーが見えていなければ寄せる
  useEffect(() => {
    if (!map || !selected) return;
    const b = map.getBounds();
    const p = { lat: selected.lat, lng: selected.lng };
    if (b && !b.contains(p)) map.panTo(p);
    setAnchor(markerRefs.current.get(selected.id) ?? null);
  }, [map, selected]);

  return (
    <>
      {origin ? <Marker position={origin} icon={originIcon} title="現在地" zIndex={5} clickable={false} /> : null}
      {gyms.map((g) => {
        const mode = g.id === selectedId ? "selected" : g.id === hoveredId ? "hover" : "normal";
        return (
          <Marker
            key={g.id}
            ref={(m) => {
              if (m) markerRefs.current.set(g.id, m);
              else markerRefs.current.delete(g.id);
            }}
            position={{ lat: g.lat, lng: g.lng }}
            title={g.name}
            icon={markerIcon(g, mode)}
            zIndex={mode === "selected" ? 20 : mode === "hover" ? 10 : 1}
            onClick={() => onSelect(g.id === selectedId ? null : g.id)}
          />
        );
      })}
      {selected && anchor ? (
        <InfoWindow anchor={anchor} onCloseClick={() => onSelect(null)} disableAutoPan={false} pixelOffset={[0, -6]}>
          <div className="flex w-[240px] flex-col gap-2 bg-ledge p-3 font-body text-chalk">
            <p className="truncate font-display text-[15px] font-bold leading-[1.3]">{selected.name}</p>
            <p className="truncate text-[12px] text-dust">
              {selected.prefecture}
              {selected.city}
            </p>
            <div className="flex flex-wrap items-center gap-1.5">
              {selected.types.map((t) => (
                <GymTypeTape key={t} type={t} />
              ))}
              {openIds ? <OpenTape open={openIds.has(selected.id)} /> : null}
            </div>
            <Link href={`/gyms/${selected.id}`} className="mt-1 inline-flex h-8 w-fit items-center rounded-pill bg-wall px-4 font-display text-[13px] font-bold text-wall-ink hover:bg-wall-bright">
              詳細
            </Link>
          </div>
        </InfoWindow>
      ) : null}
    </>
  );
}
