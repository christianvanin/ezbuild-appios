import React from 'react';
import { StyleSheet, Text, View, SafeAreaView, TouchableOpacity } from 'react-native';
import { StatusBar } from 'expo-status-bar';

export default function App() {
  return (
    <SafeAreaView style={styles.container}>
      <StatusBar style="light" />
      <View style={styles.card}>
        <Text style={styles.badge}>READY FOR DEVELOPMENT</Text>
        <Text style={styles.title}>Nuovo Gioco Multipiattaforma</Text>
        <Text style={styles.subtitle}>
          Base React Native (Expo) pronta e pulita per iOS, Android e Web.
        </Text>
        <View style={styles.statusBox}>
          <Text style={styles.statusLabel}>Stato Ambiente:</Text>
          <Text style={styles.statusValue}>✓ Struttura React Native configurata</Text>
          <Text style={styles.statusValue}>✓ Build Cloud iOS (GitHub Actions) pronta</Text>
          <Text style={styles.statusValue}>✓ In attesa delle specifiche del gioco</Text>
        </View>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0d1117',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  card: {
    width: '100%',
    maxWidth: 440,
    backgroundColor: '#161b22',
    borderRadius: 16,
    padding: 24,
    borderWidth: 1,
    borderColor: '#30363d',
    alignItems: 'center',
  },
  badge: {
    color: '#58a6ff',
    backgroundColor: 'rgba(56, 139, 253, 0.15)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
    fontSize: 12,
    fontWeight: 'bold',
    marginBottom: 16,
    letterSpacing: 1,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#f0f6fc',
    textAlign: 'center',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 14,
    color: '#8b949e',
    textAlign: 'center',
    marginBottom: 20,
    lineHeight: 20,
  },
  statusBox: {
    width: '100%',
    backgroundColor: '#0d1117',
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: '#21262d',
  },
  statusLabel: {
    fontSize: 13,
    color: '#7ee787',
    fontWeight: '600',
    marginBottom: 8,
  },
  statusValue: {
    fontSize: 13,
    color: '#c9d1d9',
    marginVertical: 3,
  },
});
