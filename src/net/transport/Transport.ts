import { NetworkMessage } from '../protocol/types';

export interface Transport {
  send(message: NetworkMessage): void;
  onMessage(callback: (message: NetworkMessage) => void): () => void;
  disconnect(): void;
  isConnected(): boolean;
}
