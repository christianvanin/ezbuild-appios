import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { Colors } from '../theme/colors';
import { GameState, SystemEnergy, SystemHeat } from '../../net/protocol/types';

interface EngineerConsoleProps {
  state: GameState;
  onSetEnergy: (system: keyof SystemEnergy, delta: number) => void;
  onCoolDown: (system: keyof SystemHeat) => void;
}

export const EngineerConsole: React.FC<EngineerConsoleProps> = ({ state, onSetEnergy, onCoolDown }) => {
  const currentTotalEnergy = state.energy.engine + state.energy.sonar + state.energy.weapons;
  const availableEnergy = state.maxTotalEnergy - currentTotalEnergy;

  const systems: { key: keyof SystemEnergy; name: string; icon: string; desc: string }[] = [
    { key: 'engine', name: 'MOTORE & PROPULSIONE', icon: '⚙️', desc: 'Permette al Pilota di manovrare e cambiare velocità' },
    { key: 'sonar', name: 'SONAR ACUSTICO', icon: '📡', desc: 'Necessario per emettere Ping e identificare minacce' },
    { key: 'weapons', name: 'SISTEMA D\'ARMI & SCUDO', icon: '🎯', desc: 'Alimenta siluri e barriera protettiva dell\'Armiere' },
  ];

  return (
    <ScrollView style={styles.container} contentContainerStyle={{ paddingBottom: 24 }}>
      {/* Quadro Reattore Nucleare */}
      <View style={styles.reactorCard}>
        <View style={styles.reactorHeader}>
          <Text style={styles.reactorTitle}>QUADRO DISTRIBUZIONE REATTORE</Text>
          <Text style={styles.reactorStatus}>
            TOTALE: {currentTotalEnergy}/{state.maxTotalEnergy} UNITÀ
          </Text>
        </View>

        <View style={styles.reactorBody}>
          <View style={styles.energyMeterRow}>
            <Text style={styles.energyMeterLabel}>CELLE DI ENERGIA DISPONIBILI:</Text>
            <View style={styles.energyCells}>
              {Array.from({ length: state.maxTotalEnergy }).map((_, i) => (
                <View
                  key={`cell_${i}`}
                  style={[
                    styles.energyCell,
                    {
                      backgroundColor: i < currentTotalEnergy ? Colors.roles.engineer : '#152530',
                      borderColor: i < currentTotalEnergy ? Colors.warningAmber : Colors.grid,
                    }
                  ]}
                />
              ))}
            </View>
          </View>
          {availableEnergy > 0 ? (
            <Text style={styles.availableNotice}>
              ⚡ Hai {availableEnergy} unità di energia ancora da assegnare!
            </Text>
          ) : (
            <Text style={styles.fullNotice}>
              Tutta l'energia è allocata. Riduci un sistema per potenziarne un altro.
            </Text>
          )}
        </View>
      </View>

      {/* Regolazione Singoli Sistemi */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>SISTEMI PRINCIPALI DEL SOTTOMARINO</Text>

        {systems.map(sys => {
          const energyVal = state.energy[sys.key];
          const heatVal = state.heat[sys.key] || 0;
          const isOverheated = energyVal >= 4 || heatVal >= 2;

          return (
            <View 
              key={`sys_${sys.key}`} 
              style={[
                styles.systemCard,
                isOverheated && styles.systemCardWarning
              ]}
            >
              <View style={styles.systemHeader}>
                <View style={styles.systemTitleRow}>
                  <Text style={styles.systemIcon}>{sys.icon}</Text>
                  <Text style={styles.systemName}>{sys.name}</Text>
                </View>
                {isOverheated && (
                  <View style={styles.heatBadge}>
                    <Text style={styles.heatBadgeText}>⚠️ SURRISCALDAMENTO!</Text>
                  </View>
                )}
              </View>

              <Text style={styles.systemDesc}>{sys.desc}</Text>

              {/* Indicatore Calore */}
              <View style={styles.heatMeterRow}>
                <Text style={styles.heatMeterLabel}>TEMPERATURA CIRCUITI:</Text>
                <View style={styles.heatBars}>
                  {Array.from({ length: 4 }).map((_, h) => (
                    <View
                      key={`heat_${sys.key}_${h}`}
                      style={[
                        styles.heatBar,
                        {
                          backgroundColor: h < (energyVal >= 4 ? 3 : heatVal) 
                            ? (h >= 2 ? Colors.dangerRed : Colors.warningAmber) 
                            : '#1C313E'
                        }
                      ]}
                    />
                  ))}
                </View>
              </View>

              {/* Controlli Stepper + e - */}
              <View style={styles.controlsRow}>
                <TouchableOpacity
                  style={[styles.stepperButton, energyVal <= 0 && styles.stepperButtonDisabled]}
                  onPress={() => onSetEnergy(sys.key, -1)}
                  disabled={energyVal <= 0}
                  activeOpacity={0.7}
                >
                  <Text style={styles.stepperButtonText}>−</Text>
                </TouchableOpacity>

                <View style={styles.valueDisplay}>
                  <Text style={styles.valueText}>{energyVal}</Text>
                  <Text style={styles.valueSub}>UNITÀ</Text>
                </View>

                <TouchableOpacity
                  style={[styles.stepperButton, (availableEnergy <= 0 || energyVal >= 6) && styles.stepperButtonDisabled]}
                  onPress={() => onSetEnergy(sys.key, 1)}
                  disabled={availableEnergy <= 0 || energyVal >= 6}
                  activeOpacity={0.7}
                >
                  <Text style={styles.stepperButtonText}>+</Text>
                </TouchableOpacity>

                {/* Sfiato Calore d'Emergenza */}
                {isOverheated && (
                  <TouchableOpacity
                    style={styles.ventButton}
                    onPress={() => onCoolDown(sys.key)}
                    activeOpacity={0.7}
                  >
                    <Text style={styles.ventButtonText}>❄️ SFIATA</Text>
                  </TouchableOpacity>
                )}
              </View>
            </View>
          );
        })}
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
  },
  reactorCard: {
    backgroundColor: Colors.panel,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: Colors.gridBright,
    overflow: 'hidden',
    marginBottom: 16,
  },
  reactorHeader: {
    backgroundColor: Colors.panelDark,
    paddingVertical: 8,
    paddingHorizontal: 12,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderBottomWidth: 1,
    borderBottomColor: Colors.grid,
  },
  reactorTitle: {
    color: Colors.roles.engineer,
    fontSize: 11,
    fontWeight: 'bold',
    letterSpacing: 1,
  },
  reactorStatus: {
    color: Colors.text,
    fontSize: 11,
    fontWeight: 'bold',
  },
  reactorBody: {
    padding: 14,
  },
  energyMeterRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  energyMeterLabel: {
    color: Colors.textDim,
    fontSize: 11,
    fontWeight: 'bold',
  },
  energyCells: {
    flexDirection: 'row',
    gap: 6,
  },
  energyCell: {
    width: 22,
    height: 16,
    borderRadius: 3,
    borderWidth: 1,
  },
  availableNotice: {
    color: Colors.roles.engineer,
    fontSize: 11,
    fontWeight: 'bold',
    marginTop: 4,
  },
  fullNotice: {
    color: Colors.textDim,
    fontSize: 11,
    fontStyle: 'italic',
    marginTop: 4,
  },
  section: {
    marginBottom: 16,
  },
  sectionTitle: {
    color: Colors.roles.engineer,
    fontSize: 12,
    fontWeight: 'bold',
    letterSpacing: 0.5,
    marginBottom: 10,
  },
  systemCard: {
    backgroundColor: Colors.panel,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: Colors.grid,
    padding: 14,
    marginBottom: 12,
  },
  systemCardWarning: {
    borderColor: Colors.warningAmber,
    backgroundColor: 'rgba(255, 184, 77, 0.08)',
  },
  systemHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 6,
  },
  systemTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  systemIcon: {
    fontSize: 16,
    marginRight: 8,
  },
  systemName: {
    color: Colors.text,
    fontSize: 13,
    fontWeight: 'bold',
  },
  heatBadge: {
    backgroundColor: 'rgba(255, 184, 77, 0.2)',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 4,
    borderWidth: 1,
    borderColor: Colors.warningAmber,
  },
  heatBadgeText: {
    color: Colors.warningAmber,
    fontSize: 10,
    fontWeight: '900',
  },
  systemDesc: {
    color: Colors.textDim,
    fontSize: 11,
    marginBottom: 10,
    lineHeight: 15,
  },
  heatMeterRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 12,
    backgroundColor: Colors.panelDark,
    paddingVertical: 6,
    paddingHorizontal: 10,
    borderRadius: 6,
  },
  heatMeterLabel: {
    color: Colors.textDim,
    fontSize: 10,
    fontWeight: 'bold',
  },
  heatBars: {
    flexDirection: 'row',
    gap: 4,
  },
  heatBar: {
    width: 16,
    height: 8,
    borderRadius: 2,
  },
  controlsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  stepperButton: {
    width: 56,
    height: 56,
    backgroundColor: Colors.panelDark,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: Colors.roles.engineer,
    justifyContent: 'center',
    alignItems: 'center',
  },
  stepperButtonDisabled: {
    borderColor: Colors.grid,
    opacity: 0.3,
  },
  stepperButtonText: {
    color: Colors.roles.engineer,
    fontSize: 26,
    fontWeight: 'bold',
    lineHeight: 30,
  },
  valueDisplay: {
    flex: 1,
    alignItems: 'center',
    backgroundColor: Colors.panelDark,
    paddingVertical: 8,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: Colors.grid,
  },
  valueText: {
    color: Colors.text,
    fontSize: 22,
    fontWeight: '900',
  },
  valueSub: {
    color: Colors.textDim,
    fontSize: 9,
    fontWeight: 'bold',
  },
  ventButton: {
    backgroundColor: 'rgba(0, 240, 255, 0.2)',
    borderWidth: 1,
    borderColor: Colors.shieldCyan,
    paddingHorizontal: 14,
    height: 56,
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
  },
  ventButtonText: {
    color: Colors.shieldCyan,
    fontSize: 11,
    fontWeight: 'bold',
  },
});
