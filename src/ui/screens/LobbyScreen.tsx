import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView, ScrollView } from 'react-native';
import { Colors } from '../theme/colors';
import { Role } from '../../net/protocol/types';

interface LobbyScreenProps {
  roomCode: string;
  isHost: boolean;
  selectedRole: Role;
  onSelectRole: (role: Role) => void;
  onStartGame: () => void;
  onBack: () => void;
}

export const LobbyScreen: React.FC<LobbyScreenProps> = ({
  roomCode,
  isHost,
  selectedRole,
  onSelectRole,
  onStartGame,
  onBack,
}) => {
  const roles: { role: Role; name: string; icon: string; desc: string; color: string }[] = [
    { role: 'pilot', name: 'PILOTA', icon: '🚢', desc: 'Guida tra le corsie e imposta la velocità', color: Colors.roles.pilot },
    { role: 'sonar', name: 'SONAR', icon: '📡', desc: 'Vede il radar 360° e scopre i codici con i Ping', color: Colors.roles.sonar },
    { role: 'engineer', name: 'INGEGNERE', icon: '⚙️', desc: 'Ripartisce l\'energia e gestisce il calore', color: Colors.roles.engineer },
    { role: 'gunner', name: 'ARMIERE', icon: '🎯', desc: 'Lancia siluri con codici e attiva lo scudo', color: Colors.roles.gunner },
  ];

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={onBack}>
          <Text style={styles.backButtonText}>◄ ESCI</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>STANZA TATTICA BLE: {roomCode}</Text>
      </View>

      <ScrollView contentContainerStyle={styles.content}>
        {/* Card Codice Stanza */}
        <View style={styles.codeCard}>
          <Text style={styles.codeLabel}>CODICE STANZA (COMUNICA AGLI ALTRI TELEFONI)</Text>
          <Text style={styles.codeText}>{roomCode}</Text>
          <Text style={styles.codeNotice}>
            Assicurati che il Bluetooth sia attivo su tutti i dispositivi.
          </Text>
        </View>

        {/* Selezione Ruolo */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>SCEGLI LA TUA POSTAZIONE NEL SOMMERGIBILE</Text>
          <View style={styles.rolesGrid}>
            {roles.map(r => {
              const isSelected = selectedRole === r.role;
              return (
                <TouchableOpacity
                  key={`lobby_role_${r.role}`}
                  style={[
                    styles.roleCard,
                    { borderColor: isSelected ? r.color : Colors.grid },
                    isSelected && { backgroundColor: `${r.color}18` }
                  ]}
                  onPress={() => onSelectRole(r.role)}
                  activeOpacity={0.7}
                >
                  <View style={styles.roleCardTop}>
                    <Text style={styles.roleIcon}>{r.icon}</Text>
                    <Text style={[styles.roleName, { color: r.color }]}>{r.name}</Text>
                  </View>
                  <Text style={styles.roleDesc}>{r.desc}</Text>
                  {isSelected && (
                    <View style={[styles.selectedBadge, { backgroundColor: r.color }]}>
                      <Text style={styles.selectedBadgeText}>ASSEGNATO A TE</Text>
                    </View>
                  )}
                </TouchableOpacity>
              );
            })}
          </View>
        </View>

        {/* Nota Equipaggio & Bot */}
        <View style={styles.noticeCard}>
          <Text style={styles.noticeTitle}>🤖 EQUIPAGGIO MISTO O AUTOMATICO</Text>
          <Text style={styles.noticeDesc}>
            Se mancano giocatori umani, le postazioni vacanti verranno assegnate all'IA di bordo
            per permettere la missione anche con 1, 2 o 3 persone!
          </Text>
        </View>

        {/* Pulsante Avvia Missione */}
        <TouchableOpacity style={styles.startButton} onPress={onStartGame} activeOpacity={0.8}>
          <Text style={styles.startButtonText}>INIZIA IMMERSIONE (AVVIA MISSIONE)</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.abyss,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    backgroundColor: Colors.panelDark,
    borderBottomWidth: 1,
    borderBottomColor: Colors.grid,
  },
  backButton: {
    paddingVertical: 6,
    paddingHorizontal: 10,
    backgroundColor: Colors.panel,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: Colors.grid,
    marginRight: 12,
  },
  backButtonText: {
    color: Colors.sonarTeal,
    fontSize: 11,
    fontWeight: 'bold',
  },
  headerTitle: {
    color: Colors.text,
    fontSize: 13,
    fontWeight: 'bold',
    letterSpacing: 1,
  },
  content: {
    padding: 16,
    gap: 16,
  },
  codeCard: {
    backgroundColor: Colors.panel,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: Colors.gridBright,
    padding: 18,
    alignItems: 'center',
  },
  codeLabel: {
    color: Colors.textDim,
    fontSize: 10,
    fontWeight: 'bold',
    letterSpacing: 0.5,
  },
  codeText: {
    color: Colors.sonarTeal,
    fontSize: 38,
    fontWeight: '900',
    letterSpacing: 8,
    marginVertical: 6,
  },
  codeNotice: {
    color: Colors.textDim,
    fontSize: 11,
    textAlign: 'center',
  },
  section: {
    gap: 10,
  },
  sectionTitle: {
    color: Colors.textDim,
    fontSize: 11,
    fontWeight: 'bold',
    letterSpacing: 0.5,
  },
  rolesGrid: {
    gap: 10,
  },
  roleCard: {
    backgroundColor: Colors.panel,
    borderRadius: 10,
    borderWidth: 1,
    padding: 14,
  },
  roleCardTop: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4,
  },
  roleIcon: {
    fontSize: 18,
    marginRight: 8,
  },
  roleName: {
    fontSize: 14,
    fontWeight: '900',
    letterSpacing: 0.5,
  },
  roleDesc: {
    color: Colors.textDim,
    fontSize: 11,
    lineHeight: 16,
  },
  selectedBadge: {
    alignSelf: 'flex-start',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 4,
    marginTop: 8,
  },
  selectedBadgeText: {
    color: '#000',
    fontSize: 9,
    fontWeight: '900',
  },
  noticeCard: {
    backgroundColor: Colors.panelDark,
    borderRadius: 8,
    padding: 12,
    borderWidth: 1,
    borderColor: Colors.grid,
  },
  noticeTitle: {
    color: Colors.warningAmber,
    fontSize: 11,
    fontWeight: 'bold',
    marginBottom: 4,
  },
  noticeDesc: {
    color: Colors.textDim,
    fontSize: 11,
    lineHeight: 15,
  },
  startButton: {
    minHeight: 56,
    backgroundColor: Colors.sonarTeal,
    borderRadius: 10,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 8,
    marginBottom: 20,
  },
  startButtonText: {
    color: '#000',
    fontSize: 14,
    fontWeight: '900',
    letterSpacing: 1,
  },
});
