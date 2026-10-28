import React, { useState, useEffect, useRef } from 'react';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaView, StyleSheet } from 'react-native';
import { Colors } from './src/ui/theme/colors';
import { HomeScreen } from './src/ui/screens/HomeScreen';
import { LobbyScreen } from './src/ui/screens/LobbyScreen';
import { GameConsoleScreen } from './src/ui/screens/GameConsoleScreen';
import { HowToPlayScreen } from './src/ui/screens/HowToPlayScreen';
import { HostSession } from './src/net/session/HostSession';
import { LoopbackTransport } from './src/net/transport/LoopbackTransport';
import { GameState, Role } from './src/net/protocol/types';
import { createInitialGameState } from './src/game/engine/gameEngine';

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<'home' | 'lobby' | 'game' | 'how_to_play'>('home');
  const [gameState, setGameState] = useState<GameState>(createInitialGameState());
  const [playerRole, setPlayerRole] = useState<Role>('pilot');
  const [roomCode, setRoomCode] = useState<string>('ECH9');

  const hostSessionRef = useRef<HostSession | null>(null);

  // Pulisci il ciclo timer quando il componente si smonta
  useEffect(() => {
    return () => {
      if (hostSessionRef.current) {
        hostSessionRef.current.destroy();
      }
    };
  }, []);

  // Avvio Rapido / Solo Test con Bot IA
  const handleStartSolo = () => {
    if (hostSessionRef.current) {
      hostSessionRef.current.destroy();
    }

    const transport = new LoopbackTransport();
    const session = new HostSession(transport);

    session.addPlayer({
      id: 'local_commander',
      name: 'Comandante',
      role: 'pilot',
      isHost: true,
    });

    // Riempi le altre 3 postazioni con l'IA di bordo
    session.fillBots();

    session.onStateUpdate(updatedState => {
      setGameState(updatedState);
    });

    session.startMission();
    hostSessionRef.current = session;
    setPlayerRole('pilot');
    setCurrentScreen('game');
  };

  // Creazione Stanza Host BLE
  const handleHostGame = () => {
    const randomCode = Math.random().toString(36).substring(2, 6).toUpperCase();
    setRoomCode(randomCode);

    if (hostSessionRef.current) {
      hostSessionRef.current.destroy();
    }

    const transport = new LoopbackTransport();
    const session = new HostSession(transport);

    session.addPlayer({
      id: 'host_player',
      name: 'Host Sommergibile',
      role: playerRole,
      isHost: true,
    });

    session.onStateUpdate(updatedState => {
      setGameState(updatedState);
    });

    hostSessionRef.current = session;
    setCurrentScreen('lobby');
  };

  const handleStartLobbyGame = () => {
    if (!hostSessionRef.current) return;
    // Riempi eventuali ruoli vuoti con Bot
    hostSessionRef.current.fillBots();
    hostSessionRef.current.startMission();
    setCurrentScreen('game');
  };

  const handleDispatchAction = (action: any) => {
    if (hostSessionRef.current) {
      hostSessionRef.current.dispatchAction(action);
    }
  };

  const handleRestart = () => {
    if (hostSessionRef.current) {
      hostSessionRef.current.startMission();
    }
  };

  const handleExitToHome = () => {
    if (hostSessionRef.current) {
      hostSessionRef.current.destroy();
      hostSessionRef.current = null;
    }
    setCurrentScreen('home');
  };

  return (
    <SafeAreaView style={styles.root}>
      <StatusBar style="light" />

      {currentScreen === 'home' && (
        <HomeScreen
          onStartSolo={handleStartSolo}
          onHostGame={handleHostGame}
          onJoinGame={handleHostGame}
          onOpenHowToPlay={() => setCurrentScreen('how_to_play')}
        />
      )}

      {currentScreen === 'lobby' && (
        <LobbyScreen
          roomCode={roomCode}
          isHost={true}
          selectedRole={playerRole}
          onSelectRole={role => setPlayerRole(role)}
          onStartGame={handleStartLobbyGame}
          onBack={handleExitToHome}
        />
      )}

      {currentScreen === 'how_to_play' && (
        <HowToPlayScreen onBack={() => setCurrentScreen('home')} />
      )}

      {currentScreen === 'game' && (
        <GameConsoleScreen
          state={gameState}
          initialRole={playerRole}
          onDispatchAction={handleDispatchAction}
          onRestartMission={handleRestart}
          onExitToHome={handleExitToHome}
        />
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: Colors.abyss,
  },
});
