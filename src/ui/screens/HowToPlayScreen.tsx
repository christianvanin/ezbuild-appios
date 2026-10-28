import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, SafeAreaView } from 'react-native';
import { Colors } from '../theme/colors';

interface HowToPlayScreenProps {
  onBack: () => void;
}

export const HowToPlayScreen: React.FC<HowToPlayScreenProps> = ({ onBack }) => {
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={onBack}>
          <Text style={styles.backButtonText}>◄ INDIETRO</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>MANUALE D'OPERAZIONE ECHO-9</Text>
      </View>

      <ScrollView contentContainerStyle={styles.content}>
        <View style={styles.card}>
          <Text style={styles.cardTitle}>REGOLA FONDAMENTALE</Text>
          <Text style={styles.cardText}>
            Nessun giocatore ha il quadro completo. Chi guida non vede il radar, chi ha il radar non può sparare, 
            chi ha le armi ha bisogno dei codici scoperti dal sonar. Si vince parlando ad alta voce e in fretta!
          </Text>
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>LE 4 POSTAZIONI</Text>
          
          <View style={[styles.roleItem, { borderLeftColor: Colors.roles.pilot }]}>
            <Text style={[styles.roleName, { color: Colors.roles.pilot }]}>PILOTA (CIANO)</Text>
            <Text style={styles.roleDesc}>
              Sceglie la corsia (Sinistra, Centro, Destra) e la velocità (Ferma, Lenta, Piena). 
              Vede solo la propria corsia nella nebbia. Deve compensare le correnti marine.
            </Text>
          </View>

          <View style={[styles.roleItem, { borderLeftColor: Colors.roles.sonar }]}>
            <Text style={[styles.roleName, { color: Colors.roles.sonar }]}>SONAR (VERDE)</Text>
            <Text style={styles.roleDesc}>
              Vede il radar circolare a 360° con tutte le minacce in arrivo. 
              Emette il Ping per scoprire il tipo di minaccia e il codice di innesco a 3 simboli.
            </Text>
          </View>

          <View style={[styles.roleItem, { borderLeftColor: Colors.roles.engineer }]}>
            <Text style={[styles.roleName, { color: Colors.roles.engineer }]}>INGEGNERE (AMBRA)</Text>
            <Text style={styles.roleDesc}>
              Distribuisce 6 punti energia tra Motore, Sonar e Armi. 
              Se un impianto ha ≥ 4 energia si surriscalda: deve sfiatarlo o si spegnerà!
            </Text>
          </View>

          <View style={[styles.roleItem, { borderLeftColor: Colors.roles.gunner }]}>
            <Text style={[styles.roleName, { color: Colors.roles.gunner }]}>ARMIERE (CORALLO)</Text>
            <Text style={styles.roleDesc}>
              Inserisce il codice a 3 simboli dettato a voce dal Sonar, seleziona la corsia e lancia i siluri. 
              Può anche attivare lo scudo per deflettere un impatto.
            </Text>
          </View>
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>IL CICLO (25 SECONDI)</Text>
          <Text style={styles.cardText}>
            1. <Text style={styles.bold}>Rilevamento (5s)</Text>: Allarme sonar. Solo il Sonar vede cosa sta per arrivare.{'\n'}
            2. <Text style={styles.bold}>Pianificazione (15s)</Text>: Tutti parlano e agiscono insieme.{'\n'}
            3. <Text style={styles.bold}>Risoluzione (5s)</Text>: Calcolo danni ed esplosioni condivise.
          </Text>
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>MINACCE ABISSALI</Text>
          <Text style={styles.cardText}>
            • <Text style={styles.bold}>Mine</Text>: occupano 1 corsia. Evitale o distruggile con un siluro.{'\n'}
            • <Text style={styles.bold}>Corrente</Text>: spinge il sommergibile di 1 corsia lateralmente.{'\n'}
            • <Text style={styles.bold}>Scogliera</Text>: occupa 2 corsie. Passa a motori fermi o nella corsia libera.{'\n'}
            • <Text style={styles.bold}>Leviatano</Text>: richiede Silenzio assoluto (Motore e Sonar a 0 energia)!{'\n'}
            • <Text style={styles.bold}>Relitto (Bonus)</Text>: passa a velocità lenta per recuperare +1 Scafo.
          </Text>
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
    letterSpacing: 0.5,
  },
  content: {
    padding: 16,
    gap: 14,
  },
  card: {
    backgroundColor: Colors.panel,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: Colors.grid,
    padding: 16,
  },
  cardTitle: {
    color: Colors.sonarTeal,
    fontSize: 13,
    fontWeight: '900',
    letterSpacing: 1,
    marginBottom: 8,
  },
  cardText: {
    color: Colors.textDim,
    fontSize: 12,
    lineHeight: 18,
  },
  bold: {
    color: Colors.text,
    fontWeight: 'bold',
  },
  roleItem: {
    borderLeftWidth: 3,
    paddingLeft: 10,
    marginBottom: 12,
  },
  roleName: {
    fontSize: 12,
    fontWeight: 'bold',
    marginBottom: 2,
  },
  roleDesc: {
    color: Colors.textDim,
    fontSize: 11,
    lineHeight: 16,
  },
});
