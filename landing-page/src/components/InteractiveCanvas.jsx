import React, { useState, useEffect } from 'react';
import { 
  Edit3, Hand, GitCommit, Image, Eraser, 
  Sparkles, Type, ZoomIn, ZoomOut, RotateCcw, Trash2, 
  Network, Database, ShieldAlert, Cpu, ArrowRightLeft,
  Server, Layers, ArrowUpRight
} from 'lucide-react';

export default function InteractiveCanvas() {
  const [activeTool, setActiveTool] = useState('pen'); // pen, hand, connector, diagram, eraser
  const [shapeDetection, setShapeDetection] = useState(true);
  const [handwriting, setHandwriting] = useState(false);
  const [zoom, setZoom] = useState(100);
  const [canvasMode, setCanvasMode] = useState('dsa'); // dsa, system
  const [isTreeInverted, setIsTreeInverted] = useState(false);
  const [roughCircleToggled, setRoughCircleToggled] = useState(false);

  // Auto-animate shape detection illustration on mount/interval
  useEffect(() => {
    const timer = setInterval(() => {
      setRoughCircleToggled(prev => !prev);
    }, 4000);
    return () => clearInterval(timer);
  }, []);

  const resetCanvas = () => {
    setIsTreeInverted(false);
    setRoughCircleToggled(false);
  };

  return (
    <div className="flex-1 h-full flex flex-col relative overflow-hidden bg-[#0A0A0C] border border-white/5 rounded-2xl shadow-2xl">
      {/* Grid Pattern Background */}
      <div className="absolute inset-0 opacity-10 pointer-events-none" style={{
        backgroundImage: 'radial-gradient(circle, #ffffff 1px, transparent 1px)',
        backgroundSize: '24px 24px'
      }} />

      {/* Floating Canvas Mode Selectors */}
      <div className="absolute top-4 left-4 z-10 flex gap-2">
        <button
          onClick={() => { setCanvasMode('dsa'); resetCanvas(); }}
          className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer ${canvasMode === 'dsa' ? 'bg-blue-600 text-white shadow-lg' : 'bg-white/5 text-gray-400 hover:bg-white/10'}`}
        >
          DSA Mode
        </button>
        <button
          onClick={() => { setCanvasMode('system'); resetCanvas(); }}
          className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer ${canvasMode === 'system' ? 'bg-blue-600 text-white shadow-lg' : 'bg-white/5 text-gray-400 hover:bg-white/10'}`}
        >
          System Design Mode
        </button>
      </div>

      {/* Intelligence & Zoom Controls (Upper Floating Panel) */}
      <div className="absolute top-4 right-4 z-10 flex items-center gap-2 bg-[#1E1E24]/80 backdrop-blur-md px-3 py-1.5 rounded-xl border border-white/5 shadow-xl">
        {/* AI toggles */}
        <button
          onClick={() => setShapeDetection(!shapeDetection)}
          title="Shape Detector (AI)"
          className={`p-1.5 rounded-lg transition-colors cursor-pointer ${shapeDetection ? 'text-blue-400 bg-blue-500/10' : 'text-gray-400 hover:bg-white/5'}`}
        >
          <Sparkles size={16} />
        </button>
        <button
          onClick={() => setHandwriting(!handwriting)}
          title="Paint to Text (ML Handwriting)"
          className={`p-1.5 rounded-lg transition-colors cursor-pointer ${handwriting ? 'text-blue-400 bg-blue-500/10' : 'text-gray-400 hover:bg-white/5'}`}
        >
          <Type size={16} />
        </button>

        <div className="h-4 w-px bg-white/10 mx-1" />

        {/* Zoom */}
        <button onClick={() => setZoom(Math.max(60, zoom - 10))} className="p-1.5 rounded-lg text-gray-400 hover:bg-white/5 cursor-pointer">
          <ZoomOut size={16} />
        </button>
        <span className="text-[10px] font-bold text-gray-400 min-w-8 text-center">{zoom}%</span>
        <button onClick={() => setZoom(Math.min(150, zoom + 10))} className="p-1.5 rounded-lg text-gray-400 hover:bg-white/5 cursor-pointer">
          <ZoomIn size={16} />
        </button>

        <div className="h-4 w-px bg-white/10 mx-1" />

        <button onClick={resetCanvas} className="p-1.5 rounded-lg text-red-400 hover:bg-red-500/10 cursor-pointer" title="Reset View">
          <RotateCcw size={16} />
        </button>
      </div>

      {/* Main Interactive Drawing Area */}
      <div className="flex-1 flex items-center justify-center p-8 transition-transform duration-300" style={{ transform: `scale(${zoom / 100})` }}>
        
        {canvasMode === 'dsa' ? (
          /* DSA Mode: Invert Binary Tree Representation */
          <div className="relative flex flex-col items-center select-none">
            
            {/* Simulation controls */}
            <div className="mb-6 flex flex-col items-center gap-2">
              <button
                onClick={() => setIsTreeInverted(!isTreeInverted)}
                className="px-4 py-2 bg-blue-600/90 hover:bg-blue-600 text-white rounded-xl text-xs font-black tracking-wide shadow-lg flex items-center gap-2 transition-transform hover:scale-105 cursor-pointer"
              >
                <ArrowRightLeft size={14} />
                {isTreeInverted ? 'Reset Tree' : 'Invert Tree'}
              </button>
              <p className="text-[10px] text-gray-400 text-center max-w-[200px]">
                Click to swap left & right children recursively.
              </p>
            </div>

            {/* Tree Structure with Connecting SVGs */}
            <div className="relative w-80 h-72 flex items-center justify-center">
              
              {/* Dynamic SVG Connection Lines */}
              <svg className="absolute inset-0 w-full h-full pointer-events-none" xmlns="http://www.w3.org/2000/svg">
                {/* Level 0 -> Level 1 */}
                <line x1="160" y1="40" x2={isTreeInverted ? "240" : "80"} y2="120" stroke="#3b82f6" strokeWidth="2" strokeDasharray="4" />
                <line x1="160" y1="40" x2={isTreeInverted ? "80" : "240"} y2="120" stroke="#3b82f6" strokeWidth="2" strokeDasharray="4" />

                {/* Level 1 (Left) -> Level 2 */}
                <line x1="80" y1="120" x2={isTreeInverted ? "110" : "50"} y2="210" stroke="#3b82f6" strokeWidth="1.5" opacity="0.6" />
                <line x1="80" y1="120" x2={isTreeInverted ? "50" : "110"} y2="210" stroke="#3b82f6" strokeWidth="1.5" opacity="0.6" />

                {/* Level 1 (Right) -> Level 2 */}
                <line x1="240" y1="120" x2={isTreeInverted ? "270" : "210"} y2="210" stroke="#3b82f6" strokeWidth="1.5" opacity="0.6" />
                <line x1="240" y1="120" x2={isTreeInverted ? "210" : "270"} y2="210" stroke="#3b82f6" strokeWidth="1.5" opacity="0.6" />
              </svg>

              {/* Node Components */}
              {/* Root Node: 4 */}
              <div className="absolute top-2 left-[136px] w-12 h-12 rounded-full border border-blue-500/30 bg-blue-500/10 flex items-center justify-center font-bold text-white text-lg shadow-lg shadow-blue-500/5 transition-all">
                4
              </div>

              {/* Level 1 Nodes: Left (2), Right (7) */}
              <div 
                className="absolute top-24 w-12 h-12 rounded-full border border-blue-500/30 bg-blue-500/10 flex items-center justify-center font-bold text-white text-lg shadow-lg shadow-blue-500/5 transition-all duration-700 ease-in-out"
                style={{ left: isTreeInverted ? '216px' : '56px' }}
              >
                2
              </div>
              <div 
                className="absolute top-24 w-12 h-12 rounded-full border border-blue-500/30 bg-blue-500/10 flex items-center justify-center font-bold text-white text-lg shadow-lg shadow-blue-500/5 transition-all duration-700 ease-in-out"
                style={{ left: isTreeInverted ? '56px' : '216px' }}
              >
                7
              </div>

              {/* Level 2 Nodes under 2: Left (1), Right (3) */}
              <div 
                className="absolute top-48 w-10 h-10 rounded-full border border-blue-400/20 bg-blue-500/5 flex items-center justify-center font-bold text-gray-300 transition-all duration-700 ease-in-out"
                style={{ left: isTreeInverted ? '246px' : '26px' }}
              >
                1
              </div>
              <div 
                className="absolute top-48 w-10 h-10 rounded-full border border-blue-400/20 bg-blue-500/5 flex items-center justify-center font-bold text-gray-300 transition-all duration-700 ease-in-out"
                style={{ left: isTreeInverted ? '186px' : '86px' }}
              >
                3
              </div>

              {/* Level 2 Nodes under 7: Left (6), Right (9) */}
              <div 
                className="absolute top-48 w-10 h-10 rounded-full border border-blue-400/20 bg-blue-500/5 flex items-center justify-center font-bold text-gray-300 transition-all duration-700 ease-in-out"
                style={{ left: isTreeInverted ? '86px' : '186px' }}
              >
                6
              </div>
              <div 
                className="absolute top-48 w-10 h-10 rounded-full border border-blue-400/20 bg-blue-500/5 flex items-center justify-center font-bold text-gray-300 transition-all duration-700 ease-in-out"
                style={{ left: isTreeInverted ? '26px' : '246px' }}
              >
                9
              </div>
            </div>

            {/* AI Handwriting Annotation Text */}
            <div className="absolute top-16 right-0 border border-amber-500/20 bg-amber-500/5 px-2 py-1 rounded text-[10px] font-mono text-amber-400/90 shadow-md">
              O(N) Time Complexity
            </div>
            
            <div className="absolute bottom-2 left-0 border border-blue-500/20 bg-blue-500/5 px-2 py-1 rounded text-[10px] font-mono text-blue-400/90 shadow-md">
              O(h) Space Complexity
            </div>

          </div>
        ) : (
          /* System Design Mode: Cloud Architecture Diagram */
          <div className="relative w-96 h-64 flex items-center justify-between px-6 select-none">
            
            {/* Connection SVG */}
            <svg className="absolute inset-0 w-full h-full pointer-events-none" xmlns="http://www.w3.org/2000/svg">
              {/* Connector line 1 */}
              <path d="M 64 120 L 192 120" stroke="#3b82f6" strokeWidth="2" fill="none" strokeDasharray="3 3" />
              {/* Connector line 2 */}
              <path d="M 192 120 L 320 70" stroke="#3b82f6" strokeWidth="2" fill="none" />
              {/* Connector line 3 */}
              <path d="M 192 120 L 320 170" stroke="#3b82f6" strokeWidth="2" fill="none" />
            </svg>

            {/* Source Node: Client / API Gateway */}
            <div className="flex flex-col items-center gap-2 z-10">
              <div className="w-14 h-14 rounded-xl bg-orange-500/10 border border-orange-500/30 flex items-center justify-center text-orange-400 shadow-lg shadow-orange-500/5">
                <Server size={24} />
              </div>
              <span className="text-[10px] font-bold text-gray-400">API Gateway</span>
            </div>

            {/* Middle Node: Backend Lambda/Cluster */}
            <div className="flex flex-col items-center gap-2 z-10">
              <div className="w-14 h-14 rounded-xl bg-blue-500/10 border border-blue-500/30 flex items-center justify-center text-blue-400 shadow-lg shadow-blue-500/5">
                <Cpu size={24} />
              </div>
              <span className="text-[10px] font-bold text-gray-400">Compute Layer</span>
            </div>

            {/* Right Nodes: Databases & Storage */}
            <div className="flex flex-col gap-8 z-10">
              <div className="flex flex-col items-center gap-1">
                <div className="w-12 h-12 rounded-xl bg-emerald-500/10 border border-emerald-500/30 flex items-center justify-center text-emerald-400 shadow-lg shadow-emerald-500/5">
                  <Database size={20} />
                </div>
                <span className="text-[9px] font-bold text-gray-400">PostgreSQL</span>
              </div>
              <div className="flex flex-col items-center gap-1">
                <div className="w-12 h-12 rounded-xl bg-purple-500/10 border border-purple-500/30 flex items-center justify-center text-purple-400 shadow-lg shadow-purple-500/5">
                  <Layers size={20} />
                </div>
                <span className="text-[9px] font-bold text-gray-400">Redis Cache</span>
              </div>
            </div>

            {/* Smart Shape Detection Demonstration Layer */}
            <div className="absolute top-2 left-6 flex items-center gap-4 bg-[#1E1E24]/60 border border-white/5 p-2 rounded-xl">
              <div className="text-[10px] text-gray-400">Smart Shape:</div>
              <div className="flex items-center gap-2">
                {/* Rough circle animating to clean circle */}
                <div className="relative w-8 h-8 flex items-center justify-center">
                  <svg className="absolute inset-0 w-full h-full" viewBox="0 0 32 32">
                    {roughCircleToggled ? (
                      /* Clean Snapped Circle */
                      <circle cx="16" cy="16" r="10" stroke="#3b82f6" strokeWidth="2" fill="none" className="transition-all" />
                    ) : (
                      /* Rough hand-drawn shape path */
                      <path d="M16 6 C9 5, 5 12, 6 18 C7 25, 23 27, 26 19 C28 12, 23 7, 16 6" stroke="#fbbf24" strokeWidth="1.5" fill="none" className="transition-all" />
                    )}
                  </svg>
                </div>
                <span className="text-[9px] font-bold font-mono text-gray-300">
                  {roughCircleToggled ? 'Circle (100% Match)' : 'Drawing...'}
                </span>
              </div>
            </div>

          </div>
        )}

      </div>

      {/* Main Integrated Draw Bar (Bottom Floating Panel) */}
      <div className="absolute bottom-4 left-1/2 -translate-x-1/2 z-10 bg-[#1E1E24]/85 backdrop-blur-lg px-4 py-2 rounded-full border border-white/8 shadow-2xl flex items-center gap-3">
        <button
          onClick={() => setActiveTool('pen')}
          className={`p-2 rounded-full transition-all cursor-pointer ${activeTool === 'pen' ? 'bg-blue-600 text-white shadow-md' : 'text-gray-400 hover:text-white'}`}
          title="Pen (Draw)"
        >
          <Edit3 size={16} />
        </button>
        
        <button
          onClick={() => setActiveTool('hand')}
          className={`p-2 rounded-full transition-all cursor-pointer ${activeTool === 'hand' ? 'bg-blue-600 text-white shadow-md' : 'text-gray-400 hover:text-white'}`}
          title="Pan / Hand"
        >
          <Hand size={16} />
        </button>

        <button
          onClick={() => setActiveTool('connector')}
          className={`p-2 rounded-full transition-all cursor-pointer ${activeTool === 'connector' ? 'bg-blue-600 text-white shadow-md' : 'text-gray-400 hover:text-white'}`}
          title="Connector Line"
        >
          <GitCommit size={16} />
        </button>

        <button
          onClick={() => setActiveTool('diagram')}
          className={`p-2 rounded-full transition-all cursor-pointer ${activeTool === 'diagram' ? 'bg-blue-600 text-white shadow-md' : 'text-gray-400 hover:text-white'}`}
          title="Cloud Icons"
        >
          <Image size={16} />
        </button>

        <button
          onClick={() => setActiveTool('eraser')}
          className={`p-2 rounded-full transition-all cursor-pointer ${activeTool === 'eraser' ? 'bg-blue-600 text-white shadow-md' : 'text-gray-400 hover:text-white'}`}
          title="Eraser"
        >
          <Eraser size={16} />
        </button>
      </div>
    </div>
  );
}
