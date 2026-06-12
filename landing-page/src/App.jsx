import React, { useState, useEffect, useRef } from 'react';
import { 
  Sparkles, Cpu, Image, Network, Cloud, BookOpen, 
  ArrowRight, Download, ChevronDown, ChevronUp, 
  HelpCircle, ExternalLink, Layers, Check, Apple,
  Zap, Star, Users, Trophy, Code2, GitBranch, Terminal
} from 'lucide-react';
import ProblemPanel from './components/ProblemPanel';
import InteractiveCanvas from './components/InteractiveCanvas';
import PaywallCard from './components/PaywallCard';

/* ─── Animated floating orb ─── */
function Orb({ className }) {
  return (
    <div
      className={`absolute rounded-full pointer-events-none blur-[120px] ${className}`}
    />
  );
}

/* ─── Particle dot (decorative) ─── */
function Particle({ style }) {
  return (
    <div
      className="absolute w-1 h-1 rounded-full bg-indigo-400/40 pointer-events-none"
      style={style}
    />
  );
}

/* ─── Animated counter ─── */
function AnimCounter({ target, suffix = '' }) {
  const [count, setCount] = useState(0);
  const ref = useRef(null);
  const started = useRef(false);

  useEffect(() => {
    const observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting && !started.current) {
        started.current = true;
        let start = 0;
        const step = target / 60;
        const timer = setInterval(() => {
          start += step;
          if (start >= target) { setCount(target); clearInterval(timer); }
          else { setCount(Math.floor(start)); }
        }, 16);
      }
    }, { threshold: 0.5 });
    if (ref.current) observer.observe(ref.current);
    return () => observer.disconnect();
  }, [target]);

  return <span ref={ref}>{count.toLocaleString()}{suffix}</span>;
}

/* ─── Feature card with icon ─── */
function FeatureCard({ icon, title, desc, accent = '#6366f1', delay = 0 }) {
  return (
    <div
      className="bento-card shimmer-hover glass rounded-2xl p-6 text-left space-y-4 relative overflow-hidden group"
      style={{ animationDelay: `${delay}ms` }}
    >
      {/* Top accent line */}
      <div className="absolute top-0 left-6 right-6 h-[1px]" style={{ background: `linear-gradient(90deg, transparent, ${accent}60, transparent)` }} />
      
      <div className="w-11 h-11 rounded-xl flex items-center justify-center relative" style={{ background: `${accent}15`, border: `1px solid ${accent}30` }}>
        {icon}
        <div className="absolute inset-0 rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-500" style={{ background: `radial-gradient(circle, ${accent}20, transparent)` }} />
      </div>

      <div>
        <h3 className="text-[15px] font-bold text-white mb-1.5 tracking-tight">{title}</h3>
        <p className="text-[13px] text-gray-500 leading-relaxed">{desc}</p>
      </div>

      {/* Corner decoration */}
      <div className="absolute bottom-3 right-3 w-16 h-16 rounded-full opacity-5 group-hover:opacity-10 transition-opacity" style={{ background: `radial-gradient(circle, ${accent}, transparent)` }} />
    </div>
  );
}

/* ─── Step badge ─── */
function StepCard({ num, title, desc, isLast }) {
  return (
    <div className="relative flex gap-5">
      <div className="flex flex-col items-center">
        <div className="w-10 h-10 rounded-xl bg-indigo-500/10 border border-indigo-500/30 flex items-center justify-center text-xs font-black text-indigo-400 shrink-0">
          {num}
        </div>
        {!isLast && <div className="w-px flex-1 mt-2 bg-gradient-to-b from-indigo-500/30 to-transparent" />}
      </div>
      <div className="pb-10 pt-1">
        <h3 className="text-[15px] font-bold text-white mb-1">{title}</h3>
        <p className="text-[13px] text-gray-500 leading-relaxed">{desc}</p>
      </div>
    </div>
  );
}

export default function App() {
  const [activeFaq, setActiveFaq] = useState(null);
  const [showPrivacy, setShowPrivacy] = useState(false);
  const [showTerms, setShowTerms] = useState(false);
  const [showSupport, setShowSupport] = useState(false);
  const [supportMessageSent, setSupportMessageSent] = useState(false);
  const [navScrolled, setNavScrolled] = useState(false);

  const APP_STORE_URL = "https://apps.apple.com/ru/app/logiccanvas/id6760606299?l=en-GB";

  useEffect(() => {
    const onScroll = () => setNavScrolled(window.scrollY > 20);
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  const features = [
    {
      icon: <Sparkles className="text-indigo-400" size={20} />,
      title: "AI Shape Detection",
      desc: "Rough circles and rectangles snap into pixel-perfect vector shapes. Draw naturally — LogicCanvas cleans it up.",
      accent: '#6366f1',
    },
    {
      icon: <Cpu className="text-violet-400" size={20} />,
      title: "ML Handwriting Recognition",
      desc: "On-device ML converts your handwritten pseudo-code and variable names into structured digital text. No cloud needed.",
      accent: '#a78bfa',
    },
    {
      icon: <Network className="text-sky-400" size={20} />,
      title: "Smart Connectors",
      desc: "Lines that latch onto diagram nodes dynamically. Move a node and the connections follow — like a real whiteboard.",
      accent: '#38bdf8',
    },
    {
      icon: <Cloud className="text-emerald-400" size={20} />,
      title: "Cloud Icon Libraries",
      desc: "Built-in icon packs for AWS, GCP, and Azure. Draft production-level system designs in minutes, not hours.",
      accent: '#34d399',
    },
    {
      icon: <Layers className="text-pink-400" size={20} />,
      title: "Multi-Board Management",
      desc: "Separate canvases per topic — Graphs, Trees, System Design. Label them, switch instantly, never lose context.",
      accent: '#f472b6',
    },
    {
      icon: <BookOpen className="text-amber-400" size={20} />,
      title: "iCloud Sync & Offline Mode",
      desc: "Works 100% offline with Hive local storage. Auto-syncs across your Apple devices when you're back online.",
      accent: '#fbbf24',
    },
  ];

  const steps = [
    { num: "01", title: "Choose Your Challenge", desc: "Browse built-in LeetCode problems categorized by difficulty, data structure, and pattern — curated for high-signal practice." },
    { num: "02", title: "Diagram the Logic", desc: "Sketch trees, trace linked list pointers, build recursion stacks, or draft a distributed system — all on one canvas." },
    { num: "03", title: "Dry-Run & Trace", desc: "Add variable tracking tables, annotate complexity, and write pseudo-code side-by-side with the problem description." },
    { num: "04", title: "Export & Review", desc: "Save boards to iCloud, export to PDF or high-res PNG, and build a personal library of solved patterns." },
  ];

  const faqs = [
    {
      q: "Does LogicCanvas work offline?",
      a: "Yes — completely. All boards are saved locally using Hive, and the AI shape detector and ML handwriting models run fully on-device. You can practice on a plane with no signal."
    },
    {
      q: "How does iCloud sync work?",
      a: "LogicCanvas monitors your local database and pushes changes to your personal iCloud Storage container automatically. Open on any Apple device signed into the same Apple ID and your boards appear instantly."
    },
    {
      q: "What's included in the free version?",
      a: "The free version includes basic shape diagramming and a starter set of icons. LogicCanvas Pro unlocks AI shape detection, ML text recognition, the full AWS/GCP/Azure icon libraries, and unlimited canvases."
    },
    {
      q: "Can I export my boards?",
      a: "Yes. Export any canvas to a high-quality PDF (great for printing or adding to a study guide) or take a high-resolution screenshot to paste into Notion, markdown files, or documentation."
    },
  ];

  const scrollTo = (id) => {
    document.getElementById(id)?.scrollIntoView({ behavior: 'smooth' });
  };

  // Decorative particles
  const particles = Array.from({ length: 18 }, (_, i) => ({
    left: `${(i * 37 + 11) % 100}%`,
    top: `${(i * 53 + 7) % 100}%`,
    animationDelay: `${i * 0.4}s`,
    animationDuration: `${5 + (i % 4)}s`,
  }));

  return (
    <div className="min-h-screen bg-[#080810] text-gray-100 font-sans selection:bg-indigo-500/30 selection:text-indigo-200">

      {/* ─── Navbar ─── */}
      <nav className={`sticky top-0 z-50 w-full transition-all duration-300 ${navScrolled ? 'glass-strong border-b border-white/5 shadow-xl shadow-black/20' : 'bg-transparent'}`}>
        <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3 cursor-pointer group" onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}>
            <div className="relative">
              <img src="/logo.png" alt="LogicCanvas Logo" className="w-9 h-9 object-contain relative z-10 group-hover:scale-105 transition-transform duration-200" />
              <div className="absolute inset-0 rounded-full bg-indigo-500/20 blur-md opacity-0 group-hover:opacity-100 transition-opacity" />
            </div>
            <span className="text-[17px] font-black tracking-tight text-white">Logic<span className="text-gradient">Canvas</span></span>
          </div>

          <div className="hidden md:flex items-center gap-8 text-[13px] font-medium text-gray-500">
            {[['features', 'Features'], ['demo', 'Demo'], ['pricing', 'Pricing'], ['faq', 'FAQ']].map(([id, label]) => (
              <button key={id} onClick={() => scrollTo(id)} className="hover:text-white transition-colors relative group cursor-pointer">
                {label}
                <span className="absolute -bottom-0.5 left-0 w-0 h-px bg-indigo-400 group-hover:w-full transition-all duration-300" />
              </button>
            ))}
            <button onClick={() => setShowSupport(true)} className="hover:text-white transition-colors relative group cursor-pointer">
              Support
              <span className="absolute -bottom-0.5 left-0 w-0 h-px bg-indigo-400 group-hover:w-full transition-all duration-300" />
            </button>
          </div>

          <button
            onClick={() => window.open(APP_STORE_URL, '_blank')}
            className="flex items-center gap-2 px-4 py-2 rounded-xl text-[13px] font-bold text-white bg-indigo-600 hover:bg-indigo-500 transition-all hover:scale-105 active:scale-95 shadow-lg shadow-indigo-600/25 cursor-pointer"
          >
            <Apple size={15} />
            Download
          </button>
        </div>
      </nav>

      {/* ─── Hero ─── */}
      <header className="relative pt-24 pb-20 md:pt-36 md:pb-28 text-center px-6 overflow-hidden">
        {/* Orbs */}
        <Orb className="w-[700px] h-[700px] bg-indigo-600/8 top-[-200px] left-1/2 -translate-x-1/2" />
        <Orb className="w-[400px] h-[400px] bg-violet-600/10 top-40 left-[10%] anim-float" />
        <Orb className="w-[300px] h-[300px] bg-sky-600/8 top-60 right-[5%] anim-float-delay" />

        {/* Grid background */}
        <div className="absolute inset-0 grid-bg opacity-40 pointer-events-none" />

        {/* Floating particles */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          {particles.map((p, i) => (
            <Particle key={i} style={{ ...p, animation: `drift ${p.animationDuration} ease-in-out infinite ${p.animationDelay}` }} />
          ))}
        </div>

        <div className="relative max-w-4xl mx-auto space-y-7">
          {/* Eyebrow */}
          <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full glass border border-indigo-500/20 text-indigo-300 text-[11px] font-black tracking-widest uppercase anim-scale-in">
            <Sparkles size={11} />
            <span>Built for Software Engineers</span>
          </div>

          {/* Headline */}
          <h1 className="text-5xl sm:text-7xl font-black text-white tracking-tight leading-[1.05] anim-fade-up" style={{ animationDelay: '0.1s' }}>
            Think Visually.<br />
            <span className="text-gradient">Code Brilliantly.</span>
          </h1>

          {/* Subheadline */}
          <p className="text-base sm:text-xl text-gray-500 max-w-2xl mx-auto leading-relaxed anim-fade-up" style={{ animationDelay: '0.2s' }}>
            The premium iOS whiteboard for engineering interviews. Sketch algorithms, trace data structures, and architect systems — all in one beautiful canvas.
          </p>

          {/* CTA */}
          <div className="pt-2 flex flex-col sm:flex-row justify-center items-center gap-4 anim-fade-up" style={{ animationDelay: '0.3s' }}>
            <button
              onClick={() => window.open(APP_STORE_URL, '_blank')}
              className="border-glow-indigo relative group flex items-center gap-3 px-8 py-4 bg-indigo-600 hover:bg-indigo-500 text-white rounded-2xl font-bold text-[15px] shadow-2xl shadow-indigo-600/30 transition-all hover:scale-[1.03] active:scale-[0.97] cursor-pointer anim-pulse-glow"
            >
              <Apple size={18} />
              Download on the App Store
              <ArrowRight size={16} className="group-hover:translate-x-1 transition-transform" />
            </button>
            <button
              onClick={() => scrollTo('demo')}
              className="glass flex items-center gap-2 px-6 py-4 rounded-2xl font-semibold text-[14px] text-gray-400 hover:text-white border border-white/8 hover:border-white/15 transition-all hover:scale-[1.02] cursor-pointer"
            >
              See it in action
              <ChevronDown size={15} />
            </button>
          </div>

          {/* Social proof micro-strip */}
          <div className="pt-4 flex items-center justify-center gap-6 anim-fade-up" style={{ animationDelay: '0.45s' }}>
            <div className="flex items-center gap-1.5">
              {[...Array(5)].map((_, i) => <Star key={i} size={12} className="fill-amber-400 text-amber-400" />)}
              <span className="text-[12px] text-gray-500 ml-1 font-medium">5.0 on App Store</span>
            </div>
            <span className="w-px h-4 bg-white/10" />
            <span className="text-[12px] text-gray-500 font-medium">iOS 16+ · iPad & iPhone</span>
            <span className="w-px h-4 bg-white/10" />
            <span className="text-[12px] text-gray-500 font-medium">Works fully offline</span>
          </div>
        </div>
      </header>

      {/* ─── Stats strip ─── */}
      <section className="py-10 border-y border-white/5 bg-black/30">
        <div className="max-w-4xl mx-auto px-6 grid grid-cols-3 gap-6 text-center">
          {[
            { val: 150, suffix: '+', label: 'Curated Problems' },
            { val: 3, suffix: ' icon packs', label: 'AWS · GCP · Azure' },
            { val: 100, suffix: '% offline', label: 'On-device AI/ML' },
          ].map((s, i) => (
            <div key={i} className="stat-item space-y-1" style={{ animationDelay: `${i * 0.1}s` }}>
              <div className="text-3xl sm:text-4xl font-black text-white">
                <AnimCounter target={s.val} suffix={s.suffix} />
              </div>
              <div className="text-[12px] text-gray-500 font-medium">{s.label}</div>
            </div>
          ))}
        </div>
      </section>

      {/* ─── Interactive Demo ─── */}
      <section id="demo" className="py-24 px-6 relative overflow-hidden">
        <Orb className="w-[500px] h-[500px] bg-indigo-600/5 top-0 right-[-100px]" />
        <div className="max-w-7xl mx-auto space-y-10">
          <div className="text-center max-w-2xl mx-auto space-y-4">
            <div className="inline-flex items-center gap-2 text-[11px] font-black uppercase tracking-widest text-indigo-400">
              <Terminal size={12} />
              <span>Live Preview</span>
            </div>
            <h2 className="text-3xl sm:text-4xl font-black text-white tracking-tight">
              The Workspace, <span className="text-gradient">Right Here</span>
            </h2>
            <p className="text-[14px] text-gray-500 leading-relaxed">
              Switch between DSA and System Design modes in the mockup below. This is what greets you when you open the app.
            </p>
          </div>

          {/* Monitor-style mockup */}
          <div className="relative">
            {/* Glow behind */}
            <div className="absolute inset-8 rounded-3xl bg-indigo-600/10 blur-3xl pointer-events-none" />
            
            <div className="relative w-full aspect-[16/10] max-h-[680px] rounded-2xl overflow-hidden glass-strong border border-white/8 shadow-2xl">
              {/* Traffic lights */}
              <div className="h-10 bg-black/60 border-b border-white/5 flex items-center justify-between px-4 shrink-0">
                <div className="flex items-center gap-1.5">
                  <span className="w-3 h-3 rounded-full bg-red-500/70" />
                  <span className="w-3 h-3 rounded-full bg-yellow-500/70" />
                  <span className="w-3 h-3 rounded-full bg-green-500/70" />
                </div>
                <div className="flex items-center gap-2">
                  <div className="h-5 w-48 rounded-md bg-white/5 border border-white/5 flex items-center justify-center">
                    <span className="text-[9px] font-mono text-gray-600">logiccanvas.app · workspace</span>
                  </div>
                </div>
                <div className="w-16" />
              </div>

              <div className="flex-1 flex overflow-hidden" style={{ height: 'calc(100% - 40px)' }}>
                <InteractiveCanvas />
                <div className="hidden md:block shrink-0 h-full border-l border-white/5">
                  <ProblemPanel />
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ─── Features ─── */}
      <section id="features" className="py-24 px-6 relative overflow-hidden">
        <div className="absolute inset-0 grid-bg opacity-20 pointer-events-none" />
        <Orb className="w-[600px] h-[600px] bg-violet-600/6 bottom-[-100px] left-[-150px]" />
        
        <div className="relative max-w-7xl mx-auto space-y-16">
          <div className="text-center max-w-2xl mx-auto space-y-4">
            <div className="inline-flex items-center gap-2 text-[11px] font-black uppercase tracking-widest text-violet-400">
              <Zap size={12} />
              <span>What's Inside</span>
            </div>
            <h2 className="text-3xl sm:text-4xl font-black text-white tracking-tight">
              Every Tool You Need to <span className="text-gradient">Think Clearly</span>
            </h2>
            <p className="text-[14px] text-gray-500 leading-relaxed">
              Not a generic notes app. Not a plain canvas. LogicCanvas is purpose-built for the specific cognitive demands of algorithm analysis and system design.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-5">
            {features.map((feat, idx) => (
              <FeatureCard key={idx} {...feat} delay={idx * 60} />
            ))}
          </div>

          {/* Inline mini highlight banner */}
          <div className="glass border border-indigo-500/15 rounded-2xl p-6 flex flex-col sm:flex-row items-center justify-between gap-6 relative overflow-hidden">
            <div className="absolute inset-0 bg-gradient-to-r from-indigo-600/5 via-violet-600/5 to-transparent pointer-events-none" />
            <div className="text-left space-y-1">
              <p className="text-[15px] font-bold text-white">All AI & ML runs on your device.</p>
              <p className="text-[13px] text-gray-500">No subscription required to use core features. Your drawings never leave your iPhone or iPad.</p>
            </div>
            <button
              onClick={() => window.open(APP_STORE_URL, '_blank')}
              className="shrink-0 flex items-center gap-2 px-5 py-2.5 bg-indigo-600 hover:bg-indigo-500 rounded-xl text-[13px] font-bold text-white transition-all hover:scale-105 cursor-pointer shadow-lg shadow-indigo-600/20"
            >
              <Apple size={14} />
              Get the App
            </button>
          </div>
        </div>
      </section>

      {/* ─── How It Works ─── */}
      <section className="py-24 px-6 relative overflow-hidden">
        <div className="max-w-7xl mx-auto">
          <div className="grid md:grid-cols-2 gap-16 items-center">
            
            {/* Left — steps */}
            <div className="space-y-6">
              <div className="space-y-3">
                <div className="inline-flex items-center gap-2 text-[11px] font-black uppercase tracking-widest text-sky-400">
                  <GitBranch size={12} />
                  <span>Workflow</span>
                </div>
                <h2 className="text-3xl sm:text-4xl font-black text-white tracking-tight">
                  From Problem<br />to <span className="text-gradient">Pattern Mastery</span>
                </h2>
              </div>
              <div>
                {steps.map((step, idx) => (
                  <StepCard key={idx} {...step} isLast={idx === steps.length - 1} />
                ))}
              </div>
            </div>

            {/* Right — decorative code block / feature card */}
            <div className="relative space-y-5">
              <Orb className="w-[350px] h-[350px] bg-sky-600/8 top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2" />
              
              {/* Mock canvas thumbnail */}
              <div className="glass border border-white/8 rounded-2xl p-5 space-y-4 relative overflow-hidden bento-card">
                <div className="absolute top-0 right-0 w-32 h-32 rounded-full bg-indigo-500/5 blur-2xl pointer-events-none" />
                <div className="flex items-center justify-between">
                  <span className="text-[11px] font-black uppercase tracking-wider text-gray-500">Canvas Snapshot</span>
                  <span className="text-[10px] px-2 py-0.5 rounded-md bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 font-bold">SAVED</span>
                </div>
                {/* Simulated whiteboard nodes */}
                <div className="relative h-40 rounded-xl bg-white/[0.02] border border-white/5 overflow-hidden">
                  {/* Node boxes */}
                  {[
                    { left: '10%', top: '20%', label: 'root', w: '60px' },
                    { left: '30%', top: '55%', label: 'left', w: '52px' },
                    { left: '58%', top: '55%', label: 'right', w: '58px' },
                    { left: '18%', top: '78%', label: 'null', w: '44px', dim: true },
                    { left: '46%', top: '78%', label: 'null', w: '44px', dim: true },
                  ].map((node, i) => (
                    <div
                      key={i}
                      className={`absolute rounded-md border flex items-center justify-center text-[9px] font-mono font-bold ${node.dim ? 'border-white/5 bg-white/[0.02] text-gray-600' : 'border-indigo-500/40 bg-indigo-500/10 text-indigo-300'}`}
                      style={{ left: node.left, top: node.top, width: node.w, height: '22px', transform: 'translateX(-50%)' }}
                    >
                      {node.label}
                    </div>
                  ))}
                  {/* Connector lines (SVG) */}
                  <svg className="absolute inset-0 w-full h-full" style={{ overflow: 'visible' }}>
                    <line x1="15%" y1="30%" x2="32%" y2="55%" stroke="rgba(99,102,241,0.3)" strokeWidth="1" strokeDasharray="3,2" />
                    <line x1="15%" y1="30%" x2="60%" y2="55%" stroke="rgba(99,102,241,0.3)" strokeWidth="1" strokeDasharray="3,2" />
                    <line x1="32%" y1="68%" x2="22%" y2="78%" stroke="rgba(99,102,241,0.2)" strokeWidth="1" strokeDasharray="2,2" />
                    <line x1="60%" y1="68%" x2="50%" y2="78%" stroke="rgba(99,102,241,0.2)" strokeWidth="1" strokeDasharray="2,2" />
                  </svg>
                </div>
                <div className="flex items-center justify-between text-[10px] text-gray-600">
                  <span className="font-mono">Binary Tree · DFS · O(n) time</span>
                  <span>3 nodes traced</span>
                </div>
              </div>

              {/* Complexity note card */}
              <div className="glass border border-white/6 rounded-xl px-5 py-4 flex items-center gap-4 bento-card">
                <div className="w-9 h-9 rounded-lg bg-violet-500/10 border border-violet-500/20 flex items-center justify-center text-violet-400 shrink-0">
                  <Code2 size={16} />
                </div>
                <div>
                  <p className="text-[12px] font-bold text-white">Complexity Annotations</p>
                  <p className="text-[11px] text-gray-500 mt-0.5">Add Big-O notes directly on the canvas next to your traced algorithm.</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ─── Pricing ─── */}
      <section id="pricing" className="py-24 px-6 relative overflow-hidden">
        <div className="absolute inset-0 grid-bg opacity-15 pointer-events-none" />
        <Orb className="w-[500px] h-[500px] bg-indigo-600/8 top-0 right-0" />
        <Orb className="w-[400px] h-[400px] bg-violet-600/6 bottom-0 left-0" />
        
        <div className="relative max-w-7xl mx-auto space-y-14">
          <div className="text-center max-w-2xl mx-auto space-y-4">
            <div className="inline-flex items-center gap-2 text-[11px] font-black uppercase tracking-widest text-pink-400">
              <Trophy size={12} />
              <span>LogicCanvas Pro</span>
            </div>
            <h2 className="text-3xl sm:text-4xl font-black text-white tracking-tight">
              Start Free, <span className="text-gradient-warm">Upgrade When Ready</span>
            </h2>
            <p className="text-[14px] text-gray-500 leading-relaxed">
              Core features are free forever. Pro unlocks the full AI toolkit, icon libraries, and unlimited canvases — all managed securely inside the app.
            </p>
          </div>

          <PaywallCard />
        </div>
      </section>

      {/* ─── FAQ ─── */}
      <section id="faq" className="py-24 px-6 max-w-3xl mx-auto space-y-10">
        <div className="text-center space-y-3">
          <div className="inline-flex items-center gap-2 text-[11px] font-black uppercase tracking-widest text-gray-500">
            <HelpCircle size={12} />
            <span>Common Questions</span>
          </div>
          <h2 className="text-3xl font-black text-white tracking-tight">FAQ</h2>
        </div>

        <div className="space-y-3">
          {faqs.map((faq, idx) => {
            const isOpen = activeFaq === idx;
            return (
              <div key={idx} className={`glass rounded-2xl overflow-hidden transition-all duration-300 border ${isOpen ? 'border-indigo-500/25' : 'border-white/5 hover:border-white/10'}`}>
                <button
                  onClick={() => setActiveFaq(isOpen ? null : idx)}
                  className="w-full px-6 py-5 text-left flex items-center justify-between gap-4 cursor-pointer hover:bg-white/[0.01] transition-colors"
                >
                  <span className="text-[14px] font-bold text-white">{faq.q}</span>
                  <span className={`shrink-0 w-6 h-6 rounded-full flex items-center justify-center transition-all duration-300 ${isOpen ? 'bg-indigo-500/20 text-indigo-400' : 'bg-white/5 text-gray-500'}`}>
                    {isOpen ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
                  </span>
                </button>
                {isOpen && (
                  <div className="px-6 pb-5 text-[13px] text-gray-500 leading-relaxed border-t border-white/5 pt-4">
                    {faq.a}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </section>

      {/* ─── Final CTA Banner ─── */}
      <section className="py-20 px-6">
        <div className="max-w-4xl mx-auto relative">
          <div className="border-glow-indigo glass rounded-3xl p-10 md:p-16 text-center space-y-6 relative overflow-hidden noise">
            <div className="absolute inset-0 bg-gradient-to-br from-indigo-600/8 via-violet-600/5 to-transparent pointer-events-none" />
            <Orb className="w-[300px] h-[300px] bg-indigo-600/12 top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2" />
            
            <div className="relative space-y-4">
              <p className="text-[11px] font-black uppercase tracking-widest text-indigo-400">Get Started Today</p>
              <h2 className="text-3xl sm:text-5xl font-black text-white tracking-tight leading-tight">
                Your Next Interview<br /><span className="text-gradient">Starts Here.</span>
              </h2>
              <p className="text-[15px] text-gray-500 max-w-lg mx-auto">
                Download LogicCanvas and start visualising the algorithms that land the roles.
              </p>
            </div>

            <div className="relative flex flex-col sm:flex-row justify-center gap-4 pt-2">
              <button
                onClick={() => window.open(APP_STORE_URL, '_blank')}
                className="group flex items-center justify-center gap-3 px-8 py-4 bg-white text-black rounded-2xl font-bold text-[15px] hover:bg-gray-100 transition-all hover:scale-[1.03] active:scale-97 cursor-pointer shadow-2xl shadow-black/40"
              >
                <Apple size={18} />
                Download on the App Store
                <ArrowRight size={16} className="group-hover:translate-x-1 transition-transform" />
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* ─── Footer ─── */}
      <footer className="border-t border-white/5 bg-black/40 py-14 px-6">
        <div className="max-w-7xl mx-auto space-y-8">
          <div className="flex flex-col sm:flex-row justify-between items-start gap-8">
            <div className="space-y-3">
              <div className="flex items-center gap-3">
                <img src="/logo.png" alt="LogicCanvas" className="w-8 h-8 object-contain" />
                <span className="text-[16px] font-black tracking-tight text-white">Logic<span className="text-gradient">Canvas</span></span>
              </div>
              <p className="text-[12px] text-gray-600 max-w-xs leading-relaxed">
                The premium iOS whiteboard for software engineers preparing for technical interviews.
              </p>
            </div>

            <div className="flex flex-wrap gap-x-10 gap-y-4">
              <div className="space-y-3">
                <p className="text-[10px] font-black uppercase tracking-widest text-gray-600">Product</p>
                {[['features', 'Features'], ['demo', 'Demo'], ['pricing', 'Pricing']].map(([id, label]) => (
                  <button key={id} onClick={() => scrollTo(id)} className="block text-[13px] text-gray-500 hover:text-white transition-colors cursor-pointer">{label}</button>
                ))}
              </div>
              <div className="space-y-3">
                <p className="text-[10px] font-black uppercase tracking-widest text-gray-600">Legal</p>
                <button onClick={() => setShowTerms(true)} className="block text-[13px] text-gray-500 hover:text-white transition-colors cursor-pointer">Terms of Use</button>
                <button onClick={() => setShowPrivacy(true)} className="block text-[13px] text-gray-500 hover:text-white transition-colors cursor-pointer">Privacy Policy</button>
              </div>
              <div className="space-y-3">
                <p className="text-[10px] font-black uppercase tracking-widest text-gray-600">Connect</p>
                <button onClick={() => setShowSupport(true)} className="block text-[13px] text-gray-500 hover:text-white transition-colors cursor-pointer">Support</button>
                <a href="https://github.com/abdulsalamdeveloper1999/logic-canvas" target="_blank" rel="noreferrer" className="flex items-center gap-1.5 text-[13px] text-gray-500 hover:text-white transition-colors">
                  GitHub <ExternalLink size={11} />
                </a>
              </div>
            </div>
          </div>

          <div className="h-px bg-white/5" />

          <div className="flex flex-col sm:flex-row items-center justify-between gap-4 text-[11px] text-gray-600">
            <p>© 2026 asdevify. All rights reserved.</p>
            <p className="text-center max-w-md leading-relaxed">
              In-app purchases handled via Apple App Store · Powered by RevenueCat · Subscriptions auto-renew unless cancelled 24 hours before period end.
            </p>
          </div>
        </div>
      </footer>

      {/* ─── Support Modal ─── */}
      {showSupport && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-md p-4">
          <div className="glass-strong max-w-lg w-full rounded-3xl p-7 space-y-5 relative border border-white/10 shadow-2xl">
            <button onClick={() => { setShowSupport(false); setSupportMessageSent(false); }} className="absolute top-5 right-5 w-7 h-7 rounded-full bg-white/5 hover:bg-white/10 flex items-center justify-center text-gray-400 hover:text-white transition-all cursor-pointer">
              <ChevronDown size={16} className="rotate-90" />
            </button>
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-indigo-500/15 border border-indigo-500/30 flex items-center justify-center">
                <HelpCircle size={18} className="text-indigo-400" />
              </div>
              <h3 className="text-[18px] font-black text-white">Support & Feedback</h3>
            </div>

            {supportMessageSent ? (
              <div className="py-10 text-center space-y-3">
                <div className="w-14 h-14 rounded-full bg-emerald-500/10 border border-emerald-500/25 text-emerald-400 flex items-center justify-center mx-auto">
                  <Check size={26} className="stroke-[2.5]" />
                </div>
                <h4 className="text-[15px] font-bold text-white">Message Sent!</h4>
                <p className="text-[12px] text-gray-500 max-w-sm mx-auto leading-relaxed">
                  We'll get back to you within 24 hours at the email you provided.
                </p>
              </div>
            ) : (
              <form onSubmit={(e) => { e.preventDefault(); setSupportMessageSent(true); }} className="space-y-4">
                <p className="text-[12px] text-gray-500 leading-relaxed">
                  Found a bug, have a feature request, or just want to say hi? We read every message.
                </p>
                {[
                  { label: 'Email Address', type: 'email', placeholder: 'you@example.com' },
                  { label: 'Subject', type: 'text', placeholder: 'What can we help with?' },
                ].map(({ label, type, placeholder }) => (
                  <div key={label}>
                    <label className="block text-[10px] font-black text-gray-500 uppercase tracking-wider mb-1.5">{label}</label>
                    <input required type={type} placeholder={placeholder} className="w-full glass border border-white/8 rounded-xl px-4 py-2.5 text-[13px] text-white placeholder-gray-600 focus:outline-none focus:border-indigo-500/50 transition-colors" />
                  </div>
                ))}
                <div>
                  <label className="block text-[10px] font-black text-gray-500 uppercase tracking-wider mb-1.5">Message</label>
                  <textarea required rows={4} placeholder="Describe your issue or idea in detail..." className="w-full glass border border-white/8 rounded-xl px-4 py-2.5 text-[13px] text-white placeholder-gray-600 focus:outline-none focus:border-indigo-500/50 transition-colors resize-none" />
                </div>
                <button type="submit" className="w-full py-3 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-[13px] font-bold transition-all hover:scale-[1.01] cursor-pointer shadow-lg shadow-indigo-600/20">
                  Send Message
                </button>
                <p className="text-center text-[11px] text-gray-600">
                  Or email: <a href="mailto:abdulsalam@asdevify.com" className="text-indigo-400 hover:underline">abdulsalam@asdevify.com</a>
                </p>
              </form>
            )}
          </div>
        </div>
      )}

      {/* ─── Privacy Modal ─── */}
      {showPrivacy && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-md p-4">
          <div className="glass-strong max-w-2xl w-full rounded-3xl p-7 md:p-9 space-y-6 max-h-[80vh] overflow-y-auto relative border border-white/10 shadow-2xl text-left">
            <button onClick={() => setShowPrivacy(false)} className="absolute top-5 right-5 w-7 h-7 rounded-full bg-white/5 hover:bg-white/10 flex items-center justify-center text-gray-400 hover:text-white transition-all cursor-pointer">
              <ChevronDown size={16} className="rotate-90" />
            </button>
            <div>
              <h3 className="text-[22px] font-black text-white">Privacy Policy</h3>
              <p className="text-[11px] text-gray-600 mt-1">Last updated: June 6, 2026</p>
            </div>
            <div className="space-y-5 text-[13px] text-gray-400 leading-relaxed">
              {[
                ['1. Information We Do Not Collect', 'At LogicCanvas, we believe your work and algorithmic ideas are entirely your own. We do not collect, transmit, or store any of your custom drawings, text elements, variables, or whiteboard sketches. All data is kept strictly local on your device.'],
                ['2. iCloud Backup & Sync', "If you choose to enable iCloud Sync, your whiteboard states are backed up and synced via Apple's secure iCloud Storage API. This data is stored in your personal iCloud container — asdevify has zero access or visibility."],
                ['3. In-App Subscriptions', 'LogicCanvas Pro purchases are handled by RevenueCat and validated using Apple App Store anonymous receipts. No personal or credit card identifiers are processed or stored by our servers.'],
                ['4. On-Device Intelligence', 'Our AI shape recognition and ML handwriting recognition models run completely on your local device. We do not upload your strokes or handwriting to any external servers.'],
                ['5. Contact', null],
              ].map(([title, body]) => (
                <div key={title}>
                  <h4 className="text-[13px] font-bold text-white mb-1">{title}</h4>
                  {body ? <p>{body}</p> : <p>For questions, reach out to <a href="mailto:abdulsalam@asdevify.com" className="text-indigo-400 hover:underline">abdulsalam@asdevify.com</a>.</p>}
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* ─── Terms Modal ─── */}
      {showTerms && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-md p-4">
          <div className="glass-strong max-w-2xl w-full rounded-3xl p-7 md:p-9 space-y-6 max-h-[80vh] overflow-y-auto relative border border-white/10 shadow-2xl text-left">
            <button onClick={() => setShowTerms(false)} className="absolute top-5 right-5 w-7 h-7 rounded-full bg-white/5 hover:bg-white/10 flex items-center justify-center text-gray-400 hover:text-white transition-all cursor-pointer">
              <ChevronDown size={16} className="rotate-90" />
            </button>
            <div>
              <h3 className="text-[22px] font-black text-white">Terms of Use</h3>
              <p className="text-[11px] text-gray-600 mt-1">Last updated: June 6, 2026</p>
            </div>
            <div className="space-y-5 text-[13px] text-gray-400 leading-relaxed">
              {[
                ['1. License Grant', 'asdevify grants you a limited, non-exclusive, revocable, non-transferable license to download, install, and use LogicCanvas strictly for personal, educational, and interview preparation purposes on your iOS devices.'],
                ['2. Pro Subscriptions & Trials', 'Some features (AI shape detection, cloud architecture icons, ML recognition) are premium benefits requiring a Monthly or Annual membership. Free trials automatically convert to standard paid subscriptions unless cancelled at least 24 hours prior to the trial expiration.'],
                ['3. App Content & Data Integrity', 'All drawings, diagrams, and structures are saved locally. We are not responsible for any data loss, deleted canvases, or synchronisation corruptions.'],
                ['4. Disclaimers & Limitations', 'LogicCanvas is provided "as is" without warranty of any kind. asdevify does not warrant the application will meet your requirements or run uninterrupted. We are not liable for any special, incidental, or consequential damages.'],
              ].map(([title, body]) => (
                <div key={title}>
                  <h4 className="text-[13px] font-bold text-white mb-1">{title}</h4>
                  <p>{body}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
