import React from 'react';
import { StyleSheet, Text, View } from 'react-native';

export default function HomeScreen() {
  return (
    <View
      style={styles.container}
      accessible={true}
      accessibilityRole="summary"
      accessibilityLabel="Welcome to Expo Starter"
    >
      <Text style={styles.titleText}>Welcome to Expo Starter</Text>
      <Text style={styles.descriptionText}>
        Managed workflow engineered with OAEF agentic contracts.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#F8FAFC',
    padding: 24,
  },
  titleText: {
    fontSize: 24,
    fontWeight: '700',
    color: '#0F172A',
    marginBottom: 8,
    textAlign: 'center',
  },
  descriptionText: {
    fontSize: 16,
    color: '#64748B',
    textAlign: 'center',
    lineHeight: 24,
  },
});
