import React, { useState, useEffect } from 'react';
import './App.css';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8080/api';

function App() {
  const [counter, setCounter] = useState(0);
  const [status, setStatus] = useState('');
  const [loading, setLoading] = useState(false);

  // Fetch initial counter value
  useEffect(() => {
    fetchCounter();
  }, []);

  const fetchCounter = async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE_URL}/counter`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const data = await response.json();
      setCounter(data.value);
      setStatus('Connected to Java backend ✅');
    } catch (error) {
      console.error('Error fetching counter:', error);
      setStatus(`Error: ${error.message} ❌`);
    } finally {
      setLoading(false);
    }
  };

  const updateCounter = async (action) => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE_URL}/counter/${action}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
      });
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      setCounter(data.value);
      setStatus(`Counter ${action}ed successfully ✅`);
    } catch (error) {
      console.error(`Error ${action}ing counter:`, error);
      setStatus(`Error: ${error.message} ❌`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="App">
      <div className="counter-container">
        <h1>Java Counter App</h1>
        <p>Spring Boot + React + Docker</p>
        
        <div className="counter-value">
          {loading ? '...' : counter}
        </div>
        
        <div className="button-group">
          <button 
            className="counter-button increment" 
            onClick={() => updateCounter('increment')}
            disabled={loading}
          >
            + Increment
          </button>
          <button 
            className="counter-button decrement" 
            onClick={() => updateCounter('decrement')}
            disabled={loading}
          >
            - Decrement
          </button>
          <button 
            className="counter-button reset" 
            onClick={() => updateCounter('reset')}
            disabled={loading}
          >
            🔄 Reset
          </button>
        </div>
        
        {status && (
          <div className={`status ${status.includes('Error') ? 'error' : 'success'}`}>
            {status}
          </div>
        )}
        
        <div className="tech-stack">
          <h3>Tech Stack</h3>
          <p><strong>Backend:</strong> Spring Boot (Java 17)</p>
          <p><strong>Frontend:</strong> React 18</p>
          <p><strong>Webhook:</strong> Java Spring Boot</p>
          <p><strong>Deployment:</strong> Docker + EC2</p>
          <p><strong>API URL:</strong> {API_BASE_URL}</p>
        </div>
      </div>
    </div>
  );
}

export default App;
