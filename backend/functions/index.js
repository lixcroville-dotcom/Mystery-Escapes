"use strict";
/** Deploy only after enabling Blaze, binding App Check and reviewing security / privacy. */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const crypto = require("crypto");
const levels = require("./levels_ranked.json");
const { MODE_IDS, boardsFor, serverScore, answersEqual, expectedStageAnswer } = require("./scoring");
admin.initializeApp();
const db = admin.firestore();
const REGION = "europe-west3";
const settings = { region: REGION, maxInstances: 6, enforceAppCheck: false }; // true before public launch!
const authUid = (request) => {
  if (!request.auth?.uid) throw new HttpsError("unauthenticated", "Connexion Firebase requise");
  return request.auth.uid;
};
const cleanName = (raw) => String(raw || "Détective").replace(/[<>\r\n]/g, "").trim().slice(0, 20) || "Détective";
const validCountry = (raw) => /^[A-Z]{2}$/.test(String(raw || "")) ? String(raw) : "";
const runDoc = (uid) => db.collection("private_ranked_runs").doc(uid);
const levelFor = (levelId) => levels.find(x => Number(x.id) === Number(levelId));

exports.setPublicRankProfile = onCall(settings, async (request) => {
  const uid = authUid(request);
  const display_name = cleanName(request.data?.display_name);
  const country = validCountry(request.data?.country);
  const visible = request.data?.visible === true;
  await db.collection("rank_profiles").doc(uid).set({ display_name, country, visible, updated_at: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
  return { ok: true, display_name, country, visible };
});

exports.startRankedRun = onCall(settings, async (request) => {
  const uid = authUid(request);
  const mode = String(request.data?.mode || "classic");
  const levelId = Number(request.data?.level_id);
  if (!MODE_IDS.includes(mode) || !Number.isInteger(levelId) || !levelFor(levelId)) throw new HttpsError("invalid-argument", "Mode ou dossier incorrect");
  if (mode === "impossible" && ![121, 122, 123].includes(levelId)) throw new HttpsError("invalid-argument", "Dossier Impossible non reconnu");
  if (mode !== "impossible" && (levelId < 1 || levelId > 100)) throw new HttpsError("invalid-argument", "Dossier classé indisponible");
  const runId = crypto.randomUUID();
  const startedMs = Date.now();
  // Atomic single active run and anti-request-spam: at least 5 s between starts.
  await db.runTransaction(async tx => {
    const ref = runDoc(uid);
    const prev = await tx.get(ref);
    if (prev.exists && startedMs - Number(prev.data().startedMs || 0) < 5000) throw new HttpsError("resource-exhausted", "Patiente avant de relancer un dossier");
    tx.set(ref, { uid, runId, mode, levelId, stage: 0, startedMs, lastStepMs: startedMs, mistakes: 0, hints: 0, hintedStage: -1, hintForStage: 0, finished: false, expiresMs: startedMs + 2 * 3600_000 });
  });
  return { run_id: runId, level_id: levelId, stage: 0, expires_at: startedMs + 2 * 3600_000 };
});

exports.requestRankedHint = onCall(settings, async (request) => {
  const uid = authUid(request);
  const runId = String(request.data?.run_id || "");
  return db.runTransaction(async tx => {
    const ref = runDoc(uid), snap = await tx.get(ref), r = snap.data();
    if (!r || r.runId !== runId || r.finished || Date.now() > r.expiresMs) throw new HttpsError("failed-precondition", "Partie classée expirée");
    const stage = levelFor(r.levelId).stages[r.stage];
    if (!stage) throw new HttpsError("failed-precondition", "Plus d'étape");
    if (r.hintedStage === r.stage && r.hintForStage >= 2) throw new HttpsError("resource-exhausted", "Limite d'indices atteinte");
    tx.update(ref, { hints: r.hints + 1, hintedStage: r.stage, hintForStage: r.hintedStage === r.stage ? r.hintForStage + 1 : 1 });
    return { hint: String(stage.hint_fr || "Observez les détails.") };
  });
});

exports.submitRankedStage = onCall(settings, async (request) => {
  const uid = authUid(request);
  const runId = String(request.data?.run_id || "");
  const submitted = request.data?.answer;
  const now = Date.now();
  const result = await db.runTransaction(async tx => {
    const ref = runDoc(uid), snap = await tx.get(ref), r = snap.data();
    if (!r || r.runId !== runId || r.finished || now > r.expiresMs) throw new HttpsError("failed-precondition", "Partie classée expirée ou rejouée");
    // Minimal time requirement reduces automated floods but does NOT prevent a motivated cheater.
    if (now - r.lastStepMs < 1500) throw new HttpsError("resource-exhausted", "Résolution trop rapide");
    const level = levelFor(r.levelId), stage = level.stages[r.stage];
    if (!stage) throw new HttpsError("failed-precondition", "Étape inexistante");
    if (!answersEqual(expectedStageAnswer(stage, String(request.data?.language || "fr")), submitted)) {
      tx.update(ref, { mistakes: r.mistakes + 1 });
      return { ok: false, stage: r.stage };
    }
    const next = r.stage + 1;
    if (next < level.stages.length) {
      tx.update(ref, { stage: next, lastStepMs: now, hintForStage: 0, hintedStage: -1 });
      return { ok: true, finished: false, next_stage: next };
    }
    const duration = (now - r.startedMs) / 1000;
    const score = serverScore({ chapter: Number(level.chapter || 0), durationSeconds: duration, mistakes: r.mistakes, hints: r.hints, mode: r.mode, overtime: r.mode === "impossible" && duration > 900 });
    // Publish atomically with completion: a network error cannot lose a score after
    // the run is marked finished. Firestore transactions re-run if a score changes.
    const profileSnap = await tx.get(db.collection("rank_profiles").doc(uid));
    const profile = profileSnap.data() || {};
    if (profile.visible === true) {
      const boards = boardsFor({ mode: r.mode, levelId: r.levelId, country: validCountry(profile.country) }, now);
      const refs = boards.map(board => db.collection("public_leaderboards").doc(board).collection("entries").doc(uid));
      const previous = [];
      for (const boardRef of refs) previous.push(await tx.get(boardRef));
      for (let i = 0; i < refs.length; i++) {
        if (!previous[i].exists || Number(previous[i].data().score || 0) < score) {
          tx.set(refs[i], { display_name: cleanName(profile.display_name), score, mode: r.mode, level_id: r.levelId, verified_at: admin.firestore.FieldValue.serverTimestamp() });
        }
      }
    }
    tx.update(ref, { finished: true, finishedMs: now, score });
    return { ok: true, finished: true, score, mode: r.mode, levelId: r.levelId, playedAt: now };
  });
  return result;
});
