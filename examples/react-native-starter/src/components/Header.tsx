import React from 'react';
import { StyleSheet, Text, View } from 'react-native';

export interface HeaderProperties {
  readonly title: string;
  readonly subtitle?: string;
}

export const Header: React.FC<HeaderProperties> = ({ title, subtitle }) => {
  return (
    <View
      style={styles.container}
      accessible={true}
      accessibilityRole="header"
      accessibilityLabel={title}
    >
      <Text style={styles.titleText}>{title}</Text>
      {subtitle ? <Text style={styles.subtitleText}>{subtitle}</Text> : null}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#E2E8F0',
  },
  titleText: {
    fontSize: 20,
    fontWeight: '700',
    color: '#0F172A',
  },
  subtitleText: {
    fontSize: 14,
    color: '#64748B',
    marginTop: 4,
  },
});
