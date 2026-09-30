import React from 'react';
import { Header } from '../src/components/Header';

describe('Header Component', () => {
  it('instantiates header component structure successfully', () => {
    const element = <Header title="Dashboard" subtitle="Overview of activities" />;
    expect(element.props.title).toBe('Dashboard');
    expect(element.props.subtitle).toBe('Overview of activities');
  });
});
