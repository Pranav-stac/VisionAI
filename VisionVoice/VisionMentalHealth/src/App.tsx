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
            padding: '10px',
            backgroundColor: 'var(--Blue-800)',
            zIndex: 100,
            textAlign: 'center'
          }}>
            <h1 style={{ 
              margin: 0, 
              fontSize: '1.2rem',
              color: 'white'
            }}>
              Mental Health Assistant
            </h1>
          </header>
     
          <main style={{ marginTop: '50px' }}>
            <div className="main-app-area" style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              padding: '15px',
              backgroundColor: 'white',
              maxWidth: '800px',
              margin: '0 auto',
              position: 'relative'
            }}>
              {/* APP goes here */}
              <Altair />
            </div>

            <ControlTray supportsVideo={false} />

            {/* Voice indicator */}
            <div style={{
              position: 'fixed',
              bottom: '20px',
              right: '20px',
              backgroundColor: 'var(--Blue-500)',
              color: 'white',
              padding: '5px 10px',
              borderRadius: '4px',
              fontSize: '12px',
              zIndex: 10
            }}>
              VOICE ACTIVE
            </div>
          </main>
        </div>
      </LiveAPIProvider>
    </div>
  );
}

export default App;
