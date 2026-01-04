const GameLimits = {
  MIN_PLAYERS: 2,
  MAX_PLAYERS: 6,
};

// === STATE MANAGEMENT ===
const State = {
  game: {
    players: [],
    rounds: [],
    currIdx: 0,
    editingIdx: null,
    locked: false,
    started: false,
    tileDetails: {},
    roundWinners: {},
  },
  timer: { d: 120, c: 120, r: false, i: null, s: true },

  init() {
    const sGame = localStorage.getItem("rummi_v7_game");
    if (sGame) this.game = JSON.parse(sGame);
    // Ensure valid state
    if (typeof this.game.currIdx === "undefined") this.game.currIdx = 0;
    if (typeof this.game.editingIdx === "undefined") this.game.editingIdx = null;
    if (typeof this.game.locked === "undefined") this.game.locked = false;
    if (
      typeof this.game.tileDetails === "undefined" ||
      this.game.tileDetails === null ||
      typeof this.game.tileDetails !== "object" ||
      Array.isArray(this.game.tileDetails)
    ) {
      this.game.tileDetails = {};
    }
    if (
      typeof this.game.roundWinners === "undefined" ||
      this.game.roundWinners === null ||
      typeof this.game.roundWinners !== "object" ||
      Array.isArray(this.game.roundWinners)
    ) {
      this.game.roundWinners = {};
    }
    if (typeof this.game.started === "undefined") {
      const inferredStarted =
        this.game.locked === true ||
        (Array.isArray(this.game.rounds) &&
          this.game.rounds.length > 0 &&
          (this.game.currIdx > 0 ||
            this.game.rounds[0].some(
              (val) => val !== "" && val !== null
            )));
      this.game.started = inferredStarted;
      if (inferredStarted) this.game.locked = true;
    }

    const sTimer = localStorage.getItem("rummi_v7_timer");
    if (sTimer) {
      const p = JSON.parse(sTimer);
      const rawSeconds = typeof p.d === "number" ? p.d : 120;
      const minutes = Math.round(rawSeconds / 60);
      const clampedMinutes = Math.min(59, Math.max(2, minutes || 2));
      this.timer.d = clampedMinutes * 60;
      this.timer.s = p.s !== false;
      this.timer.c = this.timer.d;
    } else {
      this.timer.d = 120;
      this.timer.c = 120;
    }

    // Defaults relacionados à rotação e regras de tempo
    if (typeof this.game.turnIdx === 'undefined') this.game.turnIdx = 0;
    if (typeof this.game.timeRule === 'undefined') {
      const minutes = Math.round(this.timer.d / 60);
      this.game.timeRule = minutes === 1 ? 'official' : minutes === 2 ? 'alternative' : 'custom';
    }
    if (typeof this.game.turnAutoRotate === 'undefined') this.game.turnAutoRotate = true;
    if (typeof this.game.confirmExpiry === 'undefined') this.game.confirmExpiry = false;
    if (typeof this.game.roundPenalties === 'undefined' || this.game.roundPenalties === null || typeof this.game.roundPenalties !== 'object') this.game.roundPenalties = {};
    if (!Array.isArray(this.game.events)) this.game.events = []; // registro de eventos (persistido)
    if (typeof this.game.turnHistory === 'undefined' || this.game.turnHistory === null || typeof this.game.turnHistory !== 'object') this.game.turnHistory = {}; // { roundIdx: { playerIdx: [ {start,end,duration, penaltyApplied, penaltyConfirmed, reason} ] } }
  },
  save() {
    localStorage.setItem("rummi_v7_game", JSON.stringify(this.game));
  },
  saveTimer() {
    localStorage.setItem(
      "rummi_v7_timer",
      JSON.stringify({ d: this.timer.d, s: this.timer.s })
    );
  },

  isGameStarted() {
    return this.game.started === true;
  },

  startGame() {
    if (this.game.started === true) return;
    this.game.started = true;
    this.game.locked = true;
    this.save();
  },
};

// === UI STATE (não persistido) ===
const UI = {
  editingPlayerIdx: null,
  leaderboardExpanded: false,
  leaderboardOpen: false,
};

// === SOUND ENGINE ===
const Sound = {
  ctx: null,
  init() {
    if (!this.ctx)
      this.ctx = new (window.AudioContext || window.webkitAudioContext)();
    if (this.ctx.state === "suspended") this.ctx.resume();
  },
  play(f, t, d) {
    this.init();
    const o = this.ctx.createOscillator(),
      g = this.ctx.createGain();
    o.type = t;
    o.frequency.value = f;
    g.gain.setValueAtTime(0.2, this.ctx.currentTime);
    g.gain.linearRampToValueAtTime(0, this.ctx.currentTime + d);
    o.connect(g);
    g.connect(this.ctx.destination);
    o.start();
    o.stop(this.ctx.currentTime + d);
  },
  tick: () => Sound.play(800, "sine", 0.1),
  alarm: () => {
    Sound.init();
    [0, 0.2, 0.4].forEach((t) =>
      setTimeout(() => Sound.play(880, "square", 0.1), t * 1000)
    );
  },
};

// === TIMER LOGIC ===
// helper: formato curto para nomes no temporizador
function formatPlayerShort(n, max = 12) {
  if (!n) return "";
  return n.length > max ? n.substring(0, max - 1) + "…" : n;
}

const Timer = {
  updateUI() {
    const m = Math.floor(State.timer.c / 60)
        .toString()
        .padStart(2, "0"),
      s = (State.timer.c % 60).toString().padStart(2, "0");
    const display = document.getElementById("timerDisplay");
    if (display) display.innerText = `${m}:${s}`;

    // Atualiza nome do jogador atual no cabeçalho do timer
    const curIdx = typeof State.game.turnIdx === "number" ? State.game.turnIdx : 0;
    const curNameFull = State.game.players[curIdx] || "";
    const curEl = document.getElementById("currentPlayerName");
    if (curEl) {
      curEl.innerText = formatPlayerShort(curNameFull, 12);
      curEl.title = curNameFull;
    }

    const pct = State.timer.d > 0 ? (State.timer.c / State.timer.d) * 100 : 100;
    const progEl = document.getElementById("timerProgress");
    if (progEl) progEl.style.width = `${pct}%`;

    const c = document.getElementById("timerContainer"),
      b = document.getElementById("timerProgress");
    if (State.timer.r && State.timer.c <= 15) {
      c.classList.add("timer-critical");
      b.classList.replace("bg-orange-500", "bg-red-600");
    } else {
      c.classList.remove("timer-critical");
      b.classList.replace("bg-red-600", "bg-orange-500");
    }
  },
  start() {
    const p = document.getElementById("iconPlay"),
      z = document.getElementById("iconPause"),
      b = document.getElementById("btnToggleTimer");
    Sound.init();
    if (State.timer.d === 0) return; // Sem limite
    if (State.timer.c <= 0) State.timer.c = State.timer.d;
    State.timer.r = true;
    p.classList.add("hidden");
    z.classList.remove("hidden");
    b.classList.replace("bg-orange-600", "bg-slate-800");
    State.timer.i = setInterval(() => {
      State.timer.c--;
      Timer.updateUI();
      if (State.timer.s && State.timer.c <= 10 && State.timer.c > 0)
        State.timer.c % 2 === 0 ? Sound.tick() : null;
      if (State.timer.c <= 0) {
        Timer.reset();
        if (State.timer.s) Sound.alarm();
        Timer.handleExpiry();
      }
    }, 1000);
  },
  stop() {
    const p = document.getElementById("iconPlay"),
      z = document.getElementById("iconPause"),
      b = document.getElementById("btnToggleTimer");
    State.timer.r = false;
    clearInterval(State.timer.i);
    p.classList.remove("hidden");
    z.classList.add("hidden");
    b.classList.replace("bg-slate-800", "bg-orange-600");
    document
      .getElementById("timerContainer")
      .classList.remove("timer-critical");
  },
  toggle() {
    if (State.timer.r) Timer.stop();
    else Timer.start();
  },
  handleExpiry() {
    const pIdx = typeof State.game.turnIdx === 'number' ? State.game.turnIdx : 0;
    const name = State.game.players[pIdx] || `Jogador ${pIdx + 1}`;
    const rule = State.game.timeRule || 'official';

    let draws = 1;
    if (rule === 'official') draws = 3;
    else if (rule === 'alternative') draws = 1;
    else if (rule === 'impatient') draws = 1;

    const ruleLabel = rule === 'official' ? 'Oficial' : rule === 'alternative' ? 'Alternativa' : rule === 'impatient' ? 'Variação' : 'Personalizado';

    const applyExpiry = () => {
      // Registrar penalidade
      if (!State.game.roundPenalties) State.game.roundPenalties = {};
      const rIdx = activeRoundIdx;
      if (!State.game.roundPenalties[rIdx]) State.game.roundPenalties[rIdx] = {};
      State.game.roundPenalties[rIdx][pIdx] = (State.game.roundPenalties[rIdx][pIdx] || 0) + draws;

      // Reverter quaisquer peças registradas para essa rodada/jogador (se houver)
      const activeRoundIdx =
        State.game.editingIdx !== null && typeof State.game.editingIdx === 'number'
          ? State.game.editingIdx
          : State.game.currIdx;
      const key = `${activeRoundIdx}-${pIdx}`;
      let reverted = false;
      if (State.game.tileDetails && State.game.tileDetails[key]) {
        delete State.game.tileDetails[key];
        reverted = true;
      }

      // Persistir e atualizar UI
      State.save();
      Render.playersManager();

      const nextIdx = (pIdx + 1) % (State.game.players.length || 1);
      const nextName = State.game.players[nextIdx] || `Jogador ${nextIdx + 1}`;

      // Mensagem curta para o toast
      const toastMsg = `${name} estourou o tempo (${ruleLabel}). Penalidade: +${draws} peça(s). ${reverted ? 'Peças devolvidas.' : 'Sem peças registradas.'} Próximo: ${nextName}.`;
      showToast(toastMsg);

      // Registrar evento com referência a rodada
      showEvent(`[Rodada ${activeRoundIdx + 1}] ${toastMsg}`);

      // Avança para próximo jogador
      Actions.rotateToNextPlayer();

      // Reinicia automaticamente se configurado
      if (State.game.turnAutoRotate) {
        State.timer.c = State.timer.d;
        Timer.start();
      }
    };

    if (State.game.confirmExpiry) {
      const msg = `${name} estourou o tempo (${ruleLabel}). Ao confirmar, as peças jogadas (se registradas) serão devolvidas e o jogador comprará ${draws} peça(s).`;
      showConfirm('Tempo Expirado', msg, applyExpiry);
      return;
    }

    // Aplica automaticamente
    applyExpiry();
  },
  reset() {
    State.timer.r = false;
    clearInterval(State.timer.i);
    State.timer.c = State.timer.d;
    Timer.updateUI();
    document.getElementById("iconPlay").classList.remove("hidden");
    document.getElementById("iconPause").classList.add("hidden");
    document
      .getElementById("btnToggleTimer")
      .classList.replace("bg-slate-800", "bg-orange-600");
    document
      .getElementById("timerContainer")
      .classList.remove("timer-critical");
  },
};

// === ACTIONS & UTILS ===
const TileCalc = {
  target: null,
  pendingWinner: null,
  roundWinnerAtOpen: null,
  counts: new Array(14).fill(0),
  values: (() => {
    const arr = [];
    for (let i = 1; i <= 13; i++) arr.push(i);
    arr.push(30); // curinga
    return arr;
  })(),

  open(rIdx, pIdx) {
    this.target = { rIdx, pIdx };

    const w = State.game.roundWinners ? State.game.roundWinners[rIdx] : null;
    this.roundWinnerAtOpen = typeof w === "number" ? w : null;
    this.pendingWinner = this.roundWinnerAtOpen === pIdx;

    const key = `${rIdx}-${pIdx}`;
    const saved = State.game.tileDetails ? State.game.tileDetails[key] : null;
    if (Array.isArray(saved) && saved.length === 14) {
      this.counts = saved.map((n) => (typeof n === "number" ? n : 0));
    } else {
      this.counts = new Array(14).fill(0);
    }
    this.render();
    for (let i = 0; i < 14; i++) this.updateTileCount(i);
    this.updateTotal();
    this.updateHeader();
    document.getElementById("tileCalcModal").classList.remove("hidden");
    if (document.activeElement && document.activeElement.blur)
      document.activeElement.blur();
  },

  close() {
    document.getElementById("tileCalcModal").classList.add("hidden");
    this.target = null;
    this.pendingWinner = null;
    this.roundWinnerAtOpen = null;
  },

  isWinnerTarget() {
    if (!this.target) return false;
    if (typeof this.pendingWinner === "boolean") return this.pendingWinner;
    const { rIdx, pIdx } = this.target;
    const w = State.game.roundWinners ? State.game.roundWinners[rIdx] : null;
    return typeof w === "number" && w === pIdx;
  },

  updateHeader() {
    if (!this.target) return;
    const { rIdx, pIdx } = this.target;

    const titleEl = document.getElementById("tileCalcTitle");
    if (titleEl) titleEl.textContent = `Resultado da rodada ${rIdx + 1}`;

    const subtitleEl = document.getElementById("tileCalcSubtitle");
    if (subtitleEl) subtitleEl.textContent = State.game.players[pIdx] || "";

    const winnerBtn = document.getElementById("tileCalcWinnerBtn");
    const isWinner = this.isWinnerTarget();
    if (winnerBtn) {
      winnerBtn.className =
        "p-2 rounded-xl border active:scale-95 transition-all " +
        (isWinner
          ? "border-yellow-300 bg-yellow-100 text-yellow-800"
          : "border-yellow-200 text-slate-600 hover:text-yellow-900 hover:bg-yellow-50");
      winnerBtn.title = isWinner ? "Vencedor" : "Marcar como vencedor";
      winnerBtn.setAttribute(
        "aria-label",
        isWinner ? "Vencedor" : "Marcar como vencedor"
      );

      // Mostrar/ocultar rótulo textual ao lado do ícone
      const lbl = winnerBtn.querySelector('#tileCalcWinnerLabel');
      if (lbl) lbl.classList.toggle('hidden', !isWinner);
    } // end winnerBtn

    const notice = document.getElementById("tileCalcWinnerNotice");
    if (notice) notice.classList.toggle("hidden", !isWinner);

    const totalLabel = document.getElementById("tileCalcTotalLabel");
    if (totalLabel) totalLabel.textContent = isWinner ? "Vencedor" : "Total";

    const totalDesc = document.getElementById("tileCalcTotalDesc");
    if (totalDesc)
      totalDesc.textContent = isWinner
        ? "Pontuação automática"
        : "Lançado negativo";

    const grid = document.getElementById("tileCalcGrid");
    if (grid) {
      grid.parentElement.classList.toggle("hidden", isWinner);
    }

    this.updateApplyBtnStyle();
  },

  updateApplyBtnStyle() {
    const applyBtn = document.getElementById("tileCalcApplyBtn");
    if (!applyBtn) return;

    applyBtn.disabled = false;
    const anySelected = Array.isArray(this.counts)
      ? this.counts.some((n) => (n || 0) > 0)
      : false;

    const winnerSelected = this.isWinnerTarget();

    applyBtn.className =
      "flex-1 py-3 rounded-xl shadow-lg inline-flex items-center justify-center gap-2 font-black " +
      (anySelected || winnerSelected
        ? "bg-orange-500 text-white hover:bg-orange-600"
        : "bg-slate-100 text-slate-700 hover:bg-slate-200");
  },

  toggleWinner() {
    if (!this.target) return;
    this.pendingWinner = !this.isWinnerTarget();
    this.updateHeader();
  },

  inc(i) {
    if (typeof this.counts[i] !== "number") this.counts[i] = 0;
    this.counts[i] = Math.min(99, this.counts[i] + 1);
    this.updateTileCount(i);
    this.updateTotal();
  },

  dec(i) {
    if (typeof this.counts[i] !== "number") this.counts[i] = 0;
    this.counts[i] = Math.max(0, this.counts[i] - 1);
    this.updateTileCount(i);
    this.updateTotal();
  },

  sum() {
    let s = 0;
    for (let i = 0; i < this.counts.length; i++) {
      const c = this.counts[i] || 0;
      s += c * this.values[i];
    }
    return s;
  },

  total() {
    const s = this.sum();
    return -s;
  },

  updateTotal() {
    const el = document.getElementById("tileCalcTotal");
    if (!el) return;
    if (this.isWinnerTarget()) {
      el.textContent = "Auto";
      el.className = "text-2xl font-black tabular-nums text-yellow-800";
      this.updateApplyBtnStyle();
      return;
    }

    const total = this.total();
    el.textContent = total > 0 ? `+${total}` : `${total}`;
    el.className =
      "text-2xl font-black tabular-nums " +
      (total < 0
        ? "text-rose-600"
        : total > 0
        ? "text-emerald-600"
        : "text-slate-600");

    this.updateApplyBtnStyle();
  },

  updateTileCount(i) {
    const el = document.getElementById(`tileCount-${i}`);
    if (!el) return;
    const count = this.counts[i] || 0;
    el.textContent = count;

    const isJoker = i === 13;
    const selected = count > 0;

    const card = document.getElementById(`tileCard-${i}`);
    if (card) {
      card.className =
        "rounded-2xl border bg-white p-2 transition-colors " +
        (selected ? "border-orange-200" : "border-slate-200");
    }

    const label = document.getElementById(`tileLabel-${i}`);
    if (label) {
      label.className =
        "w-8 h-8 rounded-xl flex items-center justify-center transition-colors " +
        (selected
          ? "bg-orange-500 text-white"
          : "bg-slate-100 text-slate-800") +
        (isJoker ? "" : " font-black");
    }

    const badge = document.getElementById(`tileBadge-${i}`);
    if (badge) {
      badge.className =
        "inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-black shrink-0 transition-colors " +
        (count > 0
          ? "bg-orange-100 text-orange-800"
          : "bg-slate-100 text-slate-700");
    }

    const decBtn = document.getElementById(`tileDec-${i}`);
    if (decBtn) {
      decBtn.className =
        "flex-1 h-9 rounded-xl font-black active:scale-95 transition-colors " +
        (selected
          ? "bg-rose-100 text-rose-700 hover:bg-rose-200"
          : "bg-slate-100 text-slate-700 hover:bg-slate-200");
    }

    const incBtn = document.getElementById(`tileInc-${i}`);
    if (incBtn) {
      incBtn.className =
        "flex-1 h-9 rounded-xl font-black active:scale-95 transition-colors " +
        (selected
          ? "bg-orange-500 text-white hover:bg-orange-600"
          : "bg-slate-100 text-slate-700 hover:bg-slate-200");
    }
  },

  render() {
    const grid = document.getElementById("tileCalcGrid");
    if (!grid) return;
    const jokerSvg = `...`;

    let html = "";
    for (let i = 0; i < 14; i++) {
      const isJoker = i === 13;
      const label = isJoker
        ? `<div class="flex items-center gap-2 min-w-0">
            <div id="tileLabel-${i}" class="w-8 h-8 rounded-xl bg-slate-100 text-slate-800 flex items-center justify-center transition-colors">
              ${jokerSvg}
            </div>
            <span class="font-black text-slate-800 text-sm truncate">Curinga</span>
          </div>`
        : `<div id="tileLabel-${i}" class="w-8 h-8 rounded-xl bg-slate-100 text-slate-800 flex items-center justify-center font-black transition-colors">${i + 1}</div>`;
      const sub = isJoker
        ? `<div class="text-[11px] font-bold text-slate-500">30 pts</div>`
        : `<div class="text-[11px] font-bold text-slate-500">${i + 1} pt${i + 1 === 1 ? "" : "s"}</div>`;

      html += `...`;
    }

    grid.innerHTML = html;

    try {
      const walker = document.createTreeWalker(grid, NodeFilter.SHOW_TEXT, null, false);
      const toRemove = [];
      while (walker.nextNode()) {
        const t = walker.currentNode;
        if (t && typeof t.textContent === 'string' && /id="/.test(t.textContent)) {
          toRemove.push(t);
        }
      }
      toRemove.forEach(n => n.parentNode && n.parentNode.removeChild(n));
      if (toRemove.length) console.warn('Removed', toRemove.length, 'stray text nodes from tileCalcGrid');
    } catch (e) {
      console.warn('Error cleaning tileCalcGrid text nodes', e);
    }
  },

  apply() {
    if (!this.target) return;
    const { rIdx, pIdx } = this.target;

    const input = document.getElementById(`cell-${rIdx}-${pIdx}`);
    if (!input) {
      this.close();
      return;
    }

    const currentWinner =
      State.game.roundWinners && typeof State.game.roundWinners[rIdx] === "number"
        ? State.game.roundWinners[rIdx]
        : null;

    // Se o usuário marcou como vencedor, só salva o vencedor ao clicar em Aplicar.
    if (this.isWinnerTarget()) {
      if (!State.game.roundWinners) State.game.roundWinners = {};

      if (typeof currentWinner === "number" && currentWinner !== pIdx) {
        const oldInput = document.getElementById(`cell-${rIdx}-${currentWinner}`);
        if (oldInput) {
          oldInput.value = "";
          Actions.applyScoreValue(rIdx, currentWinner, oldInput, "", {
            skipRecalc: true,
          });
        } else {
          State.game.rounds[rIdx][currentWinner] = "";
        }
      }

      State.game.roundWinners[rIdx] = pIdx;

      // Limpa pontuação/detalhes do vencedor para evitar valores antigos.
      input.value = "0";
      Actions.applyScoreValue(rIdx, pIdx, input, "0", {
        skipRecalc: true,
      });

      State.save();
      Actions.recalculateWinnerForRound(rIdx);
      Render.totals();
      Render.leaderboard();
      this.close();
      return;
    }

    // Se antes era vencedor e agora desmarcou, remove o vencedor ao clicar em Aplicar.
    if (currentWinner === pIdx) {
      delete State.game.roundWinners[rIdx];
      input.value = "";
      Actions.applyScoreValue(rIdx, pIdx, input, "", {
        skipRecalc: true,
      });
    }

    const total = this.total();
    const val = total.toString();
    input.value = val;
    Actions.applyScoreValue(rIdx, pIdx, input, val, {
      tileCounts: this.counts.slice(0, 14),
    });
    this.close();
  },
};

const Actions = {
  movePlayerUp(pIdx) {
    this.movePlayer(pIdx, -1);
  },

  movePlayerDown(pIdx) {
    this.movePlayer(pIdx, 1);
  },

  movePlayer(pIdx, delta) {
    if (State.isGameStarted()) {
      showError(
        "A partida já começou. Para reordenar jogadores, reinicie o jogo."
      );
      return;
    }

    if (!Array.isArray(State.game.players)) return;
    const from = Number(pIdx);
    if (!Number.isInteger(from)) return;

    const to = from + Number(delta);
    if (!Number.isInteger(to)) return;
    if (to < 0 || to >= State.game.players.length) return;
    if (from === to) return;

    // Troca na lista de jogadores
    const tmpName = State.game.players[from];
    State.game.players[from] = State.game.players[to];
    State.game.players[to] = tmpName;

    // Troca na matriz de rodadas (colunas)
    if (Array.isArray(State.game.rounds)) {
      State.game.rounds.forEach((row) => {
        if (!Array.isArray(row)) return;
        const tmp = row[from];
        row[from] = row[to];
        row[to] = tmp;
      });
    }

    // Troca detalhes de pedras por célula
    if (State.game.tileDetails && typeof State.game.tileDetails === "object") {
      const td = State.game.tileDetails;
      const roundsLen = Array.isArray(State.game.rounds)
        ? State.game.rounds.length
        : 0;
      for (let r = 0; r < roundsLen; r++) {
        const k1 = `${r}-${from}`;
        const k2 = `${r}-${to}`;
        const v1 = td[k1];
        const v2 = td[k2];

        if (typeof v1 === "undefined" && typeof v2 === "undefined") continue;
        if (typeof v2 === "undefined") {
          delete td[k1];
          td[k2] = v1;
          continue;
        }
        if (typeof v1 === "undefined") {
          delete td[k2];
          td[k1] = v2;
          continue;
        }

        td[k1] = v2;
        td[k2] = v1;
      }
    }

    // Ajusta vencedores por rodada (índices)
    if (State.game.roundWinners && typeof State.game.roundWinners === "object") {
      const rw = State.game.roundWinners;
      Object.keys(rw).forEach((rk) => {
        const w = rw[rk];
        if (w === from) rw[rk] = to;
        else if (w === to) rw[rk] = from;
      });
    }

    // Mantém consistência do estado de edição de jogador
    if (typeof UI.editingPlayerIdx === "number") {
      if (UI.editingPlayerIdx === from) UI.editingPlayerIdx = to;
      else if (UI.editingPlayerIdx === to) UI.editingPlayerIdx = from;
    }

    State.save();
    Render.all();
  },

  addPlayerFrom(inputId) {
    const inp = document.getElementById(inputId);
    if (!inp) return;

    if (State.game.locked === true) {
      showError(
        "O jogo já começou. Não é possível adicionar participantes agora."
      );
      return;
    }

    if (State.game.players.length >= GameLimits.MAX_PLAYERS) {
      showError(
        `Limite de ${GameLimits.MAX_PLAYERS} jogadores atingido.`
      );
      return;
    }

    const name = inp.value.trim();
    if (!name) return;

    const MAX_NAME_LENGTH = 20;
    const safeName = name.length > MAX_NAME_LENGTH ? name.substring(0, MAX_NAME_LENGTH) : name;

    State.game.players.push(safeName);
    // Expandir matriz
    State.game.rounds.forEach((r) => r.push(""));
    // Garantir rodadas = jogadores
    while (State.game.rounds.length < State.game.players.length) {
      State.game.rounds.push(
        new Array(State.game.players.length).fill("")
      );
    }

    inp.value = "";
    State.save();
    Render.all();
  },

  handleEnterFrom(e, inputId) {
    if (e.key === "Enter") this.addPlayerFrom(inputId);
  },

  toggleTimer() {
    // Pausar não precisa de confirmação
    if (State.timer.r) {
      Timer.toggle();
      return;
    }

    // Se ainda não iniciou a 1ª rodada, confirmar o início antes de começar o timer
    const canStart =
      !State.isGameStarted() &&
      State.game.players.length > 0 &&
      State.game.currIdx === 0 &&
      State.game.editingIdx === null;

    if (canStart) {
      showConfirm(
        "Iniciar a 1ª rodada?",
        "Ao iniciar, não será mais possível adicionar participantes e os campos serão liberados.",
        () => {
          State.startGame();
          Render.updateAddPlayerState();
          Timer.toggle();
        }
      );
      return;
    }

    Timer.toggle();
  },

  startFirstRound() {
    if (State.isGameStarted()) return;
    if (State.game.players.length < GameLimits.MIN_PLAYERS) {
      showError(
        `Adicione pelo menos ${GameLimits.MIN_PLAYERS} jogadores para iniciar.`
      );
      return;
    }
    showConfirm(
      "Iniciar a 1ª rodada?",
      "Ao iniciar, não será mais possível adicionar participantes e os campos serão liberados.",
      () => {
        State.startGame();
        Render.all();
      }
    );
  },

  beginEditPlayer(pIdx) {
    UI.editingPlayerIdx = pIdx;
    Render.playersManager();
  },

  cancelEditPlayer() {
    UI.editingPlayerIdx = null;
    Render.playersManager();
  },

  savePlayerName(pIdx) {
    const el = document.getElementById(`playerNameInput-${pIdx}`);
    if (!el) return;

    const nextName = el.value.trim();
    const prevName = (State.game.players[pIdx] || "").trim();

    if (!nextName) {
      showError("O nome não pode ficar vazio.");
      el.value = prevName;
      return;
    }

    if (nextName === prevName) {
      UI.editingPlayerIdx = null;
      Render.playersManager();
      return;
    }

    showConfirm(
      "Trocar nome do jogador?",
      `De: ${prevName}\nPara: ${nextName}`,
      () => {
        State.game.players[pIdx] = nextName;
        State.save();
        UI.editingPlayerIdx = null;
        Render.all();
      }
    );
  },

  removePlayer(pIdx) {
    const name = State.game.players[pIdx];
    if (!name) return;

    if (State.isGameStarted()) {
      showError(
        "A partida já começou. Para remover jogadores, reinicie o jogo."
      );
      return;
    }

    if (State.game.players.length <= GameLimits.MIN_PLAYERS) {
      showError(
        `Mínimo de ${GameLimits.MIN_PLAYERS} jogadores. Para remover mais, reinicie o jogo.`
      );
      return;
    }

    showConfirm(
      "Remover jogador?",
      `Remover ${name}? Isso também ajusta a tabela de rodadas.`,
      () => {
        State.game.players.splice(pIdx, 1);

        // Remove a coluna do jogador em todas as rodadas
        State.game.rounds.forEach((row) => {
          if (Array.isArray(row)) row.splice(pIdx, 1);
        });

        // Garante que o número de rodadas não exceda nº de jogadores
        while (State.game.rounds.length > State.game.players.length) {
          State.game.rounds.pop();
        }

        // Garante linhas com tamanho correto
        State.game.rounds.forEach((row) => {
          if (!Array.isArray(row)) return;
          row.length = State.game.players.length;
        });

        UI.editingPlayerIdx = null;
        State.save();
        Render.all();
      }
    );
  },

  addPlayer() {
    this.addPlayerFrom("newPlayerName");
  },

  handleEnter(e) {
    if (e.key === "Enter") this.addPlayer();
  },

  toggleLeaderboardExpanded() {
    UI.leaderboardExpanded = !UI.leaderboardExpanded;
    Render.leaderboard();
  },

  toggleLeaderboardOpen() {
    UI.leaderboardOpen = !UI.leaderboardOpen;
    Render.leaderboard();
  },

  applyScoreValue(rIdx, pIdx, el, val, options = {}) {
    State.game.rounds[rIdx][pIdx] = val;

    const key = `${rIdx}-${pIdx}`;
    if (!State.game.tileDetails) State.game.tileDetails = {};
    if (Array.isArray(options.tileCounts) && options.tileCounts.length === 14) {
      State.game.tileDetails[key] = options.tileCounts.map((n) =>
        typeof n === "number" ? n : 0
      );
    } else {
      delete State.game.tileDetails[key];
    }

    State.save();

    const n = parseInt(val);
    el.className = el.className.replace(/text-\w+-\d+/g, "");
    if (isNaN(n)) el.classList.add("text-slate-800");
    else if (n > 0) el.classList.add("text-emerald-600");
    else if (n < 0) el.classList.add("text-rose-600");
    else {
      const w = State.game.roundWinners ? State.game.roundWinners[rIdx] : null;
      if (typeof w === "number" && w === pIdx) el.classList.add("text-emerald-600");
      else el.classList.add("text-slate-400");
    }

    // Update Totals but NOT validation dialog
    Render.totals();
    Render.leaderboard();
    Render.updateAddPlayerState();

    if (options.skipRecalc !== true) {
      this.recalculateWinnerForRound(rIdx, pIdx);
    }
  },

  recalculateWinnerForRound(rIdx, changedPIdx) {
    if (!State.game.roundWinners) return;
    const winner = State.game.roundWinners[rIdx];
    if (typeof winner !== "number") return;
    if (typeof changedPIdx === "number" && changedPIdx === winner) return;

    const round = State.game.rounds[rIdx];
    if (!Array.isArray(round)) return;

    let sumOthers = 0;
    for (let i = 0; i < round.length; i++) {
      if (i === winner) continue;
      const v = round[i];
      if (v === "" || v === null || typeof v === "undefined") continue;
      const n = parseInt(v);
      if (isNaN(n)) continue;
      sumOthers += n;
    }

    const winnerScore = (-sumOthers).toString();
    const input = document.getElementById(`cell-${rIdx}-${winner}`);
    if (input) {
      input.value = winnerScore;
      this.applyScoreValue(rIdx, winner, input, winnerScore, {
        skipRecalc: true,
      });
    } else {
      State.game.rounds[rIdx][winner] = winnerScore;
      State.save();
      Render.totals();
      Render.leaderboard();
    }
  },

  handleInput(rIdx, pIdx, el) {
    if (!State.isGameStarted() && State.game.editingIdx === null) {
      showError("Inicie a 1ª rodada para lançar os valores.");
      el.value = "";
      return;
    }

    let val = el.value;
    if (/^\d+$/.test(val)) {
      val = "-" + val;
      el.value = val;
    }

    this.applyScoreValue(rIdx, pIdx, el, val);
  },

  openTileCalc(rIdx, pIdx) {
    if (!State.isGameStarted() && State.game.editingIdx === null) {
      showError("Inicie a 1ª rodada para lançar os valores.");
      return;
    }

    const isEditingThisRound = State.game.editingIdx === rIdx;
    const isCurrentRoundUnlocked =
      State.game.editingIdx === null && State.game.currIdx === rIdx;

    if (!isEditingThisRound && !isCurrentRoundUnlocked) {
      showError(
        "Essa rodada está bloqueada. Use o ícone de edição para alterar."
      );
      return;
    }

    TileCalc.open(rIdx, pIdx);
  },

  handleSmartAction() {
    if (!State.isGameStarted()) {
      this.startFirstRound();
      return;
    }

    // Se o jogo já terminou, clicar no botão deve abrir o resultado final.
    if (
      State.game.editingIdx === null &&
      State.game.currIdx >= State.game.rounds.length
          ) {
            openGameOverModal();
            return;
          }

          if (State.game.players.length < 2)
            return alert("Adicione jogadores.");

          const targetIdx =
            State.game.editingIdx !== null
              ? State.game.editingIdx
              : State.game.currIdx;
          const round = State.game.rounds[targetIdx];

          let empty = [],
            sum = 0,
            hasErr = false,
            pos = 0,
            neg = 0;
          round.forEach((v, i) => {
            if (v === "" || v === null) empty.push(i);
            else {
              const n = parseInt(v);
              if (isNaN(n)) hasErr = true;
              else {
                sum += n;
                if (n > 0) pos += n;
                else neg += n;
              }
            }
          });

          if (hasErr) return alert("Valores inválidos.");

          // 1. Validação Manual (0 vazios)
          if (empty.length === 0) {
            if (sum !== 0) {
              showErrorDialog(sum, pos, neg);
            } else {
              if (State.game.editingIdx !== null) {
                showConfirm(
                  "Salvar Alterações?",
                  "A soma está correta (0).",
                  () => this.finishAction(targetIdx)
                );
              } else {
                showConfirm(
                  "Concluir Rodada?",
                  "A soma está correta (0).",
                  () => this.finishAction(targetIdx)
                );  
              }
            }
            return;
          }

          // 2. Auto-calc (1 vazio)
          if (empty.length === 1) {
            const winScore = sum * -1;
            const winnerName = State.game.players[empty[0]];
            // Usar o modal de vencedor melhorado para mostrar nome e pontuação
            openWinnerModal(targetIdx, empty[0], winScore);
            return;
          }

          showError(
            "Erro: Mais de um jogador vazio. Preencha todos os perdedores."
          );
        },

        finishAction(rIdx) {
          const wasEditing = State.game.editingIdx !== null;
          const wasFinished =
            State.isGameStarted() && State.game.currIdx >= State.game.rounds.length;

          if (wasEditing) {
            State.game.editingIdx = null;
          } else if (State.game.currIdx < State.game.rounds.length) {
            State.game.currIdx++;
          }

          const finishedNow =
            !wasEditing &&
            !wasFinished &&
            State.isGameStarted() &&
            State.game.currIdx >= State.game.rounds.length;

          State.save();
          Render.all();

          if (finishedNow) {
            openGameOverModal();
          }

          // Se o jogo já estava finalizado e o usuário salvou uma edição,
          // reexibe o resultado final atualizado.
          if (
            wasEditing &&
            State.isGameStarted() &&
            State.game.currIdx >= State.game.rounds.length
          ) {
            openGameOverModal();
          }
        },

        enableEdit(rIdx) {
          showConfirm(
            "Editar Rodada Anterior?",
            "A rodada atual será bloqueada temporariamente.",
            () => {
              State.game.editingIdx = rIdx;
              State.save();
              Render.all();
            }
          );
        },

        switchTab(t) {
          document
            .querySelectorAll(".nav-link")
            .forEach((e) => e.classList.remove("active"));
          document.getElementById(`nav-${t}`).classList.add("active");
          document
            .getElementById("tab-game")
            .classList.toggle("hidden", t !== "game");
          document
            .getElementById("tab-players")
            .classList.toggle("hidden", t !== "players");
          document
            .getElementById("tab-rules")
            .classList.toggle("hidden", t !== "rules");
          document
            .getElementById("tab-about")
            .classList.toggle("hidden", t !== "about");
        },

        // Timer Settings
        openTimerSettings() {
          document.getElementById("timerModal").classList.remove("hidden");
          const minutes = Math.round(State.timer.d / 60);
          document.getElementById("customDuration").value = minutes;
          document.getElementById("soundToggle").checked = State.timer.s;

          const rule = State.game.timeRule || (minutes === 1 ? "official" : minutes === 2 ? "alternative" : "custom");
          const radio = document.querySelector(`input[name=\"timeRule\"][value=\"${rule}\"]`);
          if (radio) radio.checked = true;
          document.getElementById("autoRotateToggle").checked = State.game.turnAutoRotate !== false;
          document.getElementById("confirmOnExpiry").checked = State.game.confirmExpiry === true;
        },
        closeTimerSettings() {
          document.getElementById("timerModal").classList.add("hidden");
        },
        setTempDuration(v) {
          document.getElementById("customDuration").value = v;
        },
        saveTimerSettings() {
          const selected = document.querySelector('input[name="timeRule"]:checked');
          const rule = selected ? selected.value : 'custom';

          const minutesInput = document.getElementById("customDuration").value;
          const minutes = parseInt(minutesInput);

          let seconds = 60;
          if (rule === 'official') seconds = 60;
          else if (rule === 'alternative') seconds = 120;
          else if (rule === 'impatient') seconds = 30;
          else if (rule === 'custom') {
            if (Number.isNaN(minutes)) {
              showError("Informe um número de minutos válido.");
              return;
            }
            if (minutes < 1 || minutes >= 60) {
              showError("O tempo deve ser maior ou igual a 1 e menor que 60 minutos.");
              return;
            }
            seconds = minutes * 60;
          }

          State.timer.d = seconds;
          State.timer.s = document.getElementById("soundToggle").checked;
          State.game.timeRule = rule;
          State.game.turnAutoRotate = document.getElementById("autoRotateToggle").checked;
          State.game.confirmExpiry = document.getElementById("confirmOnExpiry").checked === true;
          State.saveTimer();
          State.save();
          Timer.reset();
          this.closeTimerSettings();
        },
        rotateToNextPlayer() {
          if (!Array.isArray(State.game.players) || State.game.players.length === 0) return;
          // encerra turno atual
          this.endCurrentTurn('rotate');

          State.game.turnIdx = (typeof State.game.turnIdx === 'number' ? State.game.turnIdx : 0) + 1;
          State.game.turnIdx = State.game.turnIdx % State.game.players.length;
          State.save();
          // inicia novo turno
          this.startCurrentTurn();

          Render.playersManager();
          Timer.updateUI();
        },
        confirmSkipTurn() {
          const pIdx = typeof State.game.turnIdx === 'number' ? State.game.turnIdx : 0;
          const name = State.game.players[pIdx] || `Jogador ${pIdx + 1}`;
          showConfirm('Pular turno?', `Deseja pular o turno de ${name}?`, () => {
            this.skipTurn();
          });
        },
        skipTurn() {
          const wasRunning = State.timer.r;
          // Sem penalidade automática; apenas rotaciona
          this.rotateToNextPlayer();
          Timer.reset();
          if (wasRunning || State.game.turnAutoRotate) {
            Timer.start();
          }
          showEvent(`Turno pulado manualmente por ação do usuário.`);
        }
};
// === GLOBAL MODALS & TOASTS ===
let confirmCallback = null;
function showConfirm(title, msg, cb) {
  const t = document.getElementById("confirmTitle");
  const m = document.getElementById("confirmMsg");
  if (t) t.innerText = title;
  if (m) m.innerText = msg;
  confirmCallback = cb;
  const modal = document.getElementById("confirmModal");
  if (modal) modal.classList.remove("hidden");
}
function closeConfirm() {
  const modal = document.getElementById("confirmModal");
  if (modal) modal.classList.add("hidden");
  confirmCallback = null;
}
function execConfirm() {
  if (confirmCallback) confirmCallback();
  closeConfirm();
}
function confirmReset() {
  showConfirm(
    "Reiniciar Jogo?",
    "Todos os dados da partida serão perdidos.",
    () => {
      State.game = {
        players: [],
        rounds: [],
        currIdx: 0,
        editingIdx: null,
        locked: false,
        started: false,
        tileDetails: {},
        roundWinners: {},
      };
      State.save();
      Render.all();
    }
  );
}

function closeGameOverModal() {
  const m = document.getElementById("gameOverModal");
  if (m) m.classList.add("hidden");
}

function showToast(msg, timeout = 4500) {
  const container = document.getElementById('toastContainer');
  if (!container) return;
  const el = document.createElement('div');
  el.className = 'toast px-4 py-2 rounded-xl shadow-lg bg-slate-900 text-white text-sm mb-2';
  el.innerText = msg;
  container.appendChild(el);
  setTimeout(() => {
    el.classList.add('toast-fade');
    setTimeout(() => { try { container.removeChild(el); } catch (e) {} }, 300);
  }, timeout);
}

let LastClearUndo = null; // { pIdx, historyBackup, penaltiesBackup, timeoutId }
function showUndoToast(msg, actionLabel, actionCb, timeout = 10000) {
  const container = document.getElementById('toastContainer');
  if (!container) return;
  const prev = container.querySelector('.toast-undo');
  if (prev) { try { container.removeChild(prev); } catch (e) {} }
  const el = document.createElement('div');
  el.className = 'toast-undo px-4 py-2 rounded-xl shadow-lg bg-slate-900 text-white text-sm mb-2 flex items-center gap-3';
  const span = document.createElement('span');
  span.innerText = msg;
  const btn = document.createElement('button');
  btn.className = 'ml-2 px-3 py-1 rounded bg-orange-500 text-white font-bold';
  btn.innerText = actionLabel;
  btn.onclick = () => {
    try { actionCb(); } catch (e) { console.warn(e); }
    try { el.classList.add('toast-fade'); setTimeout(() => { try { container.removeChild(el); } catch (e) {} }, 300); } catch (e) {}
  };
  el.appendChild(span);
  el.appendChild(btn);
  container.appendChild(el);
  const tid = setTimeout(() => {
    try { el.classList.add('toast-fade'); setTimeout(() => { try { container.removeChild(el); } catch (e) {} }, 300); } catch (e) {}
    if (LastClearUndo && LastClearUndo.timeoutId === tid) {
      LastClearUndo = null;
    }
  }, timeout);
  if (LastClearUndo) {
    LastClearUndo.timeoutId = tid;
  }
}

function showEvent(msg) {
  try {
    const ts = new Date().toISOString();
    if (!Array.isArray(State.game.events)) State.game.events = [];
    State.game.events.unshift({ ts, msg });
    if (State.game.events.length > 200) State.game.events.length = 200;
    State.save();
    Render.eventLog();
  } catch (e) {
    console.warn('Erro ao registrar evento', e);
  }
}

function restartFromGameOver() {
  closeGameOverModal();
  confirmReset();
}

function openGameOverModal() {
  const sums = new Array(State.game.players.length).fill(0);
  (State.game.rounds || []).forEach((r) => {
    if (!Array.isArray(r)) return;
    r.forEach((v, i) => {
      const n = parseInt(v);
      if (!isNaN(n)) sums[i] += n;
    });
  });

  const ranked = sums
    .map((s, i) => ({ i, n: State.game.players[i], s }))
    .sort((a, b) => (b.s - a.s) || (a.i - b.i));

  const winner = ranked.length ? ranked[0] : null;
  const title = document.getElementById("gameOverTitle");
  const subtitle = document.getElementById("gameOverSubtitle");
  const list = document.getElementById("gameOverRanking");

  if (winner) {
    if (title) title.textContent = `Parabéns, ${winner.n}!`;
    if (subtitle) subtitle.textContent = "Vencedor(a) da partida. Classificação final:";
  } else {
    if (title) title.textContent = "Jogo finalizado!";
    if (subtitle) subtitle.textContent = "Classificação final:";
  }

  let html = "";
  const trophySvg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-4 h-4 trophy-icon" aria-hidden="true"><path d="M10 2a.75.75 0 01.75.75v.846a4.5 4.5 0 003.66 4.411.75.75 0 01.64.74v1.003a4.5 4.5 0 01-3.155 4.29l-.695.232a.75.75 0 00-.51.711V16.5h1.5a.75.75 0 010 1.5h-5a.75.75 0 010-1.5h1.5v-1.525a.75.75 0 00-.51-.711l-.695-.232A4.5 4.5 0 015.5 9.75V8.747a.75.75 0 01.64-.74 4.5 4.5 0 003.66-4.411V2.75A.75.75 0 0110 2z" /><path d="M4.5 5.75a.75.75 0 00-1.5 0v2A2.75 2.75 0 005.75 10.5h.392a6.023 6.023 0 01-.439-1.5H5.75A1.25 1.25 0 014.5 7.75v-2zM15.5 5.75a.75.75 0 011.5 0v2a2.75 2.75 0 01-2.75 2.75h-.392c.216-.48.364-.98.439-1.5h-.047A1.25 1.25 0 0015.5 7.75v-2z" /></svg>';

  ranked.forEach((p, rank) => {
    const isLead = rank === 0;
    const isSecond = rank === 1;
    const isThird = rank === 2;

    const badgeBg = isLead
      ? "bg-yellow-100 border-yellow-200 text-yellow-800"
      : isSecond
      ? "bg-slate-100 border-slate-200 text-slate-700"
      : isThird
      ? "bg-orange-100 border-orange-200 text-orange-800"
      : "bg-slate-100 border-slate-200 text-slate-600";

    const col =
      p.s > 0
        ? "text-emerald-600"
        : p.s < 0
        ? "text-rose-600"
        : "text-slate-400";

    const sign = p.s > 0 ? "+" : "";
    const badgeContent = isLead
      ? trophySvg
      : `<span class="text-xs font-black tabular-nums">${rank + 1}</span>`;

    html += `
      <div class="w-full rounded-lg border border-slate-200 bg-white px-2 py-1.5">
        <div class="flex items-center justify-between gap-3">
          <div class="flex items-center gap-2 min-w-0">
            <div class="w-6 h-6 rounded-md border ${badgeBg} flex items-center justify-center shrink-0">
              ${badgeContent}
            </div>
            <div class="text-xs font-bold text-slate-800 truncate min-w-0">${p.n}</div>
          </div>
          <div class="text-xs font-black tabular-nums ${col}">${sign}${p.s}</div>
        </div>
      </div>
    `;
  });

  if (list) list.innerHTML = html;
  const modal = document.getElementById("gameOverModal");
  if (modal) modal.classList.remove("hidden");
}

function showError(msg) {
  const el = document.getElementById("errorModalMsg");
  if (el) el.innerText = msg;
  const m = document.getElementById("errorModal");
  if (m) m.classList.remove("hidden");
}

function showErrorDialog(diff, pos, neg) {
  const m = document.getElementById("errorModal");
  const em = document.getElementById("errorModalMsg");
  if (em) em.innerHTML = `<div class="space-y-3"><p>A soma deve ser zero.</p><div class="flex justify-between text-xs font-bold uppercase bg-slate-50 p-3 rounded-lg border border-slate-200"><div class="text-emerald-600 text-center">Positivos<br><span class="text-lg">+${pos}</span></div><div class="text-rose-600 text-center">Negativos<br><span class="text-lg">${neg}</span></div></div><div class="bg-red-50 p-2 rounded-lg text-center"><p class="text-xs font-bold text-red-800 uppercase mb-1">Diferença</p><p class="text-2xl font-black text-red-600">${
    diff > 0 ? "+" : ""
  }${diff}</p></div></div>`;
  if (m) m.classList.remove("hidden");
}

let pendingCalculation = null;

function openWinnerModal(roundIdx, playerIdx, score) {
  const name = (State.game.players && State.game.players[playerIdx]) || "";
  const nameEl = document.getElementById("modalWinnerName");
  const scoreEl = document.getElementById("modalWinnerScore");
  const badgeEl = document.getElementById("modalWinnerBadge");
  const msgEl = document.getElementById("winnerModalMsg");
  const modal = document.getElementById("winnerModal");
  const confirmBtn = document.getElementById("confirmWinnerBtn");

  if (nameEl) nameEl.textContent = name;

  const sStr = `${score > 0 ? "+" : ""}${score}`;
  if (scoreEl) scoreEl.textContent = sStr;
  if (badgeEl) {
    badgeEl.textContent = sStr;
    badgeEl.classList.remove("bg-emerald-600", "bg-rose-600");
    badgeEl.classList.add(score >= 0 ? "bg-emerald-600" : "bg-rose-600");
    // trigger pulse animation
    badgeEl.classList.remove("badge-pulse");
    void badgeEl.offsetWidth; // force reflow
    badgeEl.classList.add("badge-pulse");
    // remove the class after animation to keep DOM clean
    setTimeout(() => badgeEl.classList.remove("badge-pulse"), 700);
  }

  if (msgEl)
    msgEl.textContent = `Pontos calculados: ${sStr}. Confirme para aplicar e encerrar a rodada.`;

  pendingCalculation = { roundIdx, playerIdx, score };
  if (modal) modal.classList.remove("hidden");

  // foco no botão confirmar para melhor acessibilidade
  if (confirmBtn && confirmBtn.focus) {
    confirmBtn.focus();
  }

  // som de confirmação leve
  if (typeof Sound !== "undefined" && Sound.tick) Sound.tick();
}

function confirmWinner() {
  if (pendingCalculation) {
    State.game.rounds[pendingCalculation.roundIdx][
      pendingCalculation.playerIdx
    ] = pendingCalculation.score.toString();
    const w = document.getElementById("winnerModal");
    if (w) w.classList.add("hidden");
    Actions.finishAction(pendingCalculation.roundIdx);
  }
}

function closeWinnerModal() {
  const w = document.getElementById("winnerModal");
  if (w) w.classList.add("hidden");
  pendingCalculation = null;
}

// Hook confirm button
const confirmBtn = document.getElementById("confirmBtnAction");
if (confirmBtn) confirmBtn.onclick = execConfirm;

// Expose important globals to window for test environments
if (typeof window !== 'undefined') {
  try {
    window.State = State;
    window.Timer = Timer;
    window.Actions = typeof Actions !== 'undefined' ? Actions : undefined;
    // Render may live in index.html if not yet migrated; keep any existing one
    if (typeof Render !== 'undefined') window.Render = Render;
  } catch (e) {}
}

// Inicialização
State.init();
Timer.updateUI();
if (typeof Render !== 'undefined' && Render && typeof Render.all === 'function') Render.all();

// Container para toasts
const tCont = document.createElement('div');
tCont.id = 'toastContainer';
tCont.className = 'fixed bottom-6 right-6 z-50';
document.body.appendChild(tCont);
  