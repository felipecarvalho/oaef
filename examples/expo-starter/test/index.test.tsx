import React from 'react';
import HomeScreen from '../app/index';

describe('HomeScreen Component', () => {
  it('renders HomeScreen element with correct accessibility props', () => {
    const screenElement = <HomeScreen />;
    expect(screenElement.props.accessibilityRole).toBe('summary');
    expect(screenElement.props.accessibilityLabel).toBe('Welcome to Expo Starter');
  });
});
