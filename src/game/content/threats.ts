import { Threat, ThreatType, Lane } from '../../net/protocol/types';

export const SONAR_SYMBOLS = ['Δ', 'Ω', 'Ψ', 'Σ', 'Φ', 'Θ', 'Λ', 'Ξ'];

export function generateRandomCode(): string {
  const s1 = SONAR_SYMBOLS[Math.floor(Math.random() * SONAR_SYMBOLS.length)];
  const s2 = SONAR_SYMBOLS[Math.floor(Math.random() * SONAR_SYMBOLS.length)];
  const s3 = SONAR_SYMBOLS[Math.floor(Math.random() * SONAR_SYMBOLS.length)];
  return `${s1}-${s2}-${s3}`;
}

export function generateThreatsForCycle(sector: number, cycleIndex: number): Threat[] {
  const threats: Threat[] = [];
  const randomLane = (): Lane => Math.floor(Math.random() * 3) as Lane;
  
  // Settore 5: Boss Titano delle Profondità negli ultimi 3 cicli
  if (sector === 5 && cycleIndex >= 4) {
    threats.push({
      id: `titan_${cycleIndex}`,
      type: 'titan',
      name: 'Titano degli Abissi',
      lanes: [0, 1, 2],
      distanceCycles: 1,
      code: generateRandomCode(),
      revealed: false,
    });
    // Aggiungi anche una mina o corrente a sorpresa
    threats.push({
      id: `mine_titan_${cycleIndex}`,
      type: 'mine',
      name: 'Mina Abissale',
      lanes: [randomLane()],
      distanceCycles: 1,
      code: generateRandomCode(),
      revealed: false,
    });
    return threats;
  }

  // Regole procedurali basate sul settore (da 1 a 5)
  // Più alto è il settore, più minacce compaiono
  const threatCount = sector === 1 ? (cycleIndex % 2 === 0 ? 1 : 0) : Math.min(3, Math.floor(sector / 2) + (cycleIndex % 2 === 0 ? 1 : 0));
  
  const pool: ThreatType[] = ['mine', 'current'];
  if (sector >= 2) pool.push('reef');
  if (sector >= 3) pool.push('short_circuit', 'wreck');
  if (sector >= 4) pool.push('leviathan');

  for (let i = 0; i < threatCount; i++) {
    const type = pool[Math.floor(Math.random() * pool.length)];
    const id = `thr_${sector}_${cycleIndex}_${i}_${Date.now() % 10000}`;
    
    switch (type) {
      case 'mine':
        threats.push({
          id,
          type: 'mine',
          name: 'Mina Galleggiante',
          lanes: [randomLane()],
          distanceCycles: 1,
          code: generateRandomCode(),
          revealed: false,
        });
        break;
      case 'current': {
        const dir = Math.random() > 0.5 ? 1 : -1;
        threats.push({
          id,
          type: 'current',
          name: dir === 1 ? 'Corrente Verso Destra' : 'Corrente Verso Sinistra',
          lanes: [0, 1, 2],
          currentDirection: dir,
          distanceCycles: 1,
          code: generateRandomCode(),
          revealed: false,
        });
        break;
      }
      case 'reef': {
        // Occupa 2 corsie su 3
        const freeLane = randomLane();
        const occupiedLanes = ([0, 1, 2] as Lane[]).filter(l => l !== freeLane);
        threats.push({
          id,
          type: 'reef',
          name: 'Banco di Rocce',
          lanes: occupiedLanes,
          distanceCycles: 1,
          code: generateRandomCode(),
          revealed: false,
        });
        break;
      }
      case 'leviathan':
        threats.push({
          id,
          type: 'leviathan',
          name: 'Leviatano Silente',
          lanes: [0, 1, 2],
          distanceCycles: 1,
          code: generateRandomCode(),
          revealed: false,
        });
        break;
      case 'short_circuit':
        threats.push({
          id,
          type: 'short_circuit',
          name: 'Sovraccarico Impianto',
          lanes: [],
          distanceCycles: 1,
          code: generateRandomCode(),
          revealed: true,
        });
        break;
      case 'wreck':
        threats.push({
          id,
          type: 'wreck',
          name: 'Relitto Sommerso (Bonus)',
          lanes: [randomLane()],
          distanceCycles: 1,
          code: generateRandomCode(),
          revealed: false,
        });
        break;
    }
  }

  return threats;
}

export interface UpgradeCard {
  id: string;
  name: string;
  description: string;
  icon: string;
}

export const UPGRADE_CARDS: UpgradeCard[] = [
  { id: 'free_ping', name: 'Ping Potenziato', description: 'Il primo Ping di ogni ciclo non consuma energia del Sonar.', icon: '📡' },
  { id: 'reinforced_shield', name: 'Scudo Corazzato', description: 'Lo scudo dell\'Armiere assorbe fino a 2 impatti per ciclo.', icon: '🛡️' },
  { id: 'rapid_cooling', name: 'Raffreddamento Rapido', description: 'I sistemi surriscaldati dissipano il calore istantaneamente.', icon: '❄️' },
  { id: 'extra_energy', name: 'Cella Ausiliaria', description: '+1 punto energia totale disponibile in ogni ciclo (7 invece di 6).', icon: '⚡' },
];
