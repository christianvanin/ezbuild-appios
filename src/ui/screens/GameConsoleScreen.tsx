import React, { useState } from 'react';
import { View, Text, StyleSheet, SafeAreaView, TouchableOpacity } from 'react-native';
import { Colors } from '../theme/colors';
import { GameState, Role, Lane, Speed, SystemEnergy, SystemHeat } from '../../net/protocol/types';
import { SubmarineHeader } from '../components/SubmarineHeader';
import { PilotConsole } from '../roles/PilotConsole';
import { SonarConsole } from '../roles/SonarConsole';
import { EngineerConsole } from '../roles/EngineerConsole';
import { GunnerConsole } from '../roles/GunnerConsole';
import { ResolutionModal } from '../components/ResolutionModal';

interface GameConsoleScreenProps {
  state: GameState;
  initialRole: Role;
  onDispatchAction: (action: any) => void;
  onRestartMission: () => void;
  onExitToHome: () => void;
}

export const GameConsoleScreen: React.FC<GameConsoleScreenProps> = ({
  state,
  initialRole,
  onDispatchAction,
  onRestartMission,
  onExitToHome,
}) => {
  const [activeRole, setActiveRole] = useState<Role>(initialRole);

  const roles: { role: Role; name: string; icon: string; color: string }[] = [
    { role: 'pilot', name: 'PILOTA', icon: '🚢', color: Colors.roles.pilot },
    { role: 'sonar', name: 'SONAR', icon: '📡', color: Colors.roles.sonar },
    { role: 'engineer', name: 'INGEGNERE', icon: '⚙️', color: Colors.roles.engineer },
    { role: 'gunner', name: 'ARMIERE', icon: '🎯', color: Colors.roles.gunner },
  ];

  // Schermata di Game Over (Scafo a 0)
  if (state.isGameOver) {
    return (
      <SafeAreaView style={styles.endContainer}>
        <View style={styles.endCard}>
          <Text style={styles.defeatIcon}>💥</Text>
          <Text style={styles.defeatTitle}>MISSIONE FALLITA</Text>
          <Text style={styles.defeatDesc}>
            Lo scafo del sottomarino ECHO-9 è collassato sotto la pressione abissale.
          </Text>
          <View style={styles.statsBox}>
            <Text style={styles.statLine}>Settore Raggiunto: {state.sector}/5</Text>
            <Text style={styles.statLine}>Punteggio Squadra: {state.score} PTS</Text>
          </View>
          <TouchableOpacity style={styles.restartBtn} onPress={onRestartMission} activeOpacity={0.8}>
            <Text style={styles.restartBtnText}>RIGIOCA MISSIONE</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.exitBtn} onPress={onExitToHome} activeOpacity={0.8}>
            <Text style={styles.exitBtnText}>TORNA AL MENU</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  // Schermata di Vittoria (Completati 5 Settori)
  if (state.isVictory) {
    const stars = state.hull >= 5 ? '★★★' : state.hull >= 3 ? '★★☆' : '★☆☆';
    return (
      <SafeAreaView style={styles.endContainer}>
        <View style={[styles.endCard, styles.victoryCard]}>
          <Text style={styles.victoryIcon}>🏆</Text>
          <Text style={styles.victoryTitle}>FONDALE RAGGIUNTO!</Text>
          <Text style={styles.starsText}>{stars}</Text>
          <Text style={styles.victoryDesc}>
            L'equipaggio di ECHO-9 ha attraversato tutti i 5 settori e sconfitto gli abissi!
          </Text>
          <View style={styles.statsBox}>
            <Text style={styles.statLine}>Scafo Residuo: {state.hull}/6</Text>
            <Text style={styles.statLine}>Punteggio Finale: {state.score} PTS</Text>
          </View>
          <TouchableOpacity style={styles.restartBtn} onPress={onRestartMission} activeOpacity={0.8}>
            <Text style={styles.restartBtnText}>NUOVA IMMERSIONE</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.exitBtn} onPress={onExitToHome} activeOpacity={0.8}>
            <Text style={styles.exitBtnText}>TORNA AL MENU</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      {/* Header Fisso con Risorse Condivise e Timer */}
      <SubmarineHeader state={state} activeRole={activeRole} />

      {/* Selettore Rapido Postazioni (ideale per Test Solo e Pass & Play) */}
      <View style={styles.roleSwitcherBar}>
        {roles.map(r => {
          const isActive = activeRole === r.role;
          return (
            <TouchableOpacity
              key={`switcher_${r.role}`}
              style={[
                styles.switchBtn,
                { borderColor: isActive ? r.color : Colors.grid },
                isActive && { backgroundColor: `${r.color}22` }
              ]}
              onPress={() => setActiveRole(r.role)}
              activeOpacity={0.7}
            >
              <Text style={styles.switchIcon}>{r.icon}</Text>
              <Text style={[styles.switchText, { color: isActive ? r.color : Colors.textDim }]}>
                {r.name}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>

      {/* Postazione Attiva Selezionata */}
      <View style={styles.consoleBody}>
        {activeRole === 'pilot' && (
          <PilotConsole
            state={state}
            onSetLane={(lane: Lane) => onDispatchAction({ role: 'pilot', action: 'SET_LANE', lane })}
            onSetSpeed={(speed: Speed) => onDispatchAction({ role: 'pilot', action: 'SET_SPEED', speed })}
          />
        )}

        {activeRole === 'sonar' && (
          <SonarConsole
            state={state}
            onPing={(threatId: string) => onDispatchAction({ role: 'sonar', action: 'PING', threatId })}
          />
        )}

        {activeRole === 'engineer' && (
          <EngineerConsole
            state={state}
            onSetEnergy={(system: keyof SystemEnergy, delta: number) => 
              onDispatchAction({ role: 'engineer', action: 'SET_ENERGY', system, delta })
            }
            onCoolDown={(system: keyof SystemHeat) => 
              onDispatchAction({ role: 'engineer', action: 'COOL_DOWN', system })
            }
          />
        )}

        {activeRole === 'gunner' && (
          <GunnerConsole
            state={state}
            onFireTorpedo={(code: string, lane: Lane) => 
              onDispatchAction({ role: 'gunner', action: 'FIRE_TORPEDO', code, lane })
            }
            onToggleShield={() => 
              onDispatchAction({ role: 'gunner', action: 'ACTIVATE_SHIELD' })
            }
          />
        )}
      </View>

      {/* Modal Risoluzione Ciclo */}
      <ResolutionModal
        visible={state.phase === 'resolution'}
        state={state}
        events={state.lastEvents}
      />
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.abyss,
  },
  roleSwitcherBar: {
    flexDirection: 'row',
    backgroundColor: Colors.panelDark,
    paddingHorizontal: 12,
    paddingVertical: 6,
    gap: 6,
    borderBottomWidth: 1,
    borderBottomColor: Colors.grid,
  },
  switchBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 6,
    borderRadius: 6,
    borderWidth: 1,
  },
  switchIcon: {
    fontSize: 12,
    marginRight: 4,
  },
  switchText: {
    fontSize: 10,
    fontWeight: '900',
    letterSpacing: 0.5,
  },
  consoleBody: {
    flex: 1,
  },
  endContainer: {
    flex: 1,
    backgroundColor: Colors.abyss,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  endCard: {
    width: '100%',
    backgroundColor: Colors.panel,
    borderRadius: 16,
    borderWidth: 2,
    borderColor: Colors.dangerRed,
    padding: 24,
    alignItems: 'center',
  },
  victoryCard: {
    borderColor: Colors.sonarTeal,
  },
  defeatIcon: {
    fontSize: 54,
    marginBottom: 12,
  },
  victoryIcon: {
    fontSize: 54,
    marginBottom: 8,
  },
  defeatTitle: {
    color: Colors.dangerRed,
    fontSize: 26,
    fontWeight: '900',
    letterSpacing: 2,
    marginBottom: 8,
  },
  victoryTitle: {
    color: Colors.sonarTeal,
    fontSize: 26,
    fontWeight: '900',
    letterSpacing: 2,
    marginBottom: 4,
  },
  starsText: {
    fontSize: 28,
    color: Colors.warningAmber,
    letterSpacing: 4,
    marginBottom: 8,
  },
  defeatDesc: {
    color: Colors.textDim,
    fontSize: 13,
    textAlign: 'center',
    lineHeight: 18,
    marginBottom: 20,
  },
  victoryDesc: {
    color: Colors.textDim,
    fontSize: 13,
    textAlign: 'center',
    lineHeight: 18,
    marginBottom: 20,
  },
  statsBox: {
    width: '100%',
    backgroundColor: Colors.panelDark,
    borderRadius: 8,
    padding: 14,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: Colors.grid,
  },
  statLine: {
    color: Colors.text,
    fontSize: 13,
    fontWeight: 'bold',
    marginVertical: 3,
  },
  restartBtn: {
    width: '100%',
    minHeight: 52,
    backgroundColor: Colors.sonarTeal,
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 10,
  },
  restartBtnText: {
    color: '#000',
    fontSize: 13,
    fontWeight: '900',
    letterSpacing: 1,
  },
  exitBtn: {
    paddingVertical: 10,
  },
  exitBtnText: {
    color: Colors.textDim,
    fontSize: 12,
    fontWeight: 'bold',
  },
});
