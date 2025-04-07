/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { useState, useEffect } from "react";
import "./App.scss";
import { LiveAPIProvider } from "./contexts/LiveAPIContext";
import { Altair } from "./components/altair/Altair";
import ControlTray from "./components/control-tray/ControlTray";
import { useLocation } from "react-router-dom";

const API_KEY = process.env.REACT_APP_GEMINI_API_KEY as string;
if (typeof API_KEY !== "string") {
  throw new Error("set REACT_APP_GEMINI_API_KEY in .env");
}

const host = "generativelanguage.googleapis.com";
const uri = `wss://${host}/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent`;

function App() {
  const [isMobile, setIsMobile] = useState(false);
  
  // Get current route
  const location = useLocation();
  const currentPath = location.pathname;

  useEffect(() => {
    // Check if on mobile device
    const mobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
    setIsMobile(mobile);
    console.log("Device detected:", mobile ? "Mobile" : "Desktop");
    console.log("Current path:", currentPath);
  }, [currentPath]);

  return (
    <div className="App">
      <LiveAPIProvider url={uri} apiKey={API_KEY}>
        <div className="streaming-console">
          <header className="app-header" style={{
            position: 'fixed',
            top: 0,
            left: 0,
            width: '100%',
            padding: '10px 20px',
            background: 'linear-gradient(to right, var(--Blue-800), var(--Neutral-5))',
            zIndex: 100,
            textAlign: 'center',
            boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
          }}>
            <h1 style={{ 
              margin: 0, 
              fontSize: isMobile ? '1.2rem' : '1.5rem',
              color: 'var(--Neutral-90)',
              fontWeight: 'normal'
            }}>
              <span style={{ color: 'var(--Blue-500)', fontWeight: 'bold' }}>Therapeutic</span>Connect
            </h1>
            <p style={{ 
              margin: '5px 0 0', 
              fontSize: isMobile ? '0.8rem' : '0.9rem',
              color: 'var(--Neutral-80)',
              fontStyle: 'italic'
            }}>
              Dr. Ellis, PhD • Clinical Psychologist {currentPath === '/mentalhealth' && '• CBT Specialist'}
            </p>
          </header>
     
          <main style={{ marginTop: '70px' }}>
            <div className="main-app-area" style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              padding: '25px',
              backgroundColor: 'var(--Neutral-00)',
              borderRadius: '12px',
              boxShadow: '0 4px 15px rgba(0, 0, 0, 0.08)',
              maxWidth: '950px',
              margin: '0 auto 20px auto',
              position: 'relative'
            }}>
              <div style={{
                width: '100%',
                textAlign: 'center',
                marginBottom: '20px'
              }}>
                <h2 style={{
                  color: 'var(--Blue-500)',
                  fontWeight: 'normal',
                  fontSize: '1.2rem',
                  margin: '0 0 5px 0'
                }}>
                  Professional Therapy Session
                </h2>
                <p style={{
                  color: 'var(--Neutral-60)',
                  fontSize: '0.9rem',
                  margin: 0
                }}>
                  Speak naturally as you would with your therapist
                </p>
              </div>
              
              {/* Therapy principles */}
              <div style={{
                display: 'flex',
                flexWrap: 'wrap',
                justifyContent: 'center',
                gap: '10px',
                marginBottom: '20px'
              }}>
                {['Confidential', 'Evidence-based', 'Personalized', 'Supportive'].map(tag => (
                  <div key={tag} style={{
                    backgroundColor: 'var(--Blue-800)',
                    color: 'var(--Blue-500)',
                    padding: '4px 10px',
                    borderRadius: '15px',
                    fontSize: '0.8rem',
                    fontWeight: 'bold'
                  }}>
                    {tag}
                  </div>
                ))}
              </div>
              
              {/* APP goes here */}
              <Altair />
            </div>

            <ControlTray supportsVideo={false} />

            {/* Voice Session Message - shown on all devices */}
            <div style={{
              position: 'absolute',
              top: '80px',
              left: '50%',
              transform: 'translateX(-50%)',
              backgroundColor: 'rgba(255, 255, 255, 0.9)',
              color: 'var(--Blue-500)',
              padding: '8px 12px',
              borderRadius: '20px',
              fontSize: '14px',
              fontWeight: 'bold',
              zIndex: 11,
              boxShadow: '0 2px 5px rgba(0,0,0,0.1)',
              border: '1px solid var(--Blue-800)'
            }}>
              VOICE THERAPY ACTIVE
            </div>
          </main>
        </div>
      </LiveAPIProvider>
    </div>
  );
}

export default App;
