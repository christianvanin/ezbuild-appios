import { GameState, NetworkMessage, PlayerAction, Role } from '../protocol/types';
import { Transport } from '../transport/Transport';

export class ClientSession {
  private role: Role;
  private state: GameState | null = null;
  private onStateUpdateCallbacks: ((state: GameState) => void)[] = [];

  constructor(
    private transport: Transport,
    private playerId: string,
    initialRole: Role = 'pilot'
  ) {
    this.role = initialRole;
    this.setupTransport();
  }

  private setupTransport(): void {
    this.transport.onMessage(msg => {
      if (msg.type === 'CYCLE_RESULT' || msg.type === 'CYCLE_START') {
        if ('state' in msg && msg.state) {
          this.state = msg.state;
          this.notifyState();
        }
      }
    });

    // Invia HELLO all'Host
    this.transport.send({
      type: 'HELLO',
      playerId: this.playerId,
      name: `Postazione ${this.role.toUpperCase()}`,
      version: 1,
    });
  }

  public setRole(role: Role): void {
    this.role = role;
  }

  public getRole(): Role {
    return this.role;
  }

  public sendAction(action: PlayerAction): void {
    this.transport.send({
      type: 'ACTION',
      playerId: this.playerId,
      cycleIndex: this.state?.cycleIndex || 1,
      action,
    });
  }

  public onStateUpdate(cb: (state: GameState) => void): () => void {
    this.onStateUpdateCallbacks.push(cb);
    if (this.state) cb(this.state);
    return () => {
      this.onStateUpdateCallbacks = this.onStateUpdateCallbacks.filter(c => c !== cb);
    };
  }

  private notifyState(): void {
    if (this.state) {
      this.onStateUpdateCallbacks.forEach(cb => cb(this.state!));
    }
  }
}
