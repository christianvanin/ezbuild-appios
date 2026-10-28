import { 
  GameState, 
  PlayerAction, 
  ResolutionEvent, 
  Threat, 
  Lane, 
  Speed, 
  SystemEnergy, 
  SystemHeat 
} from '../../net/protocol/types';
import { generateThreatsForCycle } from '../content/threats';

export function createInitialGameState(missionId: string = 'ECHO-9-ALPHA'): GameState {
  const initialThreats = generateThreatsForCycle(1, 1);
  return {
    missionId,
    sector: 1,
    maxSectors: 5,
    cycleIndex: 1,
    maxCyclesPerSector: 6,
    
    hull: 6,
    maxHull: 6,
    
    energy: {
      engine: 2,
      sonar: 2,
      weapons: 2,
    },
    maxTotalEnergy: 6,
    heat: {
      engine: 0,
      sonar: 0,
      weapons: 0,
    },
    
    shieldActive: false,
    
    currentLane: 1, // Centro
    currentSpeed: 'slow',
    
    threats: initialThreats,
    
    score: 0,
    perfectCyclesInRow: 0,
    
    phase: 'detection',
    phaseDurationMs: 5000,
    phaseTimeRemainingMs: 5000,
    
    lastEvents: [
      {
        id: 'init_start',
        title: 'Immersione Iniziata',
        description: 'Sottomarino ECHO-9 calato negli abissi. Equipaggio operativo!',
        type: 'info',
        hullChange: 0,
        scoreChange: 0,
      }
    ],
    isGameOver: false,
    isVictory: false,
  };
}

export function applyPlayerAction(
  state: GameState, 
  action: PlayerAction, 
  torpedoLog: { lane: Lane; code: string }[] = []
): { nextState: GameState; actionAccepted: boolean; message?: string } {
  const next = { ...state };

  switch (action.role) {
    case 'pilot': {
      if (action.action === 'SET_LANE') {
        next.currentLane = action.lane;
        return { nextState: next, actionAccepted: true };
      } else if (action.action === 'SET_SPEED') {
        next.currentSpeed = action.speed;
        return { nextState: next, actionAccepted: true };
      }
      break;
    }

    case 'sonar': {
      if (action.action === 'PING') {
        // Verifica se c'è energia nel Sonar
        if (next.energy.sonar < 1) {
          return { nextState: next, actionAccepted: false, message: 'Energia Sonar insufficiente per il Ping!' };
        }
        // Ping rivela le minacce
        next.threats = next.threats.map(t => {
          if (t.id === action.threatId || action.threatId === 'all') {
            return { ...t, revealed: true };
          }
          return t;
        });
        return { nextState: next, actionAccepted: true, message: 'Ping Sonar emesso con successo!' };
      }
      break;
    }

    case 'engineer': {
      if (action.action === 'SET_ENERGY') {
        const currentSystemVal = next.energy[action.system];
        const newSystemVal = currentSystemVal + action.delta;
        if (newSystemVal < 0) {
          return { nextState: next, actionAccepted: false, message: 'Energia non può essere negativa.' };
        }

        const totalOthers = (Object.keys(next.energy) as (keyof SystemEnergy)[])
          .filter(k => k !== action.system)
          .reduce((sum, k) => sum + next.energy[k], 0);

        if (newSystemVal + totalOthers > next.maxTotalEnergy) {
          return { nextState: next, actionAccepted: false, message: `Energia totale massima (${next.maxTotalEnergy}) raggiunta!` };
        }

        next.energy = { ...next.energy, [action.system]: newSystemVal };
        return { nextState: next, actionAccepted: true };
      } else if (action.action === 'COOL_DOWN') {
        next.heat = { ...next.heat, [action.system]: Math.max(0, next.heat[action.system] - 2) };
        return { nextState: next, actionAccepted: true, message: `Raffreddamento completato su ${action.system}.` };
      }
      break;
    }

    case 'gunner': {
      if (action.action === 'ACTIVATE_SHIELD') {
        if (next.energy.weapons < 1) {
          return { nextState: next, actionAccepted: false, message: 'Energia Armi insufficiente per attivare lo Scudo!' };
        }
        next.shieldActive = !next.shieldActive;
        return { nextState: next, actionAccepted: true };
      } else if (action.action === 'FIRE_TORPEDO') {
        if (next.energy.weapons < 1) {
          return { nextState: next, actionAccepted: false, message: 'Energia Armi insufficiente per lanciare il siluro!' };
        }
        torpedoLog.push({ lane: action.lane, code: action.code });
        return { nextState: next, actionAccepted: true, message: `Siluro lanciato verso Corsia ${action.lane} con codice ${action.code}!` };
      }
      break;
    }
  }

  return { nextState: next, actionAccepted: false };
}

export function resolveCycle(
  state: GameState, 
  torpedoesFired: { lane: Lane; code: string }[] = []
): { nextState: GameState; events: ResolutionEvent[] } {
  const events: ResolutionEvent[] = [];
  let hullChange = 0;
  let scoreChange = 0;
  let subLane = state.currentLane;

  // 1. Surriscaldamento: se un sistema ha >= 4 energia, accumula calore
  const nextHeat = { ...state.heat };
  (Object.keys(state.energy) as (keyof SystemEnergy)[]).forEach(sys => {
    if (state.energy[sys] >= 4) {
      nextHeat[sys] = (nextHeat[sys] || 0) + 1;
      events.push({
        id: `heat_${sys}_${state.cycleIndex}`,
        title: `Surriscaldamento Impianto: ${sys.toUpperCase()}`,
        description: `Il sistema ${sys} opera a regime critico (${state.energy[sys]} unità). Raffreddarlo subito!`,
        type: 'warning',
        hullChange: 0,
        scoreChange: 0,
      });
    }
  });

  // 2. Correnti oceaniche: influenzano la corsia
  state.threats.forEach(t => {
    if (t.type === 'current' && t.currentDirection) {
      const newLane = (subLane + t.currentDirection) as Lane;
      if (newLane >= 0 && newLane <= 2) {
        subLane = newLane;
        events.push({
          id: `curr_${t.id}`,
          title: 'Corrente Improvvisa!',
          description: `La corrente ha spinto il sottomarino nella corsia ${newLane === 0 ? 'Sinistra' : newLane === 1 ? 'Centro' : 'Destra'}!`,
          type: 'info',
          hullChange: 0,
          scoreChange: 5,
        });
      }
    }
  });

  // 3. Verifica Siluri lanciati dall'Armiere
  const remainingThreats: Threat[] = [];
  state.threats.forEach(threat => {
    let hit = false;
    torpedoesFired.forEach(torp => {
      // Per colpire, la corsia deve corrispondere e il codice deve essere esatto
      const laneMatches = threat.lanes.includes(torp.lane);
      const codeMatches = torp.code.trim().toUpperCase() === threat.code.trim().toUpperCase();

      if (laneMatches && codeMatches) {
        hit = true;
      }
    });

    if (hit) {
      scoreChange += 15;
      events.push({
        id: `destroyed_${threat.id}`,
        title: `Bersaglio Distrutto: ${threat.name}`,
        description: `Siluro a segno! Minaccia eliminata con codice ${threat.code} in corsia ${threat.lanes.join(', ')}.`,
        type: 'destroyed',
        hullChange: 0,
        scoreChange: 15,
      });
    } else {
      remainingThreats.push(threat);
    }
  });

  // 4. Risoluzione impatti con minacce rimanenti
  let shieldAvailable = state.shieldActive && state.energy.weapons >= 1;

  remainingThreats.forEach(threat => {
    if (threat.type === 'mine') {
      if (threat.lanes.includes(subLane)) {
        if (shieldAvailable) {
          shieldAvailable = false;
          events.push({
            id: `shield_${threat.id}`,
            title: 'Scudo Energetico a Segno!',
            description: `Lo scudo ha deflesso l'esplosione della mina in corsia ${subLane}!`,
            type: 'avoided',
            hullChange: 0,
            scoreChange: 10,
          });
        } else {
          hullChange -= 1;
          events.push({
            id: `hit_${threat.id}`,
            title: 'Impatto con Mina!',
            description: `Esplosione in corsia ${subLane}! Lo scafo ha subito 1 danno.`,
            type: 'damage',
            hullChange: -1,
            scoreChange: 0,
          });
        }
      } else {
        scoreChange += 10;
        events.push({
          id: `avoided_${threat.id}`,
          title: 'Mina Evitata',
          description: `Il Pilota ha mantenuto la corsia libera da mine (+10 pts).`,
          type: 'avoided',
          hullChange: 0,
          scoreChange: 10,
        });
      }
    } else if (threat.type === 'reef') {
      if (threat.lanes.includes(subLane)) {
        if (state.currentSpeed === 'stop') {
          events.push({
            id: `reef_stop_${threat.id}`,
            title: 'Passaggio Radente tra gli Scogli',
            description: `A motori fermi il sottomarino ha sfiorato gli scogli senza subire danni!`,
            type: 'avoided',
            hullChange: 0,
            scoreChange: 15,
          });
        } else {
          hullChange -= 1;
          events.push({
            id: `reef_hit_${threat.id}`,
            title: 'Collisione con Scogliera!',
            description: `Scafo squarciato sulle rocce in corsia ${subLane}! (-1 Scafo)`,
            type: 'damage',
            hullChange: -1,
            scoreChange: 0,
          });
        }
      } else {
        scoreChange += 10;
        events.push({
          id: `reef_avoided_${threat.id}`,
          title: 'Canale Libero Attraversato',
          description: `Rotta corretta attraverso il banco di rocce (+10 pts).`,
          type: 'avoided',
          hullChange: 0,
          scoreChange: 10,
        });
      }
    } else if (threat.type === 'leviathan') {
      // Richiede Silenzio: Motore e Sonar devono essere a 0 energia
      const isSilent = state.energy.engine === 0 && state.energy.sonar === 0;
      if (isSilent) {
        scoreChange += 25;
        events.push({
          id: `leviathan_silent_${threat.id}`,
          title: 'Leviatano Superato in Silenzio!',
          description: `Sistemi acustici a zero: il mostro delle profondità non ha avvertito il sommergibile! (+25 pts)`,
          type: 'avoided',
          hullChange: 0,
          scoreChange: 25,
        });
      } else {
        hullChange -= 2;
        events.push({
          id: `leviathan_attack_${threat.id}`,
          title: 'Attacco del Leviatano!',
          description: `I motori/sonar hanno tradito la posizione! Il Leviatano ha stritolato lo scafo (-2 Scafo)!`,
          type: 'damage',
          hullChange: -2,
          scoreChange: 0,
        });
      }
    } else if (threat.type === 'wreck') {
      // Bonus: passare a velocità lenta nella corsia giusta guarisce 1 scafo
      if (threat.lanes.includes(subLane) && state.currentSpeed === 'slow') {
        hullChange += 1;
        scoreChange += 20;
        events.push({
          id: `wreck_salvage_${threat.id}`,
          title: 'Recupero Relitto Riuscito!',
          description: `Recuperati pezzi di ricambio dal relitto sommerso (+1 Scafo, +20 pts)!`,
          type: 'bonus',
          hullChange: 1,
          scoreChange: 20,
        });
      }
    }
  });

  // 5. Bonus Sincronia: ciclo pulito senza danni
  let perfectInRow = state.perfectCyclesInRow;
  if (hullChange >= 0) {
    scoreChange += 5;
    perfectInRow += 1;
    if (perfectInRow >= 3) {
      scoreChange += 20;
      events.push({
        id: `sync_bonus_${state.cycleIndex}`,
        title: '★ Bonus Sincronia Equipaggio! ★',
        description: 'Tre cicli consecutivi perfetti senza alcun danno subito! (+20 pts squadra)',
        type: 'bonus',
        hullChange: 0,
        scoreChange: 20,
      });
    }
  } else {
    perfectInRow = 0;
  }

  const finalHull = Math.max(0, Math.min(state.maxHull, state.hull + hullChange));
  const isGameOver = finalHull <= 0;

  // 6. Avanzamento Ciclo / Settore
  let nextSector = state.sector;
  let nextCycleIndex = state.cycleIndex + 1;
  let isVictory = false;

  if (nextCycleIndex > state.maxCyclesPerSector) {
    if (nextSector >= state.maxSectors) {
      isVictory = true;
    } else {
      nextSector += 1;
      nextCycleIndex = 1;
      events.push({
        id: `sector_complete_${nextSector}`,
        title: `Settore ${state.sector} Completato!`,
        description: `Discesa nel Settore ${nextSector}. Riparazione scafo +1 unità ed energia ricaricata!`,
        type: 'bonus',
        hullChange: 1,
        scoreChange: 50,
      });
    }
  }

  // Genera minacce per il prossimo ciclo se non è game over
  const nextThreats = (!isGameOver && !isVictory) 
    ? generateThreatsForCycle(nextSector, nextCycleIndex) 
    : [];

  const nextState: GameState = {
    ...state,
    sector: nextSector,
    cycleIndex: nextCycleIndex,
    hull: finalHull,
    heat: nextHeat,
    currentLane: subLane,
    shieldActive: false, // Lo scudo si resetta ogni ciclo
    threats: nextThreats,
    score: state.score + scoreChange,
    perfectCyclesInRow: perfectInRow,
    phase: 'detection',
    phaseDurationMs: 5000,
    phaseTimeRemainingMs: 5000,
    lastEvents: events,
    isGameOver,
    isVictory,
  };

  return { nextState, events };
}
