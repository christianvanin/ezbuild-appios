import { Transport } from './Transport';
import { NetworkMessage } from '../protocol/types';

type MessageListener = (msg: NetworkMessage) => void;

class MessageBus {
  private listeners: Set<MessageListener> = new Set();

  subscribe(listener: MessageListener): () => void {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  broadcast(sender: LoopbackTransport, message: NetworkMessage): void {
    this.listeners.forEach(listener => {
      // Esegui in un microtask per simulare l'asincronia di rete
      setTimeout(() => {
        listener(message);
      }, 10);
    });
  }

  clear(): void {
    this.listeners.clear();
  }
}

export const sharedLoopbackBus = new MessageBus();

export class LoopbackTransport implements Transport {
  private connected: boolean = true;
  private unsubscribers: (() => void)[] = [];

  constructor(private bus: MessageBus = sharedLoopbackBus) {}

  send(message: NetworkMessage): void {
    if (!this.connected) return;
    this.bus.broadcast(this, message);
  }

  onMessage(callback: (message: NetworkMessage) => void): () => void {
    const unsub = this.bus.subscribe(callback);
    this.unsubscribers.push(unsub);
    return unsub;
  }

  disconnect(): void {
    this.connected = false;
    this.unsubscribers.forEach(u => u());
    this.unsubscribers = [];
  }

  isConnected(): boolean {
    return this.connected;
  }
}
