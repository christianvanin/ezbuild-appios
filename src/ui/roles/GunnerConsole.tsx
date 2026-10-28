import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { Colors } from '../theme/colors';
import { GameState, Lane } from '../../net/protocol/types';
import { SONAR_SYMBOLS } from '../../game/content/threats';

interface GunnerConsoleProps {
  state: GameState;
  onFireTorpedo: (code: string, lane: Lane) => void;
  onToggleShield: () => void;
}

export const GunnerConsole: React.FC<GunnerConsoleProps> = ({ state, onFireTorpedo, onToggleShield }) => {
  const [selectedLane, setSelectedLane] = useState<Lane>(1);
  const [enteredSymbols, setEnteredSymbols] = useState<string[]>([]);

  const laneNames = ['SINISTRA', 'CENTRO', 'DESTRA'];
  const hasWeaponsEnergy = state.energy.weapons >= 1;

  const handlePressSymbol = (symbol: string) => {
    if (enteredSymbols.length < 3) {
      setEnteredSymbols([...enteredSymbols, symbol]);
    }
  };

  const handleClearCode = () => {
    setEnteredSymbols([]);
  };

  const handleFire = () => {
    if (enteredSymbols.length === 3 && hasWeaponsEnergy) {
      const code = enteredSymbols.join('-');
      onFireTorpedo(code, selectedLane);
      setEnteredSymbols([]);
    }
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={{ paddingBottom: 24 }}>
      {/* Stato Siluri & Scudo */}
      <View style={styles.weaponsCard}>
        <View style={styles.weaponsHeader}>
          <Text style={styles.weaponsTitle}>SISTEMA D'ARMI & DIFESA ATTIVA</Text>
          <Text style={[styles.energyStatus, { color: hasWeaponsEnergy ? Colors.roles.gunner : Colors.dangerRed }]}>
            ENERGIA ARMI: {state.energy.weapons} / 6
          </Text>
        </View>

        {/* Attivazione Scudo Tattico */}
        <View style={styles.shieldRow}>
          <View style={styles.shieldInfo}>
            <Text style={styles.shieldLabel}>BARRIERA DEFLETTRICE SCUDO</Text>
            <Text style={styles.shieldDesc}>Assorbe 1 impatto diretto (richiede energia alle armi)</Text>
          </View>
          <TouchableOpacity
            style={[
              styles.shieldToggleBtn,
              state.shieldActive && styles.shieldToggleBtnActive,
              !hasWeaponsEnergy && styles.shieldToggleBtnDisabled
            ]}
            onPress={onToggleShield}
            disabled={!hasWeaponsEnergy}
            activeOpacity={0.7}
          >
            <Text style={[styles.shieldToggleText, state.shieldActive && styles.shieldToggleTextActive]}>
              {state.shieldActive ? '🛡️ ATTIVO' : 'DISATTIVATO'}
            </Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* Scelta Corsia Bersaglio per Siluro */}
      <View style={styles.section}>
        <Text style={styles.sectionLabel}>1. SELEZIONA CORSIA BERSAGLIO SILURO</Text>
        <View style={styles.lanesRow}>
          {([0, 1, 2] as Lane[]).map(lane => {
            const isSelected = selectedLane === lane;
            return (
              <TouchableOpacity
                key={`gun_lane_${lane}`}
                style={[
                  styles.laneButton,
                  isSelected && styles.laneButtonActive
                ]}
                onPress={() => setSelectedLane(lane)}
                activeOpacity={0.7}
              >
                <Text style={[styles.laneArrow, isSelected && styles.laneArrowActive]}>
                  {lane === 0 ? '◄' : lane === 1 ? '▲' : '►'}
                </Text>
                <Text style={[styles.laneButtonText, isSelected && styles.laneButtonTextActive]}>
                  {laneNames[lane]}
                </Text>
                {isSelected && <Text style={styles.targetLocked}>AGGANCIATA</Text>}
              </TouchableOpacity>
            );
          })}
        </View>
      </View>

      {/* Inserimento Codice Tattico a 3 Simboli */}
      <View style={styles.section}>
        <Text style={styles.sectionLabel}>2. CODICE DI INNESCO (CHIEDI AL SONAR!)</Text>
        
        {/* Display del Codice inserito (font > 32 pt) */}
        <View style={styles.codeDisplayBox}>
          <View style={styles.slotsRow}>
            {Array.from({ length: 3 }).map((_, i) => (
              <View key={`slot_${i}`} style={styles.symbolSlot}>
                <Text style={styles.symbolSlotText}>
                  {enteredSymbols[i] || '—'}
                </Text>
              </View>
            ))}
          </View>
          {enteredSymbols.length > 0 && (
            <TouchableOpacity style={styles.clearBtn} onPress={handleClearCode}>
              <Text style={styles.clearBtnText}>CANCELLA</Text>
            </TouchableOpacity>
          )}
        </View>

        {/* Tastierino Simboli Tattici 4x2 */}
        <View style={styles.symbolsGrid}>
          {SONAR_SYMBOLS.map(sym => (
            <TouchableOpacity
              key={`key_${sym}`}
              style={styles.symbolKey}
              onPress={() => handlePressSymbol(sym)}
              activeOpacity={0.7}
            >
              <Text style={styles.symbolKeyText}>{sym}</Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      {/* Pulsante Lancio Siluro */}
      <View style={styles.fireSection}>
        <TouchableOpacity
          style={[
            styles.fireButton,
            (enteredSymbols.length < 3 || !hasWeaponsEnergy) && styles.fireButtonDisabled
          ]}
          onPress={handleFire}
          disabled={enteredSymbols.length < 3 || !hasWeaponsEnergy}
          activeOpacity={0.7}
        >
          <Text style={styles.fireIcon}>🚀</Text>
          <View style={styles.fireTextCol}>
            <Text style={styles.fireButtonTitle}>LANCIA SILURO</Text>
            <Text style={styles.fireButtonSub}>
              {enteredSymbols.length < 3 
                ? 'Inserisci tutti e 3 i simboli prima di lanciare' 
                : !hasWeaponsEnergy 
                ? 'ENERGIA ARMI INSUFFICIENTE!' 
                : `Fuoco verso corsia ${laneNames[selectedLane]}!`}
            </Text>
          </View>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
  },
  weaponsCard: {
    backgroundColor: Colors.panel,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: Colors.gridBright,
    overflow: 'hidden',
    marginBottom: 16,
  },
  weaponsHeader: {
    backgroundColor: Colors.panelDark,
    paddingVertical: 8,
    paddingHorizontal: 12,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderBottomWidth: 1,
    borderBottomColor: Colors.grid,
  },
  weaponsTitle: {
    color: Colors.roles.gunner,
    fontSize: 11,
    fontWeight: 'bold',
    letterSpacing: 1,
  },
  energyStatus: {
    fontSize: 11,
    fontWeight: 'bold',
  },
  shieldRow: {
    padding: 14,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  shieldInfo: {
    flex: 1,
    marginRight: 10,
  },
  shieldLabel: {
    color: Colors.text,
    fontSize: 12,
    fontWeight: 'bold',
  },
  shieldDesc: {
    color: Colors.textDim,
    fontSize: 10,
    marginTop: 2,
  },
  shieldToggleBtn: {
    backgroundColor: Colors.panelDark,
    borderWidth: 1,
    borderColor: Colors.grid,
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 6,
    minHeight: 44,
    justifyContent: 'center',
  },
  shieldToggleBtnActive: {
    backgroundColor: 'rgba(0, 240, 255, 0.2)',
    borderColor: Colors.shieldCyan,
  },
  shieldToggleBtnDisabled: {
    opacity: 0.4,
  },
  shieldToggleText: {
    color: Colors.textDim,
    fontSize: 11,
    fontWeight: 'bold',
  },
  shieldToggleTextActive: {
    color: Colors.shieldCyan,
  },
  section: {
    marginBottom: 16,
  },
  sectionLabel: {
    color: Colors.roles.gunner,
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
    minHeight: 64,
    backgroundColor: Colors.panel,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: Colors.grid,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 8,
  },
  laneButtonActive: {
    backgroundColor: 'rgba(255, 107, 107, 0.2)',
    borderColor: Colors.roles.gunner,
    borderWidth: 2,
  },
  laneArrow: {
    color: Colors.textDim,
    fontSize: 16,
    marginBottom: 2,
  },
  laneArrowActive: {
    color: Colors.roles.gunner,
  },
  laneButtonText: {
    color: Colors.textDim,
    fontSize: 11,
    fontWeight: 'bold',
  },
  laneButtonTextActive: {
    color: Colors.text,
  },
  targetLocked: {
    color: Colors.roles.gunner,
    fontSize: 9,
    fontWeight: '900',
    marginTop: 2,
  },
  codeDisplayBox: {
    backgroundColor: '#041017',
    borderRadius: 8,
    padding: 12,
    borderWidth: 1,
    borderColor: Colors.grid,
    alignItems: 'center',
    marginBottom: 12,
  },
  slotsRow: {
    flexDirection: 'row',
    gap: 16,
  },
  symbolSlot: {
    width: 60,
    height: 60,
    borderRadius: 8,
    backgroundColor: Colors.panelDark,
    borderWidth: 1,
    borderColor: Colors.roles.gunner,
    justifyContent: 'center',
    alignItems: 'center',
  },
  symbolSlotText: {
    color: Colors.roles.gunner,
    fontSize: 34,
    fontWeight: '900',
  },
  clearBtn: {
    marginTop: 10,
    paddingVertical: 4,
    paddingHorizontal: 12,
    borderRadius: 4,
    backgroundColor: 'rgba(255, 77, 94, 0.15)',
  },
  clearBtnText: {
    color: Colors.dangerRed,
    fontSize: 10,
    fontWeight: 'bold',
  },
  symbolsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
    justifyContent: 'space-between',
  },
  symbolKey: {
    width: '22%',
    height: 56,
    backgroundColor: Colors.panel,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: Colors.gridBright,
    justifyContent: 'center',
    alignItems: 'center',
  },
  symbolKeyText: {
    color: Colors.text,
    fontSize: 24,
    fontWeight: 'bold',
  },
  fireSection: {
    marginTop: 8,
  },
  fireButton: {
    minHeight: 64,
    backgroundColor: 'rgba(255, 107, 107, 0.2)',
    borderWidth: 2,
    borderColor: Colors.roles.gunner,
    borderRadius: 10,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
  fireButtonDisabled: {
    opacity: 0.35,
    borderColor: Colors.grid,
    backgroundColor: Colors.panel,
  },
  fireIcon: {
    fontSize: 28,
    marginRight: 14,
  },
  fireTextCol: {
    flex: 1,
  },
  fireButtonTitle: {
    color: Colors.roles.gunner,
    fontSize: 16,
    fontWeight: 'bold',
    letterSpacing: 1,
  },
  fireButtonSub: {
    color: Colors.textDim,
    fontSize: 11,
    marginTop: 2,
  },
});
