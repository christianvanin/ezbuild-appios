import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { Colors } from '../theme/colors';
import { GameState, Lane, Speed } from '../../net/protocol/types';

interface PilotConsoleProps {
  state: GameState;
  onSetLane: (lane: Lane) => void;
  onSetSpeed: (speed: Speed) => void;
}

export const PilotConsole: React.FC<PilotConsoleProps> = ({ state, onSetLane, onSetSpeed }) => {
  const laneNames = ['SINISTRA', 'CENTRO', 'DESTRA'];
  const speeds: Speed[] = ['stop', 'slow', 'full'];
  const speedLabels: Record<Speed, string> = {
    stop: 'FERMA',
    slow: 'LENTA (1x)',
    full: 'PIENA (2x)'
  };

  const currentLaneThreats = state.threats.filter(t => t.lanes.includes(state.currentLane));

  return (
    <View style={styles.container}>
      {/* Visuale Frontale Immersione con Nebbia d'Abisso */}
      <View style={styles.viewport}>
        <View style={styles.viewportHeader}>
          <Text style={styles.viewportTitle}>VISUALE TIMONE · CORSIA ATTUALE</Text>
          <View style={styles.liveIndicator}>
            <View style={styles.liveDot} />
            <Text style={styles.liveText}>CORSIA {laneNames[state.currentLane]}</Text>
          </View>
        </View>

        {/* Simulazione Finestrino con Nebbia */}
        <View style={styles.fogWindow}>
          <View style={styles.crosshairH} />
          <View style={styles.crosshairV} />
          
          <View style={styles.depthLines}>
            <Text style={styles.depthText}>PROFONDITÀ: {(state.sector * 850) + (state.cycleIndex * 120)}m</Text>
            <Text style={styles.speedIndicator}>VELOCITÀ: {speedLabels[state.currentSpeed]}</Text>
          </View>

          {/* Rilevamento locale limitato nella nebbia */}
          {currentLaneThreats.length > 0 ? (
            <View style={styles.fogAlert}>
              <Text style={styles.fogAlertText}>⚠️ SAGOME NELLA NEBBIA RILEVATE IN CORSIA!</Text>
              <Text style={styles.fogSubText}>Richiedi analisi dettagliata alla postazione SONAR</Text>
            </View>
          ) : (
            <View style={styles.fogClear}>
              <Text style={styles.fogClearText}>Nessun ostacolo visibile direttamente a prua</Text>
            </View>
          )}
        </View>
      </View>

      {/* Controllo Timone: Scelta Corsia (Touch Targets >= 56 dp) */}
      <View style={styles.section}>
        <Text style={styles.sectionLabel}>CONTROLLO TIMONE (CORSIA SOTTOMARINO)</Text>
        <View style={styles.lanesRow}>
          {([0, 1, 2] as Lane[]).map(lane => {
            const isSelected = state.currentLane === lane;
            return (
              <TouchableOpacity
                key={`lane_${lane}`}
                style={[
                  styles.laneButton,
                  isSelected && styles.laneButtonActive
                ]}
                onPress={() => onSetLane(lane)}
                activeOpacity={0.7}
              >
                <Text style={[styles.laneArrow, isSelected && styles.laneArrowActive]}>
                  {lane === 0 ? '◄' : lane === 1 ? '▲' : '►'}
                </Text>
                <Text style={[styles.laneButtonText, isSelected && styles.laneButtonTextActive]}>
                  {laneNames[lane]}
                </Text>
                {isSelected && <Text style={styles.currentTag}>IN ROTTA</Text>}
              </TouchableOpacity>
            );
          })}
        </View>
      </View>

      {/* Controllo Propulsione: Leva Velocità */}
      <View style={styles.section}>
        <Text style={styles.sectionLabel}>PROPULSIONE MOTORI (VELOCITÀ)</Text>
        <View style={styles.speedRow}>
          {speeds.map(sp => {
            const isSpeedSelected = state.currentSpeed === sp;
            return (
              <TouchableOpacity
                key={`speed_${sp}`}
                style={[
                  styles.speedButton,
                  isSpeedSelected && styles.speedButtonActive
                ]}
                onPress={() => onSetSpeed(sp)}
                activeOpacity={0.7}
              >
                <Text style={[styles.speedButtonText, isSpeedSelected && styles.speedButtonTextActive]}>
                  {speedLabels[sp]}
                </Text>
              </TouchableOpacity>
            );
          })}
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
  },
  viewport: {
    backgroundColor: Colors.panel,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: Colors.gridBright,
    overflow: 'hidden',
    marginBottom: 16,
  },
  viewportHeader: {
    backgroundColor: Colors.panelDark,
    paddingVertical: 8,
    paddingHorizontal: 12,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderBottomWidth: 1,
    borderBottomColor: Colors.grid,
  },
  viewportTitle: {
    color: Colors.roles.pilot,
    fontSize: 11,
    fontWeight: 'bold',
    letterSpacing: 1,
  },
  liveIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  liveDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: Colors.roles.pilot,
    marginRight: 6,
  },
  liveText: {
    color: Colors.text,
    fontSize: 11,
    fontWeight: 'bold',
  },
  fogWindow: {
    height: 140,
    backgroundColor: '#051119',
    position: 'relative',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 12,
  },
  crosshairH: {
    position: 'absolute',
    width: '100%',
    height: 1,
    backgroundColor: 'rgba(76, 201, 240, 0.15)',
  },
  crosshairV: {
    position: 'absolute',
    height: '100%',
    width: 1,
    backgroundColor: 'rgba(76, 201, 240, 0.15)',
  },
  depthLines: {
    position: 'absolute',
    top: 8,
    left: 12,
  },
  depthText: {
    color: Colors.textDim,
    fontSize: 10,
    fontVariant: ['tabular-nums'],
    letterSpacing: 0.5,
  },
  speedIndicator: {
    color: Colors.roles.pilot,
    fontSize: 10,
    fontWeight: 'bold',
  },
  fogAlert: {
    backgroundColor: 'rgba(255, 184, 77, 0.15)',
    borderWidth: 1,
    borderColor: Colors.warningAmber,
    paddingVertical: 8,
    paddingHorizontal: 14,
    borderRadius: 8,
    alignItems: 'center',
  },
  fogAlertText: {
    color: Colors.warningAmber,
    fontSize: 12,
    fontWeight: 'bold',
  },
  fogSubText: {
    color: Colors.textDim,
    fontSize: 10,
    marginTop: 2,
  },
  fogClear: {
    paddingVertical: 6,
    paddingHorizontal: 12,
  },
  fogClearText: {
    color: Colors.textDim,
    fontSize: 11,
    fontStyle: 'italic',
  },
  section: {
    marginBottom: 16,
  },
  sectionLabel: {
    color: Colors.textDim,
    fontSize: 11,
    fontWeight: 'bold',
    marginBottom: 8,
    letterSpacing: 0.5,
  },
  lanesRow: {
    flexDirection: 'row',
    gap: 8,
  },
  laneButton: {
    flex: 1,
    minHeight: 70,
    backgroundColor: Colors.panel,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: Colors.grid,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 10,
  },
  laneButtonActive: {
    backgroundColor: 'rgba(76, 201, 240, 0.2)',
    borderColor: Colors.roles.pilot,
    borderWidth: 2,
  },
  laneArrow: {
    color: Colors.textDim,
    fontSize: 18,
    marginBottom: 4,
  },
  laneArrowActive: {
    color: Colors.roles.pilot,
  },
  laneButtonText: {
    color: Colors.textDim,
    fontSize: 12,
    fontWeight: 'bold',
  },
  laneButtonTextActive: {
    color: Colors.text,
  },
  currentTag: {
    color: Colors.roles.pilot,
    fontSize: 9,
    fontWeight: '900',
    marginTop: 4,
    letterSpacing: 0.5,
  },
  speedRow: {
    flexDirection: 'row',
    gap: 8,
  },
  speedButton: {
    flex: 1,
    minHeight: 56,
    backgroundColor: Colors.panel,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: Colors.grid,
    justifyContent: 'center',
    alignItems: 'center',
  },
  speedButtonActive: {
    backgroundColor: 'rgba(76, 201, 240, 0.2)',
    borderColor: Colors.roles.pilot,
    borderWidth: 2,
  },
  speedButtonText: {
    color: Colors.textDim,
    fontSize: 12,
    fontWeight: 'bold',
  },
  speedButtonTextActive: {
    color: Colors.roles.pilot,
  },
});
