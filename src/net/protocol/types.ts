export type Role = 'pilot' | 'sonar' | 'engineer' | 'gunner';

export type Lane = 0 | 1 | 2; // 0: Sinistra, 1: Centro, 2: Destra
export type Speed = 'stop' | 'slow' | 'full';

export type ThreatType = 
  | 'mine' 
  | 'current' 
  | 'reef' 
  | 'leviathan' 
  | 'short_circuit' 
  | 'wreck' 
  | 'titan';

export interface Threat {
  id: string;
  type: ThreatType;
  name: string;
  lanes: Lane[]; // corsie coinvolte
  currentDirection?: -1 | 1; // per le correnti: -1 spinge a sinistra, +1 a destra
  distanceCycles: number; // 1 = colpisce questo ciclo, 2 = colpisce il prossimo
  code: string; // codice 3 simboli per siluro (es: 'Δ-Ω-Ψ')
  revealed: boolean; // se il Sonar ha fatto Ping
  destroyed?: boolean;
}

export type CyclePhase = 'detection' | 'planning' | 'resolution';

export interface SystemEnergy {
  engine: number;
  sonar: number;
  weapons: number;
}

export interface SystemHeat {
  engine: number;
  sonar: number;
  weapons: number;
}

export interface ResolutionEvent {
  id: string;
  title: string;
  description: string;
  type: 'damage' | 'destroyed' | 'avoided' | 'bonus' | 'warning' | 'info';
  hullChange: number;
  scoreChange: number;
}

export interface GameState {
  missionId: string;
  sector: number; // 1-5
  maxSectors: number;
  cycleIndex: number; // 1-6 per settore
  maxCyclesPerSector: number;
  
  hull: number; // 0-6
  maxHull: number;
  
  energy: SystemEnergy; // Totale 6 da distribuire
  maxTotalEnergy: number;
  heat: SystemHeat; // >= 4 genera surriscaldamento
  
  shieldActive: boolean;
  
  currentLane: Lane;
  currentSpeed: Speed;
  
  threats: Threat[];
  
  score: number;
  perfectCyclesInRow: number;
  
  phase: CyclePhase;
  phaseDurationMs: number;
  phaseTimeRemainingMs: number;
  
  lastEvents: ResolutionEvent[];
  isGameOver: boolean;
  isVictory: boolean;
  
  // Settore 5 Boss
  bossHp?: number; // 3 colpi necessari
}

// Azioni inviate dai giocatori
export type PlayerAction =
  | { role: 'pilot'; action: 'SET_LANE'; lane: Lane }
  | { role: 'pilot'; action: 'SET_SPEED'; speed: Speed }
  | { role: 'sonar'; action: 'PING'; threatId: string }
  | { role: 'engineer'; action: 'SET_ENERGY'; system: keyof SystemEnergy; delta: number }
  | { role: 'engineer'; action: 'COOL_DOWN'; system: keyof SystemHeat }
  | { role: 'gunner'; action: 'FIRE_TORPEDO'; code: string; lane: Lane }
  | { role: 'gunner'; action: 'ACTIVATE_SHIELD' };

// Protocollo Messaggi di Rete (BLE / Loopback)
export type NetworkMessage =
  | { type: 'HELLO'; playerId: string; name: string; version: number }
  | { type: 'LOBBY_STATE'; players: { id: string; name: string; role: Role; isHost: boolean }[]; settings: any }
  | { type: 'START_MISSION'; seed: number; sector: number }
  | { type: 'CYCLE_START'; cycleIndex: number; phase: CyclePhase; durationMs: number; hostTimestamp: number }
  | { type: 'ACTION'; playerId: string; cycleIndex: number; action: PlayerAction }
  | { type: 'CYCLE_RESULT'; state: GameState; events: ResolutionEvent[] }
  | { type: 'HEARTBEAT'; playerId: string; timestamp: number }
  | { type: 'PAUSE'; reason?: string }
  | { type: 'RESUME' };
