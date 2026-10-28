import React from 'react';
import { View, Text, StyleSheet, Modal, ScrollView, TouchableOpacity } from 'react-native';
import { Colors } from '../theme/colors';
import { GameState, ResolutionEvent } from '../../net/protocol/types';

interface ResolutionModalProps {
  visible: boolean;
  state: GameState;
  events: ResolutionEvent[];
  onDismiss?: () => void;
}

export const ResolutionModal: React.FC<ResolutionModalProps> = ({ visible, state, events }) => {
  if (!visible) return null;

  return (
    <View style={styles.overlay}>
      <View style={styles.card}>
        <View style={styles.cardHeader}>
          <Text style={styles.headerTitle}>ESITO DEL CICLO {state.cycleIndex - 1}</Text>
          <Text style={styles.headerSub}>SETTORE {state.sector} · PROFONDITÀ ABISSALE</Text>
        </View>

        <ScrollView style={styles.eventsList} contentContainerStyle={{ paddingVertical: 10 }}>
          {events.length === 0 ? (
            <View style={styles.eventItem}>
              <Text style={styles.eventTitle}>Tragitto Libero</Text>
              <Text style={styles.eventDesc}>Il sottomarino è sceso negli abissi senza incidenti.</Text>
            </View>
          ) : (
            events.map(ev => {
              const isDamage = ev.type === 'damage';
              const isDestroyed = ev.type === 'destroyed' || ev.type === 'avoided' || ev.type === 'bonus';
              const isWarning = ev.type === 'warning';

              const icon = 
                isDamage ? '💥' :
                ev.type === 'destroyed' ? '🎯' :
                ev.type === 'bonus' ? '⭐' :
                isWarning ? '⚠️' : '🛡️';

              const borderColor = 
                isDamage ? Colors.dangerRed :
                isWarning ? Colors.warningAmber :
                Colors.sonarTeal;

              return (
                <View key={ev.id} style={[styles.eventItem, { borderColor }]}>
                  <View style={styles.eventHeader}>
                    <Text style={styles.eventIcon}>{icon}</Text>
                    <Text style={[styles.eventTitle, { color: isDamage ? Colors.dangerRed : Colors.text }]}>
                      {ev.title}
                    </Text>
                  </View>
                  <Text style={styles.eventDesc}>{ev.description}</Text>
                  {ev.scoreChange > 0 && (
                    <Text style={styles.eventScore}>+{ev.scoreChange} Punti Squadra</Text>
                  )}
                  {ev.hullChange !== 0 && (
                    <Text style={[styles.eventHull, { color: ev.hullChange < 0 ? Colors.dangerRed : Colors.hullGreen }]}>
                      {ev.hullChange < 0 ? `${ev.hullChange} Scafo!` : `+${ev.hullChange} Scafo Riparato!`}
                    </Text>
                  )}
                </View>
              );
            })
          )}
        </ScrollView>

        <View style={styles.footer}>
          <Text style={styles.countdownText}>
            PROSSIMO CICLO IN ARRIVO... ({Math.ceil(state.phaseTimeRemainingMs / 1000)}s)
          </Text>
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  overlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(5, 17, 25, 0.92)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 16,
    zIndex: 1000,
  },
  card: {
    width: '100%',
    maxHeight: '80%',
    backgroundColor: Colors.panel,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: Colors.gridBright,
    overflow: 'hidden',
  },
  cardHeader: {
    backgroundColor: Colors.panelDark,
    padding: 14,
    borderBottomWidth: 1,
    borderBottomColor: Colors.grid,
    alignItems: 'center',
  },
  headerTitle: {
    color: Colors.sonarTeal,
    fontSize: 16,
    fontWeight: '900',
    letterSpacing: 1,
  },
  headerSub: {
    color: Colors.textDim,
    fontSize: 11,
    marginTop: 2,
  },
  eventsList: {
    paddingHorizontal: 14,
  },
  eventItem: {
    backgroundColor: Colors.panelDark,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: Colors.grid,
    padding: 12,
    marginBottom: 8,
  },
  eventHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4,
  },
  eventIcon: {
    fontSize: 16,
    marginRight: 8,
  },
  eventTitle: {
    fontSize: 13,
    fontWeight: 'bold',
  },
  eventDesc: {
    color: Colors.textDim,
    fontSize: 11,
    lineHeight: 16,
  },
  eventScore: {
    color: Colors.sonarTeal,
    fontSize: 11,
    fontWeight: 'bold',
    marginTop: 4,
  },
  eventHull: {
    fontSize: 11,
    fontWeight: 'bold',
    marginTop: 2,
  },
  footer: {
    backgroundColor: Colors.panelDark,
    padding: 12,
    alignItems: 'center',
    borderTopWidth: 1,
    borderTopColor: Colors.grid,
  },
  countdownText: {
    color: Colors.warningAmber,
    fontSize: 12,
    fontWeight: '900',
    letterSpacing: 0.5,
  },
});
