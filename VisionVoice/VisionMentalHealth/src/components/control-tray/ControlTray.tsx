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

import cn from "classnames";

import { memo, ReactNode, RefObject, useEffect, useRef, useState } from "react";
import { useLiveAPIContext } from "../../contexts/LiveAPIContext";
import { UseMediaStreamResult } from "../../hooks/use-media-stream-mux";
import { useScreenCapture } from "../../hooks/use-screen-capture";
import { useWebcam } from "../../hooks/use-webcam";
import { AudioRecorder } from "../../lib/audio-recorder";
import AudioPulse from "../audio-pulse/AudioPulse";
import "./control-tray.scss";

export type ControlTrayProps = {
  videoRef?: RefObject<HTMLVideoElement>;
  children?: ReactNode;
  supportsVideo: boolean;
  onVideoStreamChange?: (stream: MediaStream | null) => void;
};

type MediaStreamButtonProps = {
  isStreaming: boolean;
  onIcon: string;
  offIcon: string;
  start: () => Promise<any>;
  stop: () => any;
};

/**
 * button used for triggering webcam or screen-capture
 */
const MediaStreamButton = memo(
  ({ isStreaming, onIcon, offIcon, start, stop }: MediaStreamButtonProps) =>
    isStreaming ? (
      <button className="action-button" onClick={stop}>
        <span className="material-symbols-outlined">{onIcon}</span>
      </button>
    ) : (
      <button className="action-button" onClick={start}>
        <span className="material-symbols-outlined">{offIcon}</span>
      </button>
    ),
);

function ControlTray({
  videoRef,
  children,
  onVideoStreamChange = () => {},
  supportsVideo,
}: ControlTrayProps) {
  // Always call hooks unconditionally
  const webcam = useWebcam();
  const screenCapture = useScreenCapture();
  
  // Then use the results conditionally
  const videoStreams = supportsVideo ? [webcam, screenCapture] : [];
  
  const [activeVideoStream, setActiveVideoStream] = useState<MediaStream | null>(null);
  const [inVolume, setInVolume] = useState(0);
  const [audioRecorder] = useState(() => new AudioRecorder());
  const [muted, setMuted] = useState(false);
  const renderCanvasRef = useRef<HTMLCanvasElement>(null);
  const connectButtonRef = useRef<HTMLButtonElement>(null);

  const { client, connected, connect, disconnect, volume } =
    useLiveAPIContext();

  // Auto-connect when component mounts
  useEffect(() => {
    // Wait a moment before auto-connecting to ensure everything is loaded
    const timer = setTimeout(() => {
      if (!connected) {
        connect();
      }
    }, 1000);
    return () => clearTimeout(timer);
  }, []);

  // Auto-enable webcam when connection is established (only if video is supported)
  useEffect(() => {
    if (connected && !activeVideoStream && supportsVideo) {
      // Auto-enable webcam when connected
      changeStreams(webcam)();
    }
  }, [connected, activeVideoStream, supportsVideo, webcam]);

  useEffect(() => {
    if (!connected && connectButtonRef.current) {
      connectButtonRef.current.focus();
    }
  }, [connected]);
  
  useEffect(() => {
    document.documentElement.style.setProperty(
      "--volume",
      `${Math.max(5, Math.min(inVolume * 200, 8))}px`,
    );
  }, [inVolume]);

  // Audio handling
  useEffect(() => {
    const onData = (base64: string) => {
      client.sendRealtimeInput([
        {
          mimeType: "audio/pcm;rate=16000",
          data: base64,
        },
      ]);
    };
    if (connected && !muted && audioRecorder) {
      audioRecorder.on("data", onData).on("volume", setInVolume).start();
    } else {
      audioRecorder.stop();
    }
    return () => {
      audioRecorder.off("data", onData).off("volume", setInVolume);
    };
  }, [connected, client, muted, audioRecorder]);

  // Video handling - only if video is supported
  useEffect(() => {
    // Skip the entire effect if video is not supported or videoRef doesn't exist
    if (!supportsVideo || !videoRef || !videoRef.current) return;

    // Set the video stream to the video element
    videoRef.current.srcObject = activeVideoStream;

    let timeoutId = -1;

    // Function to send video frames
    function sendVideoFrame() {
      // Skip if video or canvas is not available
      if (!videoRef?.current || !renderCanvasRef.current) return;

      const video = videoRef.current;
      const canvas = renderCanvasRef.current;
      const ctx = canvas.getContext("2d");
      
      if (!ctx) return;

      // Set canvas dimensions based on video
      canvas.width = video.videoWidth * 0.2;
      canvas.height = video.videoHeight * 0.2;
      
      // Only send frame if canvas has dimensions
      if (canvas.width > 0 && canvas.height > 0) {
        ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
        const base64 = canvas.toDataURL("image/jpeg", 0.7);
        const data = base64.slice(base64.indexOf(",") + 1, Infinity);
        client.sendRealtimeInput([{ mimeType: "image/jpeg", data }]);
      }
      
      // Continue sending frames if still connected
      if (connected) {
        timeoutId = window.setTimeout(sendVideoFrame, 1000 / 2);
      }
    }

    // Start sending frames if connected and has active video stream
    if (connected && activeVideoStream !== null) {
      requestAnimationFrame(sendVideoFrame);
    }

    // Clean up on unmount or when dependencies change
    return () => {
      clearTimeout(timeoutId);
    };
  }, [connected, activeVideoStream, client, videoRef, supportsVideo]);

  // Handler for swapping from one video-stream to the next
  const changeStreams = (next?: UseMediaStreamResult) => async () => {
    if (!supportsVideo) return;
    
    if (next) {
      const mediaStream = await next.start();
      setActiveVideoStream(mediaStream);
      onVideoStreamChange(mediaStream);
    } else {
      setActiveVideoStream(null);
      onVideoStreamChange(null);
    }

    videoStreams.filter((msr) => msr !== next).forEach((msr) => msr.stop());
  };

  return (
    <section className="control-tray">
      {supportsVideo && <canvas style={{ display: "none" }} ref={renderCanvasRef} />}
      <nav className={cn("actions-nav", { disabled: !connected })}>
        <button
          className={cn("action-button mic-button", { active: !muted && inVolume > 0.05 })}
          onClick={() => setMuted(!muted)}
        >
          {!muted ? (
            <span className="material-symbols-outlined filled">mic</span>
          ) : (
            <span className="material-symbols-outlined filled">mic_off</span>
          )}
          {!muted && inVolume > 0.05 && (
            <span className="voice-indicator" style={{ 
              position: 'absolute', 
              top: '-5px', 
              right: '-5px', 
              width: '10px', 
              height: '10px', 
              borderRadius: '50%', 
              backgroundColor: '#00ff00',
              boxShadow: '0 0 5px #00ff00'
            }}></span>
          )}
        </button>

        <div className="action-button no-action outlined">
          <AudioPulse volume={volume} active={connected} hover={false} />
        </div>

        {supportsVideo && (
          <>
            <MediaStreamButton
              isStreaming={screenCapture.isStreaming}
              start={changeStreams(screenCapture)}
              stop={changeStreams()}
              onIcon="cancel_presentation"
              offIcon="present_to_all"
            />
            <MediaStreamButton
              isStreaming={webcam.isStreaming}
              start={changeStreams(webcam)}
              stop={changeStreams()}
              onIcon="videocam_off"
              offIcon="videocam"
            />
            {webcam.isStreaming && (
              <div className="camera-type-indicator" style={{
                fontSize: '10px',
                position: 'absolute',
                bottom: '32px',
                right: '86px',
                color: 'white',
                backgroundColor: 'rgba(0,0,0,0.5)',
                padding: '2px 4px',
                borderRadius: '4px'
              }}>
                {webcam.isBackCamera ? 'BACK CAM' : 'FRONT CAM'}
              </div>
            )}
          </>
        )}
        {children}
      </nav>

      <div className={cn("connection-container", { connected })}>
        <div className="connection-button-container">
          <button
            ref={connectButtonRef}
            className={cn("action-button connect-toggle", { connected })}
            onClick={connected ? disconnect : connect}
          >
            {connected ? (
              <span className="material-symbols-outlined filled">call_end</span>
            ) : (
              <span className="material-symbols-outlined">call</span>
            )}
          </button>
        </div>
        <div className="text-indicator">{connected ? "Connected" : ""}</div>
      </div>
    </section>
  );
}

export default memo(ControlTray);
