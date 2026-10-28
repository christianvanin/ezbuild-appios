import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Colors } from '../theme/colors';
import { GameState, Role } from '../../net/protocol/types';

interface SubmarineHeaderProps {
  state: GameState;
  activeRole: Role;
}

export const SubmarineHeader: React.FC<SubmarineHeaderProps> = ({ state, activeRole }) => {
  const roleColor = Colors.roles[activeRole];
  const phaseSeconds = Math.ceil(state.phaseTimeRemainingMs / 1000);
  
  // Nome fase in italiano
  const phaseLabel = 
    state.phase === 'detection' ? 'RILEVAMENTO' :
    state.phase === 'planning' ? 'PIANIFICAZIONE' : 'RISOLUZIONE';

  const phaseColor = 
    state.phase === 'detection' ? Colors.sonarTeal :
    state.phase === 'planning' ? Colors.warningAmber : Colors.dangerRed;

  return (
    <View style={styles.container}>
      {/* Barra Info Settore & Ciclo */}
      <View style={styles.topRow}>
        <View style={styles.sectorBadge}>
          <Text style={styles.sectorText}>
            SETTORE {state.sector}/{state.maxSectors} · CICLO {state.cycleIndex}/{state.maxCyclesPerSector}
          </Text>
        </View>
        <View style={[styles.roleBadge, { borderColor: roleColor, backgroundColor: `${roleColor}22` }]}>
          <Text style={[styles.roleText, { color: roleColor }]}>
            POSTAZIONE {activeRole.toUpperCase()}
          </Text>
        </View>
      </View>

      {/* Timer Centrale del Ciclo */}
      <View style={styles.timerRow}>
        <View style={[styles.phaseIndicator, { borderColor: phaseColor }]}>
          <Text style={[styles.phaseTitle, { color: phaseColor }]}>FASE: {phaseLabel}</Text>
          <Text style={[styles.timerNumber, { color: phaseColor }]}>{phaseSeconds}s</Text>
        </View>
      </View>

      {/* Risorse Condivise: Scafo & Energia */}
      <View style={styles.resourcesRow}>
        {/* Scafo (6 Punti Vita) */}
        <View style={styles.resourceBlock}>
          <Text style={styles.resourceLabel}>SCAFO ({state.hull}/{state.maxHull})</Text>
          <View style={styles.pipsRow}>
            {Array.from({ length: state.maxHull }).map((_, i) => (
              <View
                key={`hull_${i}`}
                style={[
                  styles.pip,
                  {
                    backgroundColor: i < state.hull 
                      ? (state.hull <= 2 ? Colors.dangerRed : Colors.hullGreen) 
                      : '#1C313E',
                    borderColor: i < state.hull ? Colors.gridBright : '#1C313E'
                  }
                ]}
              />
            ))}
          </View>
        </View>

        {/* Punti Squadra */}
        <View style={styles.scoreBlock}>
          <Text style={styles.resourceLabel}>PUNTEGGIO</Text>
          <Text style={styles.scoreValue}>{state.score} PTS</Text>
        </View>

        {/* Scudo Attivo */}
        {state.shieldActive && (
          <View style={styles.shieldBadge}>
            <Text style={styles.shieldText}>🛡️ SCUDO ATTIVO</Text>
          </View>
        )}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: Colors.panelDark,
    paddingTop: 10,
    paddingBottom: 12,
    paddingHorizontal: 16,
    borderBottomWidth: 2,
    borderBottomColor: Colors.grid,
  },
  topRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  sectorBadge: {
    backgroundColor: Colors.panel,
    paddingVertical: 4,
    paddingHorizontal: 8,
    borderRadius: 4,
    borderWidth: 1,
    borderColor: Colors.grid,
  },
  sectorText: {
    color: Colors.textDim,
    fontSize: 11,
    fontWeight: 'bold',
    letterSpacing: 0.5,
  },
  roleBadge: {
    paddingVertical: 4,
    paddingHorizontal: 10,
    borderRadius: 4,
    borderWidth: 1,
  },
  roleText: {
    fontSize: 11,
    fontWeight: '900',
    letterSpacing: 1,
  },
  timerRow: {
    alignItems: 'center',
    marginVertical: 4,
  },
  phaseIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    width: '100%',
    backgroundColor: Colors.panel,
    paddingVertical: 6,
    paddingHorizontal: 12,
    borderRadius: 6,
    borderWidth: 1,
  },
  phaseTitle: {
    fontSize: 12,
    fontWeight: 'bold',
    letterSpacing: 1,
  },
  timerNumber: {
    fontSize: 18,
    fontWeight: '900',
    fontVariant: ['tabular-nums'],
  },
  resourcesRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: 8,
  },
  resourceBlock: {
    flex: 1,
  },
  resourceLabel: {
    color: Colors.textDim,
    fontSize: 10,
    fontWeight: '700',
    marginBottom: 4,
    letterSpacing: 0.5,
  },
  pipsRow: {
    flexDirection: 'row',
    gap: 4,
  },
  pip: {
    width: 14,
    height: 10,
    borderRadius: 2,
    borderWidth: 1,
  },
  scoreBlock: {
    alignItems: 'flex-end',
    marginLeft: 12,
  },
  scoreValue: {
    color: Colors.sonarTeal,
    fontSize: 14,
    fontWeight: 'bold',
  },
  shieldBadge: {
    marginLeft: 12,
    backgroundColor: 'rgba(0, 240, 255, 0.15)',
    borderColor: Colors.shieldCyan,
    borderWidth: 1,
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  shieldText: {
    color: Colors.shieldCyan,
    fontSize: 10,
    fontWeight: 'bold',
  },
});
