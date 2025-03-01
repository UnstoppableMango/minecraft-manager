import { describe, expect, it } from 'bun:test';
import { render } from '@testing-library/react';

import App from './App';

describe('App', () => {
  it('should render Versions', () => {
    const { getByText } = render(<App />);

    expect(getByText('Versions')).toBeDefined();
  });
});
