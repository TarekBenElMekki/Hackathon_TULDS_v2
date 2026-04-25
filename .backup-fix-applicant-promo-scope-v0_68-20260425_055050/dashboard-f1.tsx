"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { Flag, MapPin, Radio, RefreshCcw, Trophy, Wifi, WifiOff } from "lucide-react";

type DashboardRow = Record<string, string | number | null | undefined>;

type AnalyticsRouteResponse = {
 ok: boolean;
 error?: string;
 rows?: DashboardRow[];
 requested?: {
 officeId?: string;
 startDate?: string;
 endDate?: string;
 };
};

type BoardRow = {
 rowId: string;
 label: string;
 shortLabel: string;
 approvedTotal: number;
 realizedTotal: number;
 completedTotal: number;
 finishedTotal: number;
 appliedTotal: number;
 o7: number;
 i7: number;
 o8: number;
 i8: number;
 o9: number;
 i9: number;
 score: number;
 rank: number;
 color: string;
};

type ProductBoard = {
 key: keyof Pick<BoardRow, "o7" | "i7" | "o8" | "i8" | "o9" | "i9">;
 title: string;
 subtitle: string;
};

const PRODUCT_BOARDS: ProductBoard[] = [
 { key: "o7", title: "oGV", subtitle: "Outgoing / Product 7" },
 { key: "i7", title: "iGV", subtitle: "Incoming / Product 7" },
 { key: "o8", title: "oGTa", subtitle: "Outgoing / Product 8" },
 { key: "i8", title: "iGTa", subtitle: "Incoming / Product 8" },
 { key: "o9", title: "oGTe", subtitle: "Outgoing / Product 9" },
 { key: "i9", title: "iGTe", subtitle: "Incoming / Product 9" },
];

const COLORS = ["#e10600", "#ff8700", "#00d2be", "#3671c6", "#b6ff00", "#ff4ecd", "#ffd700", "#00d26a", "#9b5cff", "#ffffff", "#64c4ff", "#ff595e"];
/* === REAL API LC NAME MAP v0_61 START === */
const LC_NAME_MAP: Record<string, string> = {
  "513": "Carthage",
  "1277": "Bardo",
  "1270": "Medina",
  "1559": "Ariana",
  "1601": "Sfax",
  "1702": "Sousse",
  "1803": "Bizerte",
};

const LC_LABEL_MAP: Record<string, string> = {
  "lc carthage": "Carthage",
  "carthage": "Carthage",
  "lc bardo": "Bardo",
  "bardo": "Bardo",
  "lc medina": "Medina",
  "medina": "Medina",
  "lc ariana": "Ariana",
  "ariana": "Ariana",
  "lc sfax": "Sfax",
  "sfax": "Sfax",
  "lc sousse": "Sousse",
  "sousse": "Sousse",
  "lc bizerte": "Bizerte",
  "bizerte": "Bizerte",
};

function normalizeLcKey(value: string): string {
  return value
    .toLowerCase()
    .replace(/\s*\(\d+\)\s*$/, "")
    .replace(/[_-]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function displayLcName(rowId: string, label: string): string {
  const idKey = String(rowId ?? "").trim();
  if (LC_NAME_MAP[idKey]) return LC_NAME_MAP[idKey];

  const cleaned = label.replace(/\s*\(\d+\)\s*$/, "").trim();
  const normalized = normalizeLcKey(cleaned);

  if (LC_LABEL_MAP[normalized]) return LC_LABEL_MAP[normalized];

  return cleaned.replace(/^LC\s+/i, "").trim() || cleaned || idKey || "Unknown LC";
}
/* === REAL API LC NAME MAP v0_61 END === */


const FALLBACK_ROWS: DashboardRow[] = [
 { row_id: "global", row_label: "Global", approved_total: 148, realized_total: 91, completed_total: 44, finished_total: 63, applied_total: 420 },
 { row_id: "513", row_label: "LC Carthage", approved_total: 28, realized_total: 20, completed_total: 8, finished_total: 12, applied_total: 90, o_approved_7: 6, i_approved_7: 4, o_approved_8: 8, i_approved_8: 3, o_approved_9: 5, i_approved_9: 2 },
 { row_id: "1277", row_label: "LC Bardo", approved_total: 24, realized_total: 15, completed_total: 7, finished_total: 11, applied_total: 74, o_approved_7: 4, i_approved_7: 5, o_approved_8: 5, i_approved_8: 4, o_approved_9: 4, i_approved_9: 2 },
 { row_id: "1270", row_label: "LC Medina", approved_total: 21, realized_total: 12, completed_total: 5, finished_total: 9, applied_total: 69, o_approved_7: 5, i_approved_7: 2, o_approved_8: 4, i_approved_8: 5, o_approved_9: 3, i_approved_9: 2 },
 { row_id: "1559", row_label: "LC Ariana", approved_total: 18, realized_total: 11, completed_total: 6, finished_total: 7, applied_total: 61, o_approved_7: 3, i_approved_7: 3, o_approved_8: 5, i_approved_8: 2, o_approved_9: 3, i_approved_9: 2 },
 { row_id: "1601", row_label: "LC Sfax", approved_total: 15, realized_total: 9, completed_total: 4, finished_total: 6, applied_total: 55, o_approved_7: 2, i_approved_7: 3, o_approved_8: 3, i_approved_8: 4, o_approved_9: 2, i_approved_9: 1 },
 { row_id: "1702", row_label: "LC Sousse", approved_total: 11, realized_total: 7, completed_total: 3, finished_total: 5, applied_total: 40, o_approved_7: 2, i_approved_7: 1, o_approved_8: 3, i_approved_8: 2, o_approved_9: 2, i_approved_9: 1 },
 { row_id: "1803", row_label: "LC Bizerte", approved_total: 8, realized_total: 4, completed_total: 2, finished_total: 3, applied_total: 28, o_approved_7: 1, i_approved_7: 1, o_approved_8: 2, i_approved_8: 1, o_approved_9: 2, i_approved_9: 1 },
];

function toNumber(row: DashboardRow, key: string): number {
 const value = row[key];
 if (typeof value === "number" && Number.isFinite(value)) return value;
 const parsed = Number(value ?? 0);
 return Number.isFinite(parsed) ? parsed : 0;
}

function cleanLabel(value: string): string { return displayLcName("", value); }

function initials(value: string): string {
 const words = cleanLabel(value).split(/\s+/).filter(Boolean);
 if (words.length === 0) return "ID";
 if (words.length === 1) return words[0].slice(0, 3).toUpperCase();
 return words.slice(0, 2).map((w) => w[0]).join("").toUpperCase();
}

function buildRows(rows: DashboardRow[]): BoardRow[] {
  return rows
    .filter((row) => String(row.row_id ?? "").toLowerCase() !== "global")
    .map((row, index) => {
      const rowId = String(row.row_id ?? index + 1);
      const rawLabel = String(row.row_label ?? row.row_name ?? row.office_name ?? rowId);
      const shortLabel = displayLcName(rowId, rawLabel);

      const approvedTotal = toNumber(row, "approved_total");
      const realizedTotal = toNumber(row, "realized_total");
      const completedTotal = toNumber(row, "completed_total");
      const finishedTotal = toNumber(row, "finished_total");
      const appliedTotal = toNumber(row, "applied_total");

      const o7 = toNumber(row, "o_approved_7");
      const i7 = toNumber(row, "i_approved_7");
      const o8 = toNumber(row, "o_approved_8");
      const i8 = toNumber(row, "i_approved_8");
      const o9 = toNumber(row, "o_approved_9");
      const i9 = toNumber(row, "i_approved_9");

      return {
        rowId,
        label: rawLabel,
        shortLabel,
        approvedTotal,
        realizedTotal,
        completedTotal,
        finishedTotal,
        appliedTotal,
        o7,
        i7,
        o8,
        i8,
        o9,
        i9,
        score: approvedTotal,
        rank: 0,
        color: COLORS[index % COLORS.length],
      };
    })
    .sort((a, b) =>
      b.approvedTotal - a.approvedTotal ||
      b.appliedTotal - a.appliedTotal ||
      b.realizedTotal - a.realizedTotal ||
      a.shortLabel.localeCompare(b.shortLabel)
    )
    .map((row, index) => ({ ...row, rank: index + 1 }));
}

function LeaderboardTable({ rows }: { rows: BoardRow[] }) {
  const rankedRows = useMemo(() => rows, [rows]);
  const [globalOffset, setGlobalOffset] = useState(0);

  useEffect(() => {
    if (rankedRows.length <= 7) {
      setGlobalOffset(0);
      return;
    }

    const interval = window.setInterval(() => {
      setGlobalOffset((previous) => (previous + 1) % rankedRows.length);
    }, 2200);

    return () => window.clearInterval(interval);
  }, [rankedRows.length]);

  const visibleRows = useMemo(() => {
    if (rankedRows.length === 0) return [];

    const visibleCount = Math.min(7, rankedRows.length);

    return Array.from({ length: visibleCount }, (_, index) => {
      return rankedRows[(globalOffset + index) % rankedRows.length];
    });
  }, [rankedRows, globalOffset]);

  return (
    <div
      className="sketch-carousel-window sketch-global-carousel-window"
      title={`Rotating all ${rankedRows.length} ranked LCs`}
    >
      <table className="sketch-table sketch-global-table sketch-global-carousel-table">
        <thead>
          <tr>
            <th>Pos</th>
            <th>ID / Entity</th>
            <th>App</th>
            <th>Appr</th>
            <th>Real</th>
          </tr>
        </thead>
        <tbody className="sketch-global-carousel-body">
          {visibleRows.map((row, index) => (
            <tr key={`global-${row.rowId}-${globalOffset}-${index}`} className="sketch-global-carousel-row">
              <td className="sketch-pos">{row.rank}</td>
              <td>
                <div className="sketch-team-cell">
                  <span className="sketch-color-bar" style={{ background: row.color }} />
                  <span className="sketch-team-label">{row.shortLabel}</span>
                </div>
              </td>
              <td>{row.appliedTotal}</td>
              <td className="sketch-score">{row.approvedTotal}</td>
              <td>{row.realizedTotal}</td>
            </tr>
          ))}
        </tbody>
      </table>

      <div className="sketch-global-carousel-status">
        ALL RANKED LCs ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â· {rankedRows.length} TOTAL
      </div>
    </div>
  );
}

function ProductTable({ config, rows }: { config: ProductBoard; rows: BoardRow[] }) {
  const rankedRows = useMemo(() => {
    return [...rows]
      .sort((a, b) =>
        Number(b[config.key] ?? 0) - Number(a[config.key] ?? 0) ||
        b.approvedTotal - a.approvedTotal ||
        b.appliedTotal - a.appliedTotal ||
        a.shortLabel.localeCompare(b.shortLabel)
      )
      .map((row, index) => ({ ...row, productRank: index + 1 }));
  }, [config.key, rows]);

  const carouselRows = rankedRows.length > 0 ? [...rankedRows, ...rankedRows] : [];

  return (
    <section className="sketch-card sketch-product-card sketch-carousel-card">
      <div className="sketch-card-head sketch-mini-head">
        <div>
          <h3>{config.title}</h3>
          <p>{config.subtitle} ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â· real API approvals</p>
        </div>
        <div className="sketch-product-tag">APPROVALS</div>
      </div>

      <div className="sketch-carousel-window">
        <table className="sketch-table sketch-mini-table sketch-carousel-table">
          <thead>
            <tr>
              <th>Pos</th>
              <th>LC</th>
              <th>Appr</th>
            </tr>
          </thead>
          <tbody className="sketch-carousel-track-y">
            {carouselRows.map((row, index) => (
              <tr key={`${config.key}-${row.rowId}-${index}`}>
                <td className="sketch-pos">{row.productRank}</td>
                <td>
                  <div className="sketch-team-cell">
                    <span className="sketch-color-dot" style={{ background: row.color }} />
                    <span className="sketch-team-label">{row.shortLabel}</span>
                  </div>
                </td>
                <td className="sketch-score">{Number(row[config.key] ?? 0)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}

function TrackMap({ rows }: { rows: BoardRow[] }) {
  const nodes = rows;

  const points = [
    [52, 10],
    [63, 17],
    [74, 29],
    [80, 45],
    [76, 62],
    [67, 79],
    [56, 90],
    [43, 82],
    [31, 64],
    [23, 45],
    [28, 25],
    [42, 15],
    [70, 18],
    [84, 53],
    [61, 86],
    [37, 74],
  ];

  return (
    <section className="sketch-card sketch-map-card">
      <div className="sketch-card-head">
        <div>
          <h2>Global Race Track</h2>
          <p>Logos follow global approval ranking</p>
        </div>
        <Flag size={18} />
      </div>

      <div className="sketch-track-stage">
        <svg className="sketch-track-svg" viewBox="0 0 420 320" aria-hidden="true">
          <defs>
            <linearGradient id="trackGlow" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0%" stopColor="#e10600" />
              <stop offset="48%" stopColor="#ffffff" />
              <stop offset="100%" stopColor="#e10600" />
            </linearGradient>
          </defs>

          <path
            className="sketch-track-shadow"
            d="M214 23
               C247 26 272 42 293 67
               C318 96 342 129 351 167
               C357 194 347 226 326 247
               C307 266 287 278 270 292
               C252 307 229 312 206 309
               C182 306 163 297 149 283
               C136 270 131 252 127 235
               C121 209 102 194 91 177
               C80 160 74 140 77 118
               C80 96 92 77 111 59
               C128 43 146 32 169 26
               C187 21 201 21 214 23 Z"
          />
          <path
            className="sketch-track-main"
            d="M214 23
               C247 26 272 42 293 67
               C318 96 342 129 351 167
               C357 194 347 226 326 247
               C307 266 287 278 270 292
               C252 307 229 312 206 309
               C182 306 163 297 149 283
               C136 270 131 252 127 235
               C121 209 102 194 91 177
               C80 160 74 140 77 118
               C80 96 92 77 111 59
               C128 43 146 32 169 26
               C187 21 201 21 214 23 Z"
          />
          <path
            className="sketch-track-inner"
            d="M214 53
               C236 56 253 67 267 85
               C286 109 306 133 313 161
               C318 182 311 203 294 221
               C280 236 264 248 250 260
               C236 272 219 277 202 275
               C184 273 170 267 160 256
               C151 246 148 232 145 219
               C141 199 127 188 118 173
               C109 159 104 143 107 126
               C109 110 118 96 132 84
               C145 72 158 65 174 61
               C187 58 200 58 214 53 Z"
          />

          <circle cx="216" cy="28" r="8" className="sketch-start-marker" />
          <circle cx="228" cy="303" r="8" className="sketch-arrival-marker" />
          <line x1="205" y1="20" x2="235" y2="35" className="sketch-finish-line" />
        </svg>

        <div className="sketch-track-chip sketch-track-start" style={{ left: "52%", top: "9%" }}>
          <span className="sketch-track-dot" />
          START
        </div>

        <div className="sketch-track-chip sketch-track-arrival" style={{ left: "55%", top: "89%" }}>
          <span className="sketch-track-dot sketch-track-dot-arrival" />
          ARRIVAL
        </div>

        {nodes.map((row, index) => {
          const [left, top] = points[index % points.length];
          const offset = Math.floor(index / points.length) * 2;

          return (
            <div
              className="sketch-map-node sketch-map-node-global"
              key={row.rowId}
              style={{
                left: `${Math.min(91, left + offset)}%`,
                top: `${Math.min(92, top + offset)}%`,
              }}
              title={`P${row.rank} ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â· ${row.shortLabel} ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â· ${row.approvedTotal} approvals`}
            >
              <span className="sketch-map-rank">P{row.rank}</span>
              <span
                className="sketch-map-logo"
                style={{ borderColor: row.color, boxShadow: `0 0 18px ${row.color}66` }}
              >
                {initials(row.shortLabel)}
              </span>
              <span className="sketch-map-label">{row.shortLabel}</span>
            </div>
          );
        })}

        <div className="sketch-map-live">
          <MapPin size={13} /> GLOBAL RACE
        </div>
      </div>
    </section>
  );
}

function Podium({ rows }: { rows: BoardRow[] }) {
  const top = rows.slice(0, 3);
  const first = top[0];
  const second = top[1];
  const third = top[2];

  return (
    <section className="sketch-card sketch-podium-card">
      <div className="sketch-card-head sketch-podium-head">
        <div>
          <h2>Global Ranking Podium</h2>
          <p>Top 3 by total approvals</p>
        </div>
        <Trophy size={18} />
      </div>
      <div className="sketch-podium-stage">
        {[second, first, third].filter(Boolean).map((row) => (
          <div key={row.rowId} className={`sketch-podium-item sketch-place-${row.rank}`}>
            <div className="sketch-podium-logo" style={{ borderColor: row.color }}>{initials(row.shortLabel)}</div>
            <div className="sketch-podium-name sketch-podium-rank-label">P{row.rank}</div>
            <div className="sketch-podium-points">{row.approvedTotal} approvals ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â· {row.appliedTotal} applicants</div>
            <div className="sketch-podium-step sketch-podium-entity-label">{row.shortLabel}</div>
          </div>
        ))}
      </div>
    </section>
  );
}

export default function DashboardF1() {
 const router = useRouter();
 const [payload, setPayload] = useState<AnalyticsRouteResponse | null>(null);
 const [loading, setLoading] = useState(true);
 const [refreshing, setRefreshing] = useState(false);
 const [error, setError] = useState<string | null>(null);
 const [now, setNow] = useState<Date | null>(null);

 const fetchDashboard = async (manual = false) => {
 if (manual) setRefreshing(true);
 try {
 setError(null);
 const response = await fetch("/api/aiesec-analytics", { cache: "no-store" });
 const json = (await response.json()) as AnalyticsRouteResponse;
 if (!response.ok || !json.ok) {
 setError(json.error ?? "Analytics API error");
 setPayload({ ok: true, rows: FALLBACK_ROWS });
 } else {
 setPayload(json);
 }
 } catch (err) {
 setError(err instanceof Error ? err.message : "Analytics API unavailable");
 setPayload({ ok: true, rows: FALLBACK_ROWS });
 } finally {
 setLoading(false);
 setRefreshing(false);
 }
 };

 useEffect(() => {
 void fetchDashboard(false);
 setNow(new Date());
 const tick = window.setInterval(() => setNow(new Date()), 1000);
 const refresh = window.setInterval(() => void fetchDashboard(false), 60000);
 
  const applicantPromoText = useMemo(() => {
    if (!rows || rows.length === 0) return "No applicant data yet";

    return rows
      .map((row) => `${row.shortLabel}: ${row.appliedTotal} applicants`)
      .join(" | ");
  }, [rows]);
return () => {
 window.clearInterval(tick);
 window.clearInterval(refresh);
 };
 }, []);

 const sourceRows = payload?.rows && payload.rows.length > 1 ? payload.rows : FALLBACK_ROWS;
 const rows = useMemo(() => buildRows(sourceRows), [sourceRows]);
 const globalRow = sourceRows.find((row) => String(row.row_id ?? "") === "global");
 const globalApproved = globalRow ? toNumber(globalRow, "approved_total") : rows.reduce((sum, row) => sum + row.approvedTotal, 0);
 const globalRealized = globalRow ? toNumber(globalRow, "realized_total") : rows.reduce((sum, row) => sum + row.realizedTotal, 0);
 const globalApplied = globalRow ? toNumber(globalRow, "applied_total") : rows.reduce((sum, row) => sum + row.appliedTotal, 0);

 const timeText = now ? now.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit", second: "2-digit" }) : "--:--:--";
 const dateText = now ? now.toLocaleDateString("en-GB", { day: "2-digit", month: "short", year: "numeric" }) : "-- --- ----";
 const rangeText = payload?.requested?.startDate && payload?.requested?.endDate ? `${payload.requested.startDate} a' ${payload.requested.endDate}` : "Live range";

 const appliedRanking = useMemo(() => {
 return [...rows]
 .sort((a, b) =>
 b.appliedTotal - a.appliedTotal ||
 b.approvedTotal - a.approvedTotal ||
 a.shortLabel.localeCompare(b.shortLabel)
 )
 .slice(0, 12)
 .map((row, index) => `${row.shortLabel}: ${index + 1}`)
 .join(" ? ");
 }, [rows]);
 const appliedRankingText = useMemo(() => {
 const ranked = [...rows]
 .sort((a, b) => b.appliedTotal - a.appliedTotal || b.approvedTotal - a.approvedTotal || a.shortLabel.localeCompare(b.shortLabel))
 .slice(0, 12);
 return ranked.map((row, index) => `${row.shortLabel}: ${index + 1}`).join(" - ");
 }, [rows]);

 return (
 <main className="sketch-race-page">
 <div className="sketch-shell">
 <header className="sketch-header">
          <div className="sketch-header-flag-deco" aria-hidden="true">
            <span className="sketch-header-flag-pole" />
            <span className="sketch-header-flag-cloth" />
          </div>
<div className="sketch-brand">
 <div className="sketch-kicker">AIESEC FORMULA ANALYTICS</div>
 <h1>Race Control Dashboard</h1>
 <p>Symmetric F1 broadcast layout - no-scroll tables - approval performance</p>
 </div>
 <div className="sketch-header-metrics">
 <div className="sketch-metric"><span>Applied</span><strong>{globalApplied}</strong></div>
 <div className="sketch-metric sketch-red"><span>Approved</span><strong>{globalApproved}</strong></div>
 <div className="sketch-metric"><span>Realized</span><strong>{globalRealized}</strong></div>
 <div className="sketch-clock"><span>{dateText}</span><strong>{timeText}</strong></div>
 <button className="sketch-refresh" onClick={() => void fetchDashboard(true)} disabled={refreshing}>
 <RefreshCcw size={14} className={refreshing ? "spin" : ""} />
 {refreshing ? "Refreshing" : "Refresh"}
 </button>
 <button className="sketch-control" onClick={() => router.push("/admin")}>Race Control</button>
 </div>
 </header>

 {error ? <div className="sketch-alert"><WifiOff size={14} /> {error} - showing safe local fallback if needed</div> : null}

 <section className="sketch-main-grid">
 <section className="sketch-card sketch-global-card">
 <div className="sketch-card-head">
 <div>
 <h2>Global Approval Table</h2>
 <p>{loading ? "Loading live data..." : `All ${rows.length} ranked LCs - ${rangeText}`}</p>
 </div>
 <div className="sketch-live-pill">{error ? <WifiOff size={13} /> : <Wifi size={13} />} LIVE</div>
 </div>
 <LeaderboardTable rows={rows} />
 </section>

 <section className="sketch-products-zone">
 {PRODUCT_BOARDS.map((config) => <ProductTable key={config.key} config={config} rows={rows} />)}
 </section>

 <TrackMap rows={rows} />
 </section>

 <Podium rows={rows} />

 <footer className="sketch-news-bar sketch-applied-news-bar">
          <div className="sketch-news-label"><Radio size={14} /> APPLICANTS</div>
          <div className="sketch-news-track">
            <span>Applicant count by LC | {applicantPromoText} |</span>
          </div>
        </footer>
 </div>
 </main>
 );
}

