import { 
  GameState, 
  PlayerAction, 
  Role, 
  NetworkMessage, 
  CyclePhase, 
  Lane 
} from '../protocol/types';
import { createInitialGameState, applyPlayerAction, resolveCycle } from '../../game/engine/gameEngine';
import { Transport } from '../transport/Transport';

export interface ConnectedPlayer {
  id: string;
  name: string;
  role: Role;
  isHost: boolean;
  isBot?: boolean;
}

export class HostSession {
  private state: GameState;
  private players: Map<string, ConnectedPlayer> = new Map();
  private cycleTimer: any = null;
  private tickInterval: any = null;
  private torpedoBuffer: { lane: Lane; code: string }[] = [];
  private onStateUpdateCallbacks: ((state: GameState) => void)[] = [];

  constructor(private transport: Transport) {
    this.state = createInitialGameState();
    this.setupTransport();
  }

  private setupTransport(): void {
    this.transport.onMessage(msg => {
      this.handleIncomingMessage(msg);
    });
  }

  public addPlayer(player: ConnectedPlayer): void {
    this.players.set(player.id, player);
    this.broadcastLobby();
  }

  public fillBots(): void {
    const roles: Role[] = ['pilot', 'sonar', 'engineer', 'gunner'];
    const takenRoles = new Set(Array.from(this.players.values()).map(p => p.role));

    roles.forEach(role => {
      if (!takenRoles.has(role)) {
        this.players.set(`bot_${role}`, {
          id: `bot_${role}`,
          name: `IA ${role.toUpperCase()}`,
          role,
          isHost: false,
          isBot: true,
        });
      }
    });
    this.broadcastLobby();
  }

  public startMission(): void {
    this.state = createInitialGameState();
    this.transport.send({
      type: 'START_MISSION',
      seed: Date.now(),
      sector: 1,
    });
    this.startCyclePhase('detection', 5000);
  }

  private startCyclePhase(phase: CyclePhase, durationMs: number): void {
    if (this.state.isGameOver || this.state.isVictory) return;

    this.state.phase = phase;
    this.state.phaseDurationMs = durationMs;
    this.state.phaseTimeRemainingMs = durationMs;

    this.transport.send({
      type: 'CYCLE_START',
      cycleIndex: this.state.cycleIndex,
      phase,
      durationMs,
      hostTimestamp: Date.now(),
    });

    this.notifyState();

    if (this.cycleTimer) clearTimeout(this.cycleTimer);
    if (this.tickInterval) clearInterval(this.tickInterval);

    // Countdown tick ogni 200 ms
    const startTime = Date.now();
    this.tickInterval = setInterval(() => {
      const elapsed = Date.now() - startTime;
      this.state.phaseTimeRemainingMs = Math.max(0, durationMs - elapsed);
      this.notifyState();
    }, 200);

    // Esegui logica dei Bot durante la fase di pianificazione
    if (phase === 'planning') {
      setTimeout(() => this.executeBotActions(), 3000);
    }

    this.cycleTimer = setTimeout(() => {
      clearInterval(this.tickInterval);
      this.advancePhase();
    }, durationMs);
  }

  private advancePhase(): void {
    if (this.state.phase === 'detection') {
      // Passa a Planning: 15s (12s nel settore 5)
      const planningDuration = this.state.sector === 5 ? 12000 : 15000;
      this.startCyclePhase('planning', planningDuration);
    } else if (this.state.phase === 'planning') {
      // Passa a Risoluzione: 5s
      const { nextState, events } = resolveCycle(this.state, this.torpedoBuffer);
      this.state = nextState;
      this.torpedoBuffer = []; // Reset siluri per il prossimo ciclo

      this.transport.send({
        type: 'CYCLE_RESULT',
        state: this.state,
        events,
      });

      this.startCyclePhase('resolution', 5000);
    } else if (this.state.phase === 'resolution') {
      // Se vivo, torna a Detection
      if (!this.state.isGameOver && !this.state.isVictory) {
        this.startCyclePhase('detection', 5000);
      }
    }
  }

  private executeBotActions(): void {
    // I bot intervengono solo per i ruoli non controllati da umani
    this.players.forEach(p => {
      if (!p.isBot) return;

      if (p.role === 'sonar') {
        // Il bot sonar pinga le minacce sconosciute se c'è energia
        if (this.state.energy.sonar >= 1) {
          applyPlayerAction(this.state, { role: 'sonar', action: 'PING', threatId: 'all' });
        }
      } else if (p.role === 'engineer') {
        // Se c'è calore elevato, sfiata
        (Object.keys(this.state.heat) as (keyof typeof this.state.heat)[]).forEach(sys => {
          if (this.state.heat[sys] >= 2) {
            applyPlayerAction(this.state, { role: 'engineer', action: 'COOL_DOWN', system: sys });
          }
        });
      } else if (p.role === 'gunner') {
        // Se una mina è rivelata nella nostra corsia, prova a sparare
        const target = this.state.threats.find(t => t.revealed && t.lanes.includes(this.state.currentLane));
        if (target && this.state.energy.weapons >= 1) {
          applyPlayerAction(this.state, { 
            role: 'gunner', 
            action: 'FIRE_TORPEDO', 
            code: target.code, 
            lane: this.state.currentLane 
          }, this.torpedoBuffer);
        }
      }
    });
    this.notifyState();
  }

  private handleIncomingMessage(msg: NetworkMessage): void {
    if (msg.type === 'ACTION') {
      const res = applyPlayerAction(this.state, msg.action, this.torpedoBuffer);
      if (res.actionAccepted) {
        this.state = res.nextState;
        this.notifyState();
      }
    } else if (msg.type === 'HELLO') {
      this.addPlayer({
        id: msg.playerId,
        name: msg.name,
        role: this.getNextAvailableRole(),
        isHost: false,
      });
    }
  }

  public dispatchAction(action: PlayerAction): boolean {
    const res = applyPlayerAction(this.state, action, this.torpedoBuffer);
    if (res.actionAccepted) {
      this.state = res.nextState;
      this.notifyState();
      return true;
    }
    return false;
  }

  private getNextAvailableRole(): Role {
    const assigned = new Set(Array.from(this.players.values()).map(p => p.role));
    const allRoles: Role[] = ['pilot', 'sonar', 'engineer', 'gunner'];
    return allRoles.find(r => !assigned.has(r)) || 'pilot';
  }

  private broadcastLobby(): void {
    this.transport.send({
      type: 'LOBBY_STATE',
      players: Array.from(this.players.values()),
      settings: {},
    });
  }

  public onStateUpdate(cb: (state: GameState) => void): () => void {
    this.onStateUpdateCallbacks.push(cb);
    cb(this.state);
    return () => {
      this.onStateUpdateCallbacks = this.onStateUpdateCallbacks.filter(c => c !== cb);
    };
  }

  private notifyState(): void {
    this.onStateUpdateCallbacks.forEach(cb => cb({ ...this.state }));
  }

  public getState(): GameState {
    return this.state;
  }

  public destroy(): void {
    if (this.cycleTimer) clearTimeout(this.cycleTimer);
    if (this.tickInterval) clearInterval(this.tickInterval);
  }
}
