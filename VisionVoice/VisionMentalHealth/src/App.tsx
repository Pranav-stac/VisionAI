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
  
  const location = useLocation();
  const currentPath = location.pathname;

  useEffect(() => {
    const mobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
    setIsMobile(mobile);
    
    // Add the Inter font if it's not already in the document
    if (!document.getElementById('inter-font')) {
      const link = document.createElement('link');
      link.id = 'inter-font';
      link.rel = 'stylesheet';
      link.href = 'https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap';
      document.head.appendChild(link);
    }
    
    // Add Material Symbols for icons
    if (!document.getElementById('material-symbols')) {
      const link = document.createElement('link');
      link.id = 'material-symbols';
      link.rel = 'stylesheet';
      link.href = 'https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200';
      document.head.appendChild(link);
    }
  }, [currentPath]);

  return (
    <div className="App">
      <LiveAPIProvider url={uri} apiKey={API_KEY}>
        <div className="streaming-console">
          {/* Dynamic background with subtle gradient animation */}
          <div 
            style={{
              position: 'fixed',
              top: 0,
              left: 0,
              width: '100vw',
              height: '100vh',
              background: 'radial-gradient(circle at 50% 50%, rgba(30, 30, 45, 0.8), rgba(18, 18, 18, 1))',
              zIndex: -1,
              overflow: 'hidden'
            }}
          >
            {/* Animated gradient orbs in background */}
            <div 
              style={{
                position: 'absolute',
                top: '10%',
                left: '15%',
                width: '30vw',
                height: '30vw',
                borderRadius: '50%',
                background: 'radial-gradient(circle at center, rgba(99, 102, 241, 0.1), transparent 70%)',
                filter: 'blur(60px)',
                animation: 'pulse 15s infinite ease-in-out',
                transformOrigin: 'center'
              }}
            />
            <div 
              style={{
                position: 'absolute',
                bottom: '20%',
                right: '10%',
                width: '25vw',
                height: '25vw',
                borderRadius: '50%',
                background: 'radial-gradient(circle at center, rgba(236, 72, 153, 0.1), transparent 70%)',
                filter: 'blur(60px)',
                animation: 'pulse 18s infinite ease-in-out 2s',
                transformOrigin: 'center'
              }}
            />
            <div 
              style={{
                position: 'absolute',
                top: '60%',
                left: '25%',
                width: '20vw',
                height: '20vw',
                borderRadius: '50%',
                background: 'radial-gradient(circle at center, rgba(147, 51, 234, 0.1), transparent 70%)',
                filter: 'blur(50px)',
                animation: 'pulse 12s infinite ease-in-out 1s',
                transformOrigin: 'center'
              }}
            />
          </div>

          <header className="glass-card" style={{
            position: 'fixed',
            top: '20px',
            left: '50%',
            transform: 'translateX(-50%)',
            padding: '12px 25px',
            zIndex: 100,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '10px',
            width: 'auto',
            maxWidth: '90%'
          }}>
            <div style={{
              width: '36px',
              height: '36px',
              borderRadius: '50%',
              background: 'linear-gradient(135deg, var(--primary), var(--tertiary))',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center'
            }}>
              <span className="material-symbols-outlined" style={{ fontSize: '20px', color: 'white' }}>
                psychology
              </span>
            </div>
            <div>
              <h1 className="gradient-text" style={{ 
                margin: 0, 
                fontSize: '1.3rem',
                fontWeight: 700
              }}>
                Mental Health Assistant
              </h1>
            </div>
          </header>
     
          <main style={{ 
            marginTop: '100px',
            width: '100%',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '0 15px'
          }}>
            <div className="glass-card main-app-area" style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              padding: '25px',
              maxWidth: '800px',
              width: '100%',
              margin: '0 auto',
              position: 'relative'
            }}>
              {/* APP goes here */}
              <Altair />
            </div>

            <ControlTray supportsVideo={false} />

            {/* Voice indicator */}
            <div className="glass-card pulse" style={{
              position: 'fixed',
              bottom: '90px',
              right: '25px',
              backgroundColor: 'var(--glass-bg)',
              color: 'var(--on-surface)',
              padding: '8px 15px',
              borderRadius: '30px',
              fontSize: '12px',
              fontWeight: '600',
              zIndex: 10,
              display: 'flex',
              alignItems: 'center',
              gap: '8px'
            }}>
              <span style={{
                width: '8px',
                height: '8px',
                borderRadius: '50%',
                backgroundColor: 'var(--primary)',
                boxShadow: '0 0 10px var(--primary)'
              }}></span>
              VOICE ACTIVE
            </div>
          </main>
        </div>
      </LiveAPIProvider>
    </div>
  );
}

export default App;
