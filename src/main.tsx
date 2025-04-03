import React from 'react';
import { createRoot } from 'react-dom/client';
import { App } from './app';

function start() {
  const root = createRoot(document.getElementById('root')!);
  root.render(<App />);
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', start);
} else {
  start();
}
