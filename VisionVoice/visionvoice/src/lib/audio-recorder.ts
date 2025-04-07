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

import { audioContext } from "./utils";
import AudioRecordingWorklet from "./worklets/audio-processing";
import VolMeterWorket from "./worklets/vol-meter";

import { createCachedWorkletFromSrc } from "./audioworklet-registry";
import EventEmitter from "eventemitter3";

function arrayBufferToBase64(buffer: ArrayBuffer) {
  var binary = "";
  var bytes = new Uint8Array(buffer);
  var len = bytes.byteLength;
  for (var i = 0; i < len; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return window.btoa(binary);
}

export class AudioRecorder extends EventEmitter {
  stream: MediaStream | undefined;
  audioContext: AudioContext | undefined;
  source: MediaStreamAudioSourceNode | undefined;
  recording: boolean = false;
  recordingWorklet: AudioWorkletNode | undefined;
  vuWorklet: AudioWorkletNode | undefined;

  private starting: Promise<void> | null = null;

  constructor(public sampleRate = 16000) {
    super();
  }

  async start() {
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      throw new Error("Could not request user media");
    }

    this.starting = new Promise(async (resolve, reject) => {
      try {
        this.stream = await navigator.mediaDevices.getUserMedia({ 
          audio: {
            echoCancellation: true,
            noiseSuppression: true,
            autoGainControl: true,
            channelCount: 1,
          } 
        });
        this.audioContext = await audioContext({ sampleRate: this.sampleRate });
        this.source = this.audioContext.createMediaStreamSource(this.stream);

        // Check if running on mobile - fallback to simpler audio processing
        const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
        
        if (isMobile) {
          console.log("Mobile device detected, using simplified audio processing");
          this.useFallbackAudioProcessing();
          resolve();
          return;
        }

        const workletName = "audio-recorder-worklet";
        const src = createCachedWorkletFromSrc(workletName, AudioRecordingWorklet);

        try {
          await this.audioContext.audioWorklet.addModule(src);
          this.recordingWorklet = new AudioWorkletNode(
            this.audioContext,
            workletName,
          );

          this.recordingWorklet.port.onmessage = async (ev: MessageEvent) => {
            // worklet processes recording floats and messages converted buffer
            const arrayBuffer = ev.data.data.int16arrayBuffer;

            if (arrayBuffer) {
              const arrayBufferString = arrayBufferToBase64(arrayBuffer);
              this.emit("data", arrayBufferString);
            }
          };
          this.source.connect(this.recordingWorklet);

          // vu meter worklet
          const vuWorkletName = "vu-meter";
          await this.audioContext.audioWorklet.addModule(
            createCachedWorkletFromSrc(vuWorkletName, VolMeterWorket),
          );
          this.vuWorklet = new AudioWorkletNode(this.audioContext, vuWorkletName);
          this.vuWorklet.port.onmessage = (ev: MessageEvent) => {
            this.emit("volume", ev.data.volume);
          };

          this.source.connect(this.vuWorklet);
          this.recording = true;
          resolve();
        } catch (error) {
          console.error("Error loading audio worklets:", error);
          // Fallback to simpler audio processing without worklets
          this.useFallbackAudioProcessing();
          resolve();
        }
      } catch (error) {
        console.error("Error starting audio recording:", error);
        reject(error);
      }
      this.starting = null;
    });
    return this.starting;
  }

  // Fallback method that uses ScriptProcessorNode instead of AudioWorklet
  private useFallbackAudioProcessing() {
    if (!this.audioContext || !this.source) return;
    
    console.log("Using fallback audio processing method");
    
    // Use ScriptProcessorNode (deprecated but more compatible)
    const bufferSize = 4096;
    const scriptNode = this.audioContext.createScriptProcessor(
      bufferSize, 
      1, // input channels
      1  // output channels
    );
    
    const sampleRate = this.audioContext.sampleRate;
    const buffer = new Int16Array(bufferSize);
    let bufferIndex = 0;
    
    scriptNode.onaudioprocess = (audioProcessingEvent) => {
      const inputBuffer = audioProcessingEvent.inputBuffer;
      const inputData = inputBuffer.getChannelData(0);
      
      // Calculate volume for visualization
      let sum = 0;
      for (let i = 0; i < inputData.length; i++) {
        sum += inputData[i] * inputData[i];
      }
      const volume = Math.sqrt(sum / inputData.length);
      this.emit("volume", volume);
      
      // Convert to Int16 and send
      for (let i = 0; i < inputData.length; i++) {
        buffer[bufferIndex++] = inputData[i] * 32768;
        
        if (bufferIndex >= buffer.length) {
          const arrayBufferString = arrayBufferToBase64(buffer.buffer);
          this.emit("data", arrayBufferString);
          bufferIndex = 0;
        }
      }
    };
    
    this.source.connect(scriptNode);
    scriptNode.connect(this.audioContext.destination);
    this.recording = true;
  }

  stop() {
    // its plausible that stop would be called before start completes
    // such as if the websocket immediately hangs up
    const handleStop = () => {
      this.source?.disconnect();
      this.stream?.getTracks().forEach((track) => track.stop());
      this.stream = undefined;
      this.recordingWorklet = undefined;
      this.vuWorklet = undefined;
    };
    if (this.starting) {
      this.starting.then(handleStop);
      return;
    }
    handleStop();
  }
}
