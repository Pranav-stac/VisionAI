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

import { useRef, useState, useEffect } from "react";
import "./App.scss";
import { LiveAPIProvider } from "./contexts/LiveAPIContext";
import SidePanel from "./components/side-panel/SidePanel";
import { Altair } from "./components/altair/Altair";
import ControlTray from "./components/control-tray/ControlTray";
import cn from "classnames";

const API_KEY = process.env.REACT_APP_GEMINI_API_KEY as string;
if (typeof API_KEY !== "string") {
  throw new Error("set REACT_APP_GEMINI_API_KEY in .env");
}

const host = "generativelanguage.googleapis.com";
const uri = `wss://${host}/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent`;

function App() {
  // this video reference is used for displaying the active stream, whether that is the webcam or screen capture
  // feel free to style as you see fit
  const videoRef = useRef<HTMLVideoElement>(null);
  // either the screen capture, the video or null, if null we hide it
  const [videoStream, setVideoStream] = useState<MediaStream | null>(null);
  const [cameraPermission, setCameraPermission] = useState<'granted' | 'denied' | 'prompt'>('prompt');
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    // Check if on mobile device
    const mobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
    setIsMobile(mobile);
    console.log("Device detected:", mobile ? "Mobile" : "Desktop");
    
    // Check for existing camera permissions
    if (navigator.permissions && navigator.permissions.query) {
      navigator.permissions.query({ name: 'camera' as PermissionName })
        .then(status => {
          setCameraPermission(status.state as 'granted' | 'denied' | 'prompt');
          
          // Listen for permission changes
          status.onchange = () => {
            setCameraPermission(status.state as 'granted' | 'denied' | 'prompt');
          };
        })
        .catch(err => {
          console.error("Error checking camera permission:", err);
        });
    }
  }, []);

  // Add this description component near where the video stream is rendered
  const StreamDescription = () => {
    const isMobile = window.innerWidth <= 768;
    
    if (!isMobile) return null;
    
    return (
      <div className="stream-description">
        <div className="description-text">
          <span className="highlight">Vision AI</span> brings the digital world to life through your ears
        </div>
      </div>
    );
  };

  return (
    <div className="App">
      <LiveAPIProvider url={uri} apiKey={API_KEY}>
        <div className="streaming-console">
     
          <main>
            <div className="main-app-area">
              {/* Position video centered for voice with camera mode */}
              <div style={{ position: 'relative', width: '100%', height: '100%' }}>
                <video
                  className={cn("stream", {
                    hidden: !videoRef.current || !videoStream,
                  })}
                  ref={videoRef}
                  autoPlay
                  playsInline
                  muted
                />
                {videoStream && (
                  <div style={{
                    position: 'absolute',
             
                    left: '50%',
                    transform: 'translateX(-50%)',
                    backgroundColor: 'rgba(0, 0, 0, 0.6)',
                    top: '25px',
                    color: 'white',
                    padding: '6px 12px',
                    borderRadius: '8px',
                    fontSize: isMobile ? '16px' : '12px',
                    fontWeight: 'bold',
                    zIndex: 11,
                    letterSpacing: '1px',
                    boxShadow: '0 2px 8px rgba(0,0,0,0.3)',
                    backdropFilter: 'blur(4px)',
                    border: '1px solid rgba(255, 255, 255, 0.2)'
                  }}>
                    VISION AI
                  </div>
                )}
                {cameraPermission === 'denied' && (
                  <div style={{
                    position: 'absolute',
                    top: '50%',
                    left: '50%',
                    transform: 'translate(-50%, -50%)',
                    backgroundColor: 'rgba(220, 53, 69, 0.9)',
                    color: 'white',
                    padding: '16px 20px',
                    borderRadius: '12px',
                    textAlign: 'center',
                    zIndex: 100,
                    maxWidth: '90%',
                    boxShadow: '0 8px 20px rgba(0,0,0,0.4)',
                    backdropFilter: 'blur(8px)'
                  }}>
                    <div style={{ fontSize: '20px', marginBottom: '12px', fontWeight: 'bold' }}>Camera Permission Required</div>
                    <div style={{ fontSize: '16px', lineHeight: '1.4' }}>Please enable camera access in your browser settings to use this app.</div>
                  </div>
                )}
                <StreamDescription />
              </div>
              
              {/* APP goes here */}
              <Altair />
            </div>

            <ControlTray
              videoRef={videoRef}
              supportsVideo={true}
              onVideoStreamChange={setVideoStream}
            >
              {/* put your own buttons here */}
            </ControlTray>
          </main>
        </div>
      </LiveAPIProvider>
    </div>
  );
}

export default App;
