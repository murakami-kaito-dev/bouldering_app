"use client";

import { useEffect, useId, useMemo, useRef, useState } from "react";
import { normalizeQuery } from "@/lib/gym/types";
import { Tape } from "@/components/ui/Tape";

export interface PickerGym {
  id: number;
  name: string;
  prefecture: string;
  city: string;
}

const MAX_SHOWN = 30;

/**
 * ジム選択のコンボボックス。名前・都道府県・市区町村で部分一致（ひらがな/カタカナ・全角の揺れを吸収）。
 * 選択中はテキスト入力の代わりに「選んだジム」を出し、× で解除。
 */
export function GymCombobox({
  gyms,
  value,
  onChange,
  invalid = false,
}: {
  gyms: PickerGym[];
  value: PickerGym | null;
  onChange: (g: PickerGym | null) => void;
  invalid?: boolean;
}) {
  const [query, setQuery] = useState("");
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(0);
  const listId = useId();
  const rootRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const indexed = useMemo(() => gyms.map((g) => ({ g, key: normalizeQuery(`${g.name}${g.prefecture}${g.city}`) })), [gyms]);
  const results = useMemo(() => {
    const n = normalizeQuery(query);
    if (!n) return [];
    return indexed.filter((x) => x.key.includes(n)).slice(0, MAX_SHOWN).map((x) => x.g);
  }, [indexed, query]);

  useEffect(() => {
    if (!open) return;
    const onDown = (e: MouseEvent | TouchEvent) => {
      if (rootRef.current && !rootRef.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener("mousedown", onDown);
    document.addEventListener("touchstart", onDown);
    return () => {
      document.removeEventListener("mousedown", onDown);
      document.removeEventListener("touchstart", onDown);
    };
  }, [open]);

  const activeIndex = Math.min(active, Math.max(0, results.length - 1));

  const select = (g: PickerGym) => {
    onChange(g);
    setQuery("");
    setOpen(false);
  };

  if (value) {
    return (
      <div className="flex h-12 items-center justify-between gap-3 rounded-card border border-crack bg-ledge px-4">
        <span className="flex min-w-0 items-center gap-3">
          <Tape tone="wall">{value.prefecture.replace(/[都府県]$/, "") || "—"}</Tape>
          <span className="truncate font-display text-[16px] font-bold text-chalk">{value.name}</span>
          <span className="hidden truncate text-small text-dust md:inline">{value.city}</span>
        </span>
        <button
          type="button"
          onClick={() => {
            onChange(null);
            setTimeout(() => inputRef.current?.focus(), 0);
          }}
          className="pressable shrink-0 rounded-pill px-2 text-[13px] font-bold text-dust hover:text-chalk"
          aria-label="ジムの選択を解除"
        >
          変更
        </button>
      </div>
    );
  }

  return (
    <div ref={rootRef} className="relative">
      <input
        ref={inputRef}
        type="text"
        role="combobox"
        aria-expanded={open && results.length > 0}
        aria-controls={listId}
        aria-autocomplete="list"
        aria-invalid={invalid || undefined}
        value={query}
        placeholder="ジム名・都道府県・市区町村で検索"
        autoComplete="off"
        onChange={(e) => {
          setQuery(e.target.value);
          setActive(0);
          setOpen(true);
        }}
        onFocus={() => setOpen(true)}
        onKeyDown={(e) => {
          if (!open || results.length === 0) return;
          if (e.key === "ArrowDown") {
            e.preventDefault();
            setActive((i) => Math.min(results.length - 1, i + 1));
          } else if (e.key === "ArrowUp") {
            e.preventDefault();
            setActive((i) => Math.max(0, i - 1));
          } else if (e.key === "Enter") {
            e.preventDefault();
            select(results[activeIndex]);
          } else if (e.key === "Escape") {
            setOpen(false);
          }
        }}
        className={`h-12 w-full rounded-card border bg-ledge px-4 text-[16px] text-chalk placeholder:text-dust focus:outline-none ${invalid ? "border-hold-red" : "border-crack focus:border-wall"}`}
      />
      {open && query.trim() !== "" ? (
        <ul
          id={listId}
          role="listbox"
          className="absolute left-0 right-0 top-[calc(100%+6px)] z-30 max-h-72 overflow-y-auto rounded-card border border-crack bg-joint py-1"
        >
          {results.length === 0 ? (
            <li className="px-4 py-3 text-small text-dust">見つかりません。ジム名の一部や市区町村で試してください。</li>
          ) : (
            results.map((g, i) => (
              <li
                key={g.id}
                role="option"
                aria-selected={i === activeIndex}
                onMouseDown={(e) => e.preventDefault()}
                onClick={() => select(g)}
                onMouseEnter={() => setActive(i)}
                className={`flex cursor-pointer items-center gap-3 px-4 py-2 ${i === activeIndex ? "bg-ledge" : ""}`}
              >
                <Tape tone="wall">{g.prefecture.replace(/[都府県]$/, "") || "—"}</Tape>
                <span className="flex min-w-0 flex-col">
                  <span className="truncate font-display text-[15px] font-bold text-chalk">{g.name}</span>
                  <span className="truncate text-small text-dust">{g.city}</span>
                </span>
              </li>
            ))
          )}
        </ul>
      ) : null}
    </div>
  );
}
