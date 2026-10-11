"use strict";
// Server-side score calculation. Never trust points, time or hint counters from an iOS client.
const MODE_IDS = Object.freeze(["classic", "expert", "impossible", "daily", "marathon"]);
const PUBLIC_BOARD_NAMES = Object.freeze(["global", "expert", "impossible", "daily", "marathon"]);
function periodKey(kind, now = Date.now()) {
  const d = new Date(now);
  if (kind === "weekly") return `weekly_${Math.floor((now / 1000 + 3 * 86400) / (7 * 86400))}`;
  if (kind === "monthly") return `monthly_${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}`;
  throw new Error("Invalid period");
}
function boardsFor({ mode, levelId, country }, now = Date.now()) {
  if (!MODE_IDS.includes(mode)) throw new Error("Unknown game mode");
  const boards = ["global", periodKey("weekly", now), periodKey("monthly", now)];
  if (mode !== "classic") boards.push(mode);
  if (Number.isInteger(levelId) && levelId >= 1 && levelId <= 100) boards.push(`case_${String(levelId).padStart(3, "0")}`);
  if (/^[A-Z]{2}$/.test(country || "")) boards.push(`country_${country}`);
  return boards;
}
function serverScore({ chapter = 0, durationSeconds, mistakes = 0, hints = 0, mode = "classic", overtime = false }) {
  if (!MODE_IDS.includes(mode)) throw new Error("Invalid mode");
  if (![chapter, durationSeconds, mistakes, hints].every(x => Number.isFinite(x) && x >= 0)) throw new Error("Bad numeric fields");
  if (durationSeconds < 1 || durationSeconds > 7200 || mistakes > 999 || hints > 99) throw new Error("Out of bounds");
  let score = Math.max(250, 2500 + Math.floor(chapter) * 350 - Math.floor(durationSeconds) * 4 - Math.floor(mistakes) * 95 - Math.floor(hints) * 300);
  if (mode === "impossible" && overtime) score = Math.max(100, Math.round(score * 0.55));
  return score;
}
function answersEqual(expected, given) {
  if (Array.isArray(expected)) return Array.isArray(given) && expected.length === given.length && expected.every((x, i) => answersEqual(x, given[i]));
  return String(expected).trim().normalize("NFKC").toLocaleUpperCase("fr-FR") === String(given ?? "").trim().normalize("NFKC").toLocaleUpperCase("fr-FR");
}
function expectedStageAnswer(stage, language = "fr") {
  if (stage.type === "hangman") return stage[language === "en" ? "answer_en" : "answer_fr"];
  return stage.answer;
}
module.exports = { MODE_IDS, PUBLIC_BOARD_NAMES, periodKey, boardsFor, serverScore, answersEqual, expectedStageAnswer };
