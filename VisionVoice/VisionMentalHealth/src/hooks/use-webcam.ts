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
import { UseMediaStreamResult } from "./use-media-stream-mux";

export function useWebcam(): UseMediaStreamResult {
  const [stream, setStream] = useState<MediaStream | null>(null);
  const [isStreaming, setIsStreaming] = useState(false);
  const [isBackCamera, setIsBackCamera] = useState(false);

  useEffect(() => {
    const handleStreamEnded = () => {
      setIsStreaming(false);
      setStream(null);
    };
    if (stream) {
      stream
        .getTracks()
        .forEach((track) => track.addEventListener("ended", handleStreamEnded));
      return () => {
        stream
          .getTracks()
          .forEach((track) =>
            track.removeEventListener("ended", handleStreamEnded),
          );
      };
    }
  }, [stream]);

  const start = async () => {
    // For mobile devices, check if we can get the available video devices first
    try {
      const devices = await navigator.mediaDevices.enumerateDevices();
      const videoDevices = devices.filter(device => device.kind === 'videoinput');
      
      // Mobile devices typically have the back camera listed first or have "back" in the label
      const hasMultipleCameras = videoDevices.length > 1;
      
      if (hasMultipleCameras) {
        console.log("Multiple cameras detected:", videoDevices.map(d => d.label));
      }
      
      // Try to use back camera first with exact constraint
      try {
        const mediaStream = await navigator.mediaDevices.getUserMedia({
          video: {
            facingMode: { exact: "environment" },
            width: { ideal: 1280 },
            height: { ideal: 720 }
          }
        });
        setStream(mediaStream);
        setIsStreaming(true);
        setIsBackCamera(true);
        console.log("Using back camera (environment exact)");
        return mediaStream;
      } catch (error) {
        console.log("Exact environment mode failed, trying with preference:", error);
        
        // Try with ideal preference instead of exact requirement
        try {
          const mediaStream = await navigator.mediaDevices.getUserMedia({
            video: {
              facingMode: { ideal: "environment" },
              width: { ideal: 1280 },
              height: { ideal: 720 }
            }
          });
          setStream(mediaStream);
          setIsStreaming(true);
          setIsBackCamera(true);
          console.log("Using preferred back camera");
          return mediaStream;
        } catch (error) {
          console.log("Preferred environment mode failed too:", error);
          
          // If on mobile with multiple cameras, try getting the back camera by index
          if (hasMultipleCameras) {
            try {
              // On many mobile devices, the back camera is the first in the list
              const backCameraId = videoDevices[0].deviceId;
              
              const mediaStream = await navigator.mediaDevices.getUserMedia({
                video: {
                  deviceId: { exact: backCameraId },
                  width: { ideal: 1280 },
                  height: { ideal: 720 }
                }
              });
              setStream(mediaStream);
              setIsStreaming(true);
              setIsBackCamera(true);
              console.log("Using first camera from device list as back camera");
              return mediaStream;
            } catch (error) {
              console.log("Failed to use first camera:", error);
            }
          }
          
          // Last resort: use any available camera
          console.log("Using any available camera");
          const mediaStream = await navigator.mediaDevices.getUserMedia({
            video: true
          });
          setStream(mediaStream);
          setIsStreaming(true);
          setIsBackCamera(false);
          return mediaStream;
        }
      }
    } catch (error) {
      console.error("Error enumerating devices:", error);
      
      // Fallback to simple camera access if device enumeration fails
      try {
        const mediaStream = await navigator.mediaDevices.getUserMedia({
          video: true
        });
        setStream(mediaStream);
        setIsStreaming(true);
        setIsBackCamera(false);
        console.log("Using fallback camera (enumeration failed)");
        return mediaStream;
      } catch (cameraError) {
        console.error("Failed to access any camera:", cameraError);
        throw cameraError;
      }
    }
  };

  const stop = () => {
    if (stream) {
      stream.getTracks().forEach((track) => track.stop());
      setStream(null);
      setIsStreaming(false);
      setIsBackCamera(false);
    }
  };

  const result: UseMediaStreamResult = {
    type: "webcam",
    start,
    stop,
    isStreaming,
    stream,
    isBackCamera
  };

  return result;
}
