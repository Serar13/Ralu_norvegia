import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App.jsx';
import { initAnalytics } from './firebase.js';
import './styles/index.css';

// Fire-and-forget analytics init (safe no-op if unsupported / no config).
initAnalytics();

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
