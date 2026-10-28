import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView, ScrollView } from 'react-native';
import { Colors } from '../theme/colors';

interface HomeScreenProps {
  onStartSolo: () => void;
  onHostGame: () => void;
  onJoinGame: () => void;
  onOpenHowToPlay: () => void;
}

export const HomeScreen: React.FC<HomeScreenProps> = ({
  onStartSolo,
  onHostGame,
  onJoinGame,
  onOpenHowToPlay,
}) => {
  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        {/* Logo ECHO-9 CRT Retro-Futuristico */}
        <View style={styles.logoBox}>
          <Text style={styles.subTitleSmall}>SISTEMA SOMMERGIBILE TATTICO</Text>
          <Text style={styles.logoTitle}>ECHO-9</Text>
          <Text style={styles.logoTagline}>CO-OP LOCALE AD ALTA TENSIONE</Text>
          <View style={styles.logoDivider} />
          <Text style={styles.loreText}>
            5 Settori Abissali · 4 Postazioni · 1 Solo Scafo Condiviso.
            Parla ad alta voce, decidi in 15 secondi, fidati dell'equipaggio.
          </Text>
        </View>

        {/* Pulsanti Menu Principale */}
        <View style={styles.menuGroup}>
          {/* Modalità 1: Test Rapido con Bot IA */}
          <TouchableOpacity 
            style={[styles.menuButton, styles.soloButton]} 
            onPress={onStartSolo}
            activeOpacity={0.8}
          >
            <Text style={styles.btnIcon}>🤖</Text>
            <View style={styles.btnTextCol}>
              <Text style={styles.btnTitle}>TEST IMMEDIATO / BOT IA</Text>
              <Text style={styles.btnSub}>Gioca subito da solo testando tutte le 4 postazioni</Text>
            </View>
          </TouchableOpacity>

          {/* Modalità 2: Host Bluetooth LE */}
          <TouchableOpacity 
            style={[styles.menuButton, styles.hostButton]} 
            onPress={onHostGame}
            activeOpacity={0.8}
          >
            <Text style={styles.btnIcon}>📡</Text>
            <View style={styles.btnTextCol}>
              <Text style={styles.btnTitle}>CREA STANZA (HOST BLE)</Text>
              <Text style={styles.btnSub}>Fai da server GATT per iPhone e Android vicini</Text>
            </View>
          </TouchableOpacity>

          {/* Modalità 3: Client Bluetooth LE */}
          <TouchableOpacity 
            style={[styles.menuButton, styles.joinButton]} 
            onPress={onJoinGame}
            activeOpacity={0.8}
          >
            <Text style={styles.btnIcon}>🔍</Text>
            <View style={styles.btnTextCol}>
              <Text style={styles.btnTitle}>UNISCITI A STANZA (CLIENT)</Text>
              <Text style={styles.btnSub}>Scansiona le postazioni ECHO-9 nei paraggi</Text>
            </View>
          </TouchableOpacity>

          {/* Modalità 4: Come si gioca */}
          <TouchableOpacity 
            style={[styles.menuButton, styles.rulesButton]} 
            onPress={onOpenHowToPlay}
            activeOpacity={0.8}
          >
            <Text style={styles.btnIcon}>📖</Text>
            <View style={styles.btnTextCol}>
              <Text style={styles.btnTitle}>MANUALE D'OPERAZIONE</Text>
              <Text style={styles.btnSub}>Regole, ruoli, minacce e comandi a voce</Text>
            </View>
          </TouchableOpacity>
        </View>

        {/* Badge Ruoli a Fondo Schermo */}
        <View style={styles.rolesPreview}>
          <View style={[styles.rolePill, { borderColor: Colors.roles.pilot }]}>
            <Text style={[styles.rolePillText, { color: Colors.roles.pilot }]}>PILOTA</Text>
          </View>
          <View style={[styles.rolePill, { borderColor: Colors.roles.sonar }]}>
            <Text style={[styles.rolePillText, { color: Colors.roles.sonar }]}>SONAR</Text>
          </View>
          <View style={[styles.rolePill, { borderColor: Colors.roles.engineer }]}>
            <Text style={[styles.rolePillText, { color: Colors.roles.engineer }]}>INGEGNERE</Text>
          </View>
          <View style={[styles.rolePill, { borderColor: Colors.roles.gunner }]}>
            <Text style={[styles.rolePillText, { color: Colors.roles.gunner }]}>ARMIERE</Text>
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.abyss,
  },
  scrollContent: {
    padding: 24,
    alignItems: 'center',
    justifyContent: 'center',
    flexGrow: 1,
  },
  logoBox: {
    alignItems: 'center',
    marginBottom: 32,
    width: '100%',
  },
  subTitleSmall: {
    color: Colors.sonarTeal,
    fontSize: 11,
    letterSpacing: 2,
    fontWeight: 'bold',
    marginBottom: 4,
  },
  logoTitle: {
    color: '#fff',
    fontSize: 54,
    fontWeight: '900',
    letterSpacing: 6,
    textShadowColor: Colors.sonarTeal,
    textShadowOffset: { width: 0, height: 0 },
    textShadowRadius: 18,
  },
  logoTagline: {
    color: Colors.warningAmber,
    fontSize: 12,
    fontWeight: 'bold',
    letterSpacing: 2,
    marginTop: 2,
  },
  logoDivider: {
    width: 60,
    height: 2,
    backgroundColor: Colors.sonarTeal,
    marginVertical: 14,
  },
  loreText: {
    color: Colors.textDim,
    fontSize: 12,
    textAlign: 'center',
    lineHeight: 18,
    maxWidth: 320,
  },
  menuGroup: {
    width: '100%',
    gap: 14,
    marginBottom: 32,
  },
  menuButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.panel,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: Colors.grid,
    padding: 16,
    minHeight: 74,
  },
  soloButton: {
    borderColor: Colors.sonarTeal,
    backgroundColor: 'rgba(18, 214, 193, 0.12)',
  },
  hostButton: {
    borderColor: Colors.roles.pilot,
  },
  joinButton: {
    borderColor: Colors.roles.engineer,
  },
  rulesButton: {
    borderColor: Colors.grid,
  },
  btnIcon: {
    fontSize: 28,
    marginRight: 16,
  },
  btnTextCol: {
    flex: 1,
  },
  btnTitle: {
    color: Colors.text,
    fontSize: 14,
    fontWeight: '900',
    letterSpacing: 0.5,
  },
  btnSub: {
    color: Colors.textDim,
    fontSize: 11,
    marginTop: 3,
  },
  rolesPreview: {
    flexDirection: 'row',
    gap: 8,
    justifyContent: 'center',
  },
  rolePill: {
    paddingVertical: 4,
    paddingHorizontal: 8,
    borderRadius: 4,
    borderWidth: 1,
    backgroundColor: Colors.panelDark,
  },
  rolePillText: {
    fontSize: 9,
    fontWeight: 'bold',
    letterSpacing: 0.5,
  },
});
