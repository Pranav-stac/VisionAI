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

/**
 * A registry to map attached worklets by their audio-context
 * any module using `audioContext.audioWorklet.addModule(` should register the worklet here
 */
export type WorkletGraph = {
  node?: AudioWorkletNode;
  handlers: Array<(this: MessagePort, ev: MessageEvent) => any>;
};

export const registeredWorklets: Map<
  AudioContext,
  Record<string, WorkletGraph>
> = new Map();

/**
 * Helper function that creates a blob URL for the audio worklet code
 */
export function createWorketFromSrc(name: string, src: string): string {
  const blob = new Blob([src], { type: 'application/javascript' });
  return URL.createObjectURL(blob);
}

// Cache the worklet URLs to prevent recreation
const workletCache = new Map<string, string>();

/**
 * Improved function that caches worklet URLs to avoid repeated creation
 */
export function createCachedWorkletFromSrc(name: string, src: string): string {
  if (!workletCache.has(name)) {
    const url = createWorketFromSrc(name, src);
    workletCache.set(name, url);
    return url;
  }
  return workletCache.get(name)!;
}

// Cleanup function to release any blob URLs when they're no longer needed
export function cleanupWorkletURLs(): void {
  workletCache.forEach(url => {
    URL.revokeObjectURL(url);
  });
  workletCache.clear();
}
