import { Transport } from './Transport';
import { NetworkMessage } from '../protocol/types';

// UUID dedicati a ECHO-9 per il Bluetooth Low Energy GATT
export const ECHO9_BLE_CONFIG = {
  SERVICE_UUID: '6E400001-B5A3-F393-E0A9-E50E24DCCA9E',
  CHAR_HOST_NOTIFY: '6E400002-B5A3-F393-E0A9-E50E24DCCA9E', // Host -> Client
  CHAR_CLIENT_WRITE: '6E400003-B5A3-F393-E0A9-E50E24DCCA9E', // Client -> Host
};

export class BleTransport implements Transport {
  private connected: boolean = false;
  private messageCallbacks: ((msg: NetworkMessage) => void)[] = [];

  constructor(
    private isHost: boolean = false,
    private deviceId?: string
  ) {}

  send(message: NetworkMessage): void {
    if (!this.connected) {
      console.warn('[BLE Transport] Invio ignorato: dispositivo non connesso.');
      return;
    }
    // Codifica del messaggio binario/JSON (< 100 byte per MTU BLE standard)
    const payload = JSON.stringify(message);
    console.log(`[BLE Transport ${this.isHost ? 'HOST' : 'CLIENT'}] Invio payload:`, payload);
  }

  onMessage(callback: (message: NetworkMessage) => void): () => void {
    this.messageCallbacks.push(callback);
    return () => {
      this.messageCallbacks = this.messageCallbacks.filter(c => c !== callback);
    };
  }

  disconnect(): void {
    this.connected = false;
    this.messageCallbacks = [];
  }

  isConnected(): boolean {
    return this.connected;
  }
}
