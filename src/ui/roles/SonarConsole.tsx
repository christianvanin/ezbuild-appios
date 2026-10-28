import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { Colors } from '../theme/colors';
import { GameState, Threat, Lane } from '../../net/protocol/types';

interface SonarConsoleProps {
  state: GameState;
  onPing: (threatId: string) => void;
}

export const SonarConsole: React.FC<SonarConsoleProps> = ({ state, onPing }) => {
  const [sweepAngle, setSweepAngle] = useState(0);

  // Animazione rotazione sweep radar (simulata)
  useEffect(() => {
    const interval = setInterval(() => {
      setSweepAngle(prev => (prev + 15) % 360);
    }, 100);
    return () => clearInterval(interval);
  }, []);

  const hasSonarEnergy = state.energy.sonar >= 1;
  const laneNames = ['SINISTRA', 'CENTRO', 'DESTRA'];

  return (
    <ScrollView style={styles.container} contentContainerStyle={{ paddingBottom: 24 }}>
      {/* Radar Circolare Tattico */}
      <View style={styles.radarCard}>
        <View style={styles.radarHeader}>
          <Text style={styles.radarTitle}>RADAR ACUSTICO CIRCOLARE · 360°</Text>
          <Text style={[styles.energyStatus, { color: hasSonarEnergy ? Colors.roles.sonar : Colors.dangerRed }]}>
            ENERGIA SONAR: {state.energy.sonar} / 6
          </Text>
        </View>

        <View style={styles.radarScreen}>
          {/* Cerchi concentrici di distanza */}
          <View style={[styles.radarCircle, { width: 220, height: 220 }]} />
          <View style={[styles.radarCircle, { width: 150, height: 150 }]} />
          <View style={[styles.radarCircle, { width: 80, height: 80 }]} />
          
          {/* Linee di griglia settori */}
          <View style={styles.gridLineH} />
          <View style={styles.gridLineV} />
          <View style={styles.gridLineDiag1} />
          <View style={styles.gridLineDiag2} />

          {/* Sottomarino al centro */}
          <View style={styles.submarineCenter}>
            <View style={styles.subDot} />
            <Text style={styles.subLabel}>ECHO-9</Text>
          </View>

          {/* Sweep Raggio Radar */}
          <View 
            style={[
              styles.sweepRay,
              { transform: [{ rotate: `${sweepAngle}deg` }] }
            ]} 
          />

          {/* Blip delle Minacce rilevate nel radar */}
          {state.threats.map((threat, index) => {
            // Calcola posizione visiva in base alla corsia e distanza
            const laneOffset = threat.lanes.includes(0) ? -60 : threat.lanes.includes(2) ? 60 : 0;
            const distOffset = threat.distanceCycles === 1 ? -55 : -90;

            return (
              <View
                key={`blip_${threat.id}_${index}`}
                style={[
                  styles.threatBlip,
                  {
                    left: 110 + laneOffset - 12,
                    top: 110 + distOffset - 12,
                    borderColor: threat.revealed ? Colors.warningAmber : Colors.roles.sonar,
                    backgroundColor: threat.revealed ? 'rgba(255, 184, 77, 0.4)' : 'rgba(61, 220, 132, 0.3)',
                  }
                ]}
              >
                <Text style={styles.blipIcon}>
                  {threat.type === 'mine' ? '💣' : threat.type === 'reef' ? '🪨' : threat.type === 'leviathan' ? '🐉' : '⚠️'}
                </Text>
              </View>
            );
          })}
        </View>
      </View>

      {/* Pulsante Emissione PING Sonar */}
      <View style={styles.pingSection}>
        <TouchableOpacity
          style={[
            styles.pingButton,
            !hasSonarEnergy && styles.pingButtonDisabled
          ]}
          onPress={() => onPing('all')}
          disabled={!hasSonarEnergy}
          activeOpacity={0.7}
        >
          <Text style={styles.pingIcon}>📡</Text>
          <View style={styles.pingTextCol}>
            <Text style={styles.pingButtonTitle}>EMETTI IMPULSO PING</Text>
            <Text style={styles.pingButtonSub}>
              {hasSonarEnergy 
                ? 'Rivela codici siluri e tipologia esatta minacce' 
                : 'ENERGIA INSUFFICIENTE: Chiedi all\'Ingegnere +1 al Sonar!'}
            </Text>
          </View>
        </TouchableOpacity>
      </View>

      {/* Registro Minacce e Codici Rivelati (Font > 32 pt) */}
      <View style={styles.logSection}>
        <Text style={styles.logTitle}>REGISTRO TELEMETRIA & CODICI SILURO</Text>
        <Text style={styles.logHint}>
          COMUNICA QUESTI CODICI A VOCE ALL'ARMIERE PER COLPIRE!
        </Text>

        {state.threats.length === 0 ? (
          <View style={styles.emptyCard}>
            <Text style={styles.emptyText}>Settore pulito: nessuna minaccia acustica rilevata.</Text>
          </View>
        ) : (
          state.threats.map(threat => (
            <View key={`card_${threat.id}`} style={styles.threatCard}>
              <View style={styles.threatCardHeader}>
                <Text style={styles.threatName}>
                  {threat.revealed ? threat.name.toUpperCase() : 'CONTATTO NON IDENTIFICATO'}
                </Text>
                <View style={styles.laneBadge}>
                  <Text style={styles.laneBadgeText}>
                    CORSIA {threat.lanes.map(l => laneNames[l]).join(' + ')}
                  </Text>
                </View>
              </View>

              {threat.revealed ? (
                <View style={styles.codeRevealBox}>
                  <Text style={styles.codeLabel}>CODICE SILURO RICHIESTO:</Text>
                  <Text style={styles.codeText}>{threat.code}</Text>
                  <Text style={styles.speakAloudNotice}>📢 DILLO ALL'ARMIERE AD ALTA VOCE!</Text>
                </View>
              ) : (
                <View style={styles.unrevealedBox}>
                  <Text style={styles.unrevealedText}>
                    Codice criptato nella scia acustica. Premi "EMETTI PING" per rivelarlo.
                  </Text>
                </View>
              )}
            </View>
          ))
        )}
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
  },
  radarCard: {
    backgroundColor: Colors.panel,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: Colors.gridBright,
    overflow: 'hidden',
    marginBottom: 16,
  },
  radarHeader: {
    backgroundColor: Colors.panelDark,
    paddingVertical: 8,
    paddingHorizontal: 12,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderBottomWidth: 1,
    borderBottomColor: Colors.grid,
  },
  radarTitle: {
    color: Colors.roles.sonar,
    fontSize: 11,
    fontWeight: 'bold',
    letterSpacing: 1,
  },
  energyStatus: {
    fontSize: 11,
    fontWeight: 'bold',
  },
  radarScreen: {
    height: 230,
    backgroundColor: '#041017',
    position: 'relative',
    justifyContent: 'center',
    alignItems: 'center',
  },
  radarCircle: {
    position: 'absolute',
    borderRadius: 150,
    borderWidth: 1,
    borderColor: 'rgba(61, 220, 132, 0.2)',
  },
  gridLineH: {
    position: 'absolute',
    width: '100%',
    height: 1,
    backgroundColor: 'rgba(61, 220, 132, 0.15)',
  },
  gridLineV: {
    position: 'absolute',
    height: '100%',
    width: 1,
    backgroundColor: 'rgba(61, 220, 132, 0.15)',
  },
  gridLineDiag1: {
    position: 'absolute',
    width: '100%',
    height: 1,
    backgroundColor: 'rgba(61, 220, 132, 0.08)',
    transform: [{ rotate: '45deg' }],
  },
  gridLineDiag2: {
    position: 'absolute',
    width: '100%',
    height: 1,
    backgroundColor: 'rgba(61, 220, 132, 0.08)',
    transform: [{ rotate: '-45deg' }],
  },
  submarineCenter: {
    position: 'absolute',
    alignItems: 'center',
    zIndex: 10,
  },
  subDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: Colors.roles.sonar,
    borderWidth: 2,
    borderColor: '#fff',
  },
  subLabel: {
    color: Colors.roles.sonar,
    fontSize: 9,
    fontWeight: '900',
    marginTop: 2,
  },
  sweepRay: {
    position: 'absolute',
    width: 110,
    height: 2,
    backgroundColor: Colors.roles.sonar,
    top: 114,
    left: 110,
    transformOrigin: 'left center',
    opacity: 0.8,
  },
  threatBlip: {
    position: 'absolute',
    width: 24,
    height: 24,
    borderRadius: 12,
    borderWidth: 1,
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 20,
  },
  blipIcon: {
    fontSize: 12,
  },
  pingSection: {
    marginBottom: 16,
  },
  pingButton: {
    minHeight: 58,
    backgroundColor: 'rgba(61, 220, 132, 0.15)',
    borderWidth: 2,
    borderColor: Colors.roles.sonar,
    borderRadius: 10,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
  pingButtonDisabled: {
    opacity: 0.4,
    borderColor: Colors.grid,
    backgroundColor: Colors.panel,
  },
  pingIcon: {
    fontSize: 26,
    marginRight: 14,
  },
  pingTextCol: {
    flex: 1,
  },
  pingButtonTitle: {
    color: Colors.roles.sonar,
    fontSize: 14,
    fontWeight: 'bold',
    letterSpacing: 0.5,
  },
  pingButtonSub: {
    color: Colors.textDim,
    fontSize: 11,
    marginTop: 2,
  },
  logSection: {
    marginBottom: 16,
  },
  logTitle: {
    color: Colors.roles.sonar,
    fontSize: 12,
    fontWeight: 'bold',
    letterSpacing: 0.5,
    marginBottom: 4,
  },
  logHint: {
    color: Colors.textDim,
    fontSize: 10,
    marginBottom: 10,
    fontWeight: '600',
  },
  emptyCard: {
    backgroundColor: Colors.panel,
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: Colors.grid,
  },
  emptyText: {
    color: Colors.textDim,
    fontSize: 12,
    fontStyle: 'italic',
  },
  threatCard: {
    backgroundColor: Colors.panel,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: Colors.grid,
    padding: 12,
    marginBottom: 10,
  },
  threatCardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  threatName: {
    color: Colors.text,
    fontSize: 12,
    fontWeight: 'bold',
  },
  laneBadge: {
    backgroundColor: Colors.panelDark,
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 4,
    borderWidth: 1,
    borderColor: Colors.grid,
  },
  laneBadgeText: {
    color: Colors.warningAmber,
    fontSize: 10,
    fontWeight: 'bold',
  },
  codeRevealBox: {
    backgroundColor: '#04141D',
    borderRadius: 6,
    padding: 12,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: Colors.roles.sonar,
  },
  codeLabel: {
    color: Colors.textDim,
    fontSize: 11,
    fontWeight: '600',
    marginBottom: 4,
  },
  codeText: {
    color: Colors.roles.sonar,
    fontSize: 34,
    fontWeight: '900',
    letterSpacing: 6,
    fontVariant: ['tabular-nums'],
    marginVertical: 4,
  },
  speakAloudNotice: {
    color: Colors.warningAmber,
    fontSize: 10,
    fontWeight: 'bold',
    marginTop: 2,
  },
  unrevealedBox: {
    backgroundColor: Colors.panelDark,
    padding: 10,
    borderRadius: 6,
  },
  unrevealedText: {
    color: Colors.textDim,
    fontSize: 11,
    textAlign: 'center',
    fontStyle: 'italic',
  },
});
