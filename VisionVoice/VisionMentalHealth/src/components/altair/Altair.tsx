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
import { type FunctionDeclaration, SchemaType } from "@google/generative-ai";
import { useEffect, useRef, useState, memo } from "react";
import vegaEmbed from "vega-embed";
import { useLiveAPIContext } from "../../contexts/LiveAPIContext";
import { ToolCall } from "../../multimodal-live-types";
import { useLocation } from "react-router-dom";

const declaration: FunctionDeclaration = {
  name: "render_altair",
  description: "Displays an altair graph in json format.",
  parameters: {
    type: SchemaType.OBJECT,
    properties: {
      json_graph: {
        type: SchemaType.STRING,
        description:
          "JSON STRING representation of the graph to render. Must be a string, not a json object",
      },
    },
    required: ["json_graph"],
  },
};

function AltairComponent() {
  const [jsonString, setJSONString] = useState<string>("");
  const { client, setConfig } = useLiveAPIContext();
  const location = useLocation();
  const currentPath = location.pathname;
  const isMentalHealthRoute = currentPath === '/mentalhealth';

  useEffect(() => {
    // Define the systemText instructions based on route
    const systemText = `I am Dr. Ellis, a licensed clinical psychologist with 15 years of experience in cognitive-behavioral therapy, mindfulness-based interventions, and trauma-informed care. 

I'm here with you for a voice-only therapy session. I'll listen carefully to your concerns and respond with empathy and professional guidance.

My therapeutic approach emphasizes creating a safe, confidential space where you can explore your thoughts and feelings without judgment. I practice active listening and validate your unique experiences.

During our session, I'll use therapeutic techniques like:
- Cognitive reframing to help identify and transform negative thought patterns
- Guided mindfulness exercises for grounding during moments of distress
- Strengths-based reflection to recognize your inherent capabilities
- Motivational interviewing to explore ambivalence about change
- Emotion-focused techniques to process difficult feelings in a healthy way

I'll offer personalized coping strategies based on evidence-based practices while respecting your agency and autonomy. I'll check in with you regularly to ensure my approach resonates with your needs.

While I can provide emotional support and therapeutic guidance, I cannot diagnose conditions or prescribe medications. For clinical diagnoses, medication management, or crisis situations, I'll recommend connecting with a licensed healthcare provider in your area.

How are you feeling today? We can start wherever feels most comfortable for you.`;

    setConfig({
      model: "models/gemini-2.0-flash-exp",
      generationConfig: {
        responseModalities: "audio",
        speechConfig: {
          voiceConfig: { prebuiltVoiceConfig: { voiceName: "Aoede" } },
        },
      },
      systemInstruction: {
        parts: [
          {
            text: systemText,
          },
        ],
      },
      tools: [
        // there is a free-tier quota for search
        { googleSearch: {} },
        { functionDeclarations: [declaration] },
      ],
    });
    
    console.log(`Running in mode: ${isMentalHealthRoute ? 'Mental Health Route' : 'Default Route'}`);
    
  }, [setConfig, isMentalHealthRoute, currentPath]);

  useEffect(() => {
    const onToolCall = (toolCall: ToolCall) => {
      console.log(`got toolcall`, toolCall);
      const fc = toolCall.functionCalls.find(
        (fc) => fc.name === declaration.name,
      );
      if (fc) {
        const str = (fc.args as any).json_graph;
        setJSONString(str);
      }
      // send data for the response of your tool call
      // in this case Im just saying it was successful
      if (toolCall.functionCalls.length) {
        setTimeout(
          () =>
            client.sendToolResponse({
              functionResponses: toolCall.functionCalls.map((fc) => ({
                response: { output: { success: true } },
                id: fc.id,
              })),
            }),
          200,
        );
      }
    };
    client.on("toolcall", onToolCall);
    return () => {
      client.off("toolcall", onToolCall);
    };
  }, [client]);

  const embedRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (embedRef.current && jsonString) {
      vegaEmbed(embedRef.current, JSON.parse(jsonString), {
        theme: 'dark', // Use dark theme for the charts
        config: {
          background: 'transparent',
          axis: {
            labelColor: 'rgba(229, 231, 235, 0.8)',
            titleColor: 'rgba(229, 231, 235, 0.9)',
            gridColor: 'rgba(255, 255, 255, 0.1)',
            domainColor: 'rgba(255, 255, 255, 0.2)'
          },
          legend: {
            labelColor: 'rgba(229, 231, 235, 0.8)',
            titleColor: 'rgba(229, 231, 235, 0.9)'
          },
          title: {
            color: 'rgba(229, 231, 235, 1)'
          }
        }
      });
    }
  }, [embedRef, jsonString]);
  
  return (
    <>
      {isMentalHealthRoute && (
        <div className="glass-card" style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          marginBottom: '30px',
          width: '100%',
          padding: '20px',
          borderRadius: '20px'
        }}>
          <div style={{
            display: 'flex',
            alignItems: 'center',
            marginBottom: '20px',
            padding: '15px',
            borderRadius: '16px',
            background: 'rgba(30, 30, 45, 0.5)',
            width: '100%',
            maxWidth: '500px',
            boxShadow: '0 10px 30px rgba(0, 0, 0, 0.15)',
            border: '1px solid rgba(255, 255, 255, 0.05)',
            boxSizing: 'border-box'
          }}>
            <div style={{
              minWidth: '60px',
              width: '60px',
              height: '60px',
              borderRadius: '50%',
              background: 'linear-gradient(135deg, var(--primary), var(--tertiary))',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              marginRight: '15px',
              color: 'white',
              fontWeight: 'bold',
              fontSize: '24px',
              boxShadow: '0 8px 20px rgba(99, 102, 241, 0.3)'
            }}>
              <span className="material-symbols-outlined filled" style={{ fontSize: '28px' }}>psychology</span>
            </div>
            <div>
              <div style={{ 
                fontWeight: 'bold', 
                color: 'var(--on-surface)', 
                fontSize: '16px',
                marginBottom: '4px'
              }}>Dr. Sarah Ellis, PhD</div>
              <div style={{ 
                fontSize: '13px', 
                color: 'rgba(229, 231, 235, 0.7)',
                marginBottom: '6px'
              }}>Licensed Clinical Psychologist</div>
              <div className="gradient-text" style={{ 
                fontSize: '12px', 
                marginTop: '3px'
              }}>CBT Specialist • Anxiety & Depression • Trauma</div>
            </div>
          </div>
          <div className="glass-card neon-glow" style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '8px',
            background: 'rgba(99, 102, 241, 0.15)',
            color: 'var(--primary)',
            padding: '8px 16px',
            borderRadius: '30px',
            fontSize: '12px',
            fontWeight: 'bold',
            marginBottom: '20px',
            border: '1px solid rgba(99, 102, 241, 0.3)'
          }}>
            <span className="material-symbols-outlined" style={{ fontSize: '14px' }}>headphones</span>
            VOICE-ONLY THERAPY SESSION
          </div>
          <p style={{ 
            fontSize: '14px', 
            color: 'rgba(229, 231, 235, 0.8)',
            fontStyle: 'italic',
            textAlign: 'center',
            maxWidth: '450px',
            lineHeight: '1.5',
            letterSpacing: '0.2px'
          }}>
            Speak naturally to begin your session with Dr. Ellis.
            Your voice interactions are confidential and secure.
          </p>
        </div>
      )}
      <div className="vega-embed glass-card" ref={embedRef} style={{
        width: '100%',
        padding: '20px',
        borderRadius: '16px',
        backgroundColor: 'rgba(30, 30, 45, 0.5)',
        border: '1px solid rgba(255, 255, 255, 0.05)',
        minHeight: '200px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center'
      }}>
        {!jsonString && (
          <div style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '20px',
            textAlign: 'center',
            width: '100%'
          }}>
            <div className="pulse" style={{
              width: '70px',
              height: '70px',
              borderRadius: '50%',
              background: 'linear-gradient(135deg, var(--primary) 0%, var(--tertiary) 100%)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              marginBottom: '20px',
              boxShadow: '0 0 20px rgba(99, 102, 241, 0.4)'
            }}>
              <span className="material-symbols-outlined" style={{ 
                fontSize: '35px', 
                color: 'white'
              }}>
                record_voice_over
              </span>
            </div>
            <h3 className="gradient-text" style={{ 
              fontSize: '18px', 
              marginBottom: '15px',
              fontWeight: '600'
            }}>
              Your Mental Health Assistant
            </h3>
            <p style={{ 
              color: 'rgba(229, 231, 235, 0.7)',
              fontSize: '14px',
              maxWidth: '400px',
              lineHeight: '1.6'
            }}>
              Speak or type to start a conversation. 
              I'm here to listen, understand, and provide guidance 
              for your mental wellbeing journey.
            </p>
          </div>
        )}
      </div>
    </>
  );
}

export const Altair = memo(AltairComponent);
