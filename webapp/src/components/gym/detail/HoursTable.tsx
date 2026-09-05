import type { Gym } from "@/lib/api/types";
import { weekRows } from "@/lib/gym/hours";

/** 週の営業時間（月〜日）。今日（JST）の行を壁ブルーの左テープで示し、休みは ash */
export function HoursTable({ gym }: { gym: Gym }) {
  const rows = weekRows(gym);
  return (
    <table className="w-full border-collapse">
      <caption className="sr-only">週の営業時間（日本時間）</caption>
      <tbody>
        {rows.map((r) => (
          <tr key={r.dayIndex} className={r.isToday ? "bg-ledge" : undefined} aria-current={r.isToday ? "date" : undefined}>
            <th
              scope="row"
              className={`w-[4.5em] border-l-[3px] py-2 pl-3 text-left text-[15px] font-medium ${
                r.isToday ? "border-wall text-chalk" : "border-transparent text-dust"
              }`}
            >
              {r.label}
              {r.isToday ? <span className="sr-only">（今日）</span> : null}
            </th>
            <td className={`py-2 pr-3 font-numeric text-[17px] font-semibold tracking-[0.03em] ${r.isClosed ? "text-ash" : "text-chalk"}`}>
              {r.text}
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
