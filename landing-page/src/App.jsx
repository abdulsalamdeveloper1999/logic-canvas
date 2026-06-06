import React, { useState } from 'react';
import { 
  Sparkles, Cpu, Image, Network, Cloud, BookOpen, 
  ArrowRight, Download, ChevronDown, ChevronUp, 
  HelpCircle, ExternalLink, Layers, Check
} from 'lucide-react';
import ProblemPanel from './components/ProblemPanel';
import InteractiveCanvas from './components/InteractiveCanvas';
import PaywallCard from './components/PaywallCard';

export default function App() {
  const [activeFaq, setActiveFaq] = useState(null);
  const [showPrivacy, setShowPrivacy] = useState(false);
  const [showTerms, setShowTerms] = useState(false);
  const [showSupport, setShowSupport] = useState(false);
  const [supportMessageSent, setSupportMessageSent] = useState(false);

  const SUPPORT_URL = "https://github.com/abdulsalamdeveloper1999/logic-canvas/issues";
  const MARKETING_URL = "https://logiccanvas.asdevify.uk";
  const PRIVACY_URL = "https://logiccanvas.asdevify.uk/privacy";
  const TERMS_URL = "https://logiccanvas.asdevify.uk/terms";
  
  const features = [
    {
      icon: <Sparkles className="text-blue-400" size={24} />,
      title: "AI Shape Detection",
      desc: "Instantly snaps rough hand-drawn circles, rectangles, triangles, and flow arrows into clean, pixel-perfect vector elements."
    },
    {
      icon: <Cpu className="text-blue-400" size={24} />,
      title: "ML Handwriting Recognition",
      desc: "Powered by on-device machine learning, translate your handwritten pseudo-code, variables, and comments into structured digital text."
    },
    {
      icon: <Network className="text-blue-400" size={24} />,
      title: "Smart Connectors",
      desc: "Draw lines that dynamically latch onto architecture nodes and diagram objects. Reposition nodes, and watch the connections follow."
    },
    {
      icon: <Image className="text-blue-400" size={24} />,
      title: "Cloud Icon Libraries",
      desc: "Includes comprehensive built-in asset packs for AWS, Google Cloud, and Microsoft Azure to draft production-level system design layouts."
    },
    {
      icon: <Layers className="text-blue-400" size={24} />,
      title: "Multi-Board Management",
      desc: "Create and label custom whiteboards for different algorithms (Graphs, Trees) or architectural designs, switching between them instantly."
    },
    {
      icon: <Cloud className="text-blue-400" size={24} />,
      title: "iCloud Sync & Persistence",
      desc: "Keep your study progress safe. Works offline with Hive local database and syncs automatically across all iOS devices with iCloud."
    }
  ];

  const steps = [
    {
      num: "01",
      title: "Choose Your Challenge",
      desc: "Browse our built-in LeetCode questions (Starter Packs & Pareto list) categorized by difficulty and data structure."
    },
    {
      num: "02",
      title: "Diagram the Logic",
      desc: "Use the whiteboard to draw out array indices, linked list pointers, recursion stacks, tree balances, or system designs."
    },
    {
      num: "03",
      title: "Dry-Run and Trace",
      desc: "Add variable tracking tables, trace complexities side-by-side with the problem descriptions, and write clear pseudo-code."
    },
    {
      num: "04",
      title: "Export & Save",
      desc: "Save your drawing locally, back it up to iCloud, or export it to high-fidelity PDF/PNG for future reviews and study documentation."
    }
  ];

  const faqs = [
    {
      q: "Does LogicCanvas work offline?",
      a: "Yes. All your boards and drawing states are saved locally on your device using Hive. The AI shape detector and ML handwriting models also run fully on-device, meaning you can practice and sketch without an active internet connection."
    },
    {
      q: "How does iCloud synchronization work?",
      a: "LogicCanvas automatically monitors your local database and pushes updates to iCloud Storage container. If you open LogicCanvas on another device connected to the same Apple ID, your boards will merge and update seamlessly."
    },
    {
      q: "Are the cloud icon libraries available on the free plan?",
      a: "The free plan includes basic shape diagramming and select icons. The full AWS, GCP, and Azure icon sets, alongside AI shape detection and ML text recognition, are unlocked under LogicCanvas Pro."
    },
    {
      q: "Can I export my boards to code or other platforms?",
      a: "Currently, you can export your whiteboard drawings to high-quality PDF files (great for printing or combining into study guides) or take high-resolution screenshots to share in documentation or markdown files."
    }
  ];

  const toggleFaq = (index) => {
    setActiveFaq(activeFaq === index ? null : index);
  };

  const scrollToSection = (id) => {
    const el = document.getElementById(id);
    if (el) {
      el.scrollIntoView({ behavior: 'smooth' });
    }
  };

  return (
    <div className="min-h-screen bg-[#0F0F0F] text-gray-100 font-sans selection:bg-blue-500/30 selection:text-blue-200">
      
      {/* Sticky Glassmorphic Navbar */}
      <nav className="sticky top-0 z-50 w-full bg-[#0F0F0F]/70 backdrop-blur-md border-b border-white/5">
        <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
          {/* Brand Logo */}
          <div className="flex items-center gap-3 cursor-pointer" onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}>
            <img src="/logo.png" alt="LogicCanvas Logo" className="w-9 h-9 object-contain" />
            <span className="text-lg font-black tracking-tighter text-white">LogicCanvas</span>
          </div>

          {/* Navigation Links */}
          <div className="hidden md:flex items-center gap-8 text-sm font-medium text-gray-400">
            <button onClick={() => scrollToSection('features')} className="hover:text-white transition-colors cursor-pointer">Features</button>
            <button onClick={() => scrollToSection('demo')} className="hover:text-white transition-colors cursor-pointer">Interactive Demo</button>
            <button onClick={() => scrollToSection('pricing')} className="hover:text-white transition-colors cursor-pointer">Pricing</button>
            <button onClick={() => scrollToSection('faq')} className="hover:text-white transition-colors cursor-pointer">FAQs</button>
            <button onClick={() => setShowSupport(true)} className="hover:text-white transition-colors cursor-pointer">Support</button>
          </div>

          {/* Primary CTA */}
          <div className="flex items-center gap-4">
            <button
              onClick={() => scrollToSection('pricing')}
              className="px-4 py-2 text-xs font-bold bg-blue-600 hover:bg-blue-500 text-white rounded-lg transition-transform hover:scale-105 active:scale-95 shadow-md shadow-blue-600/20 cursor-pointer"
            >
              Get LogicCanvas Pro
            </button>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <header className="relative pt-20 pb-16 md:pt-32 md:pb-28 text-center px-6 overflow-hidden">
        {/* Background glow highlights */}
        <div className="absolute top-1/4 left-1/2 -translate-x-1/2 w-[500px] h-[500px] rounded-full bg-blue-600/10 blur-[120px] pointer-events-none -z-10" />
        
        <div className="max-w-4xl mx-auto space-y-6">
          {/* Badge */}
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-500/10 border border-blue-500/20 text-blue-400 text-xs font-black tracking-wide uppercase">
            <Sparkles size={12} />
            <span>Redefining Technical Interview Prep</span>
          </div>

          {/* Main Title */}
          <h1 className="text-4xl sm:text-6xl font-black text-white tracking-tight leading-tight">
            Visualise the Logic.<br />
            <span className="text-gradient-blue">Ace the Coding Interview.</span>
          </h1>

          {/* Subtitle */}
          <p className="text-base sm:text-xl text-gray-400 max-w-2xl mx-auto leading-relaxed">
            The premium whiteboard designed for software engineers. Sketch trees, map graphs, trace complexities, and draft system designs side-by-side with LeetCode problems.
          </p>

          {/* Actions */}
          <div className="pt-4 flex flex-col sm:flex-row justify-center items-center gap-4">
            <button 
              onClick={() => scrollToSection('demo')}
              className="w-full sm:w-auto px-6 py-3.5 bg-white text-black font-black text-sm rounded-xl shadow-lg hover:bg-gray-100 transition-all flex items-center justify-center gap-2 cursor-pointer hover:scale-[1.02]"
            >
              Try Interactive Demo
              <ArrowRight size={16} />
            </button>
            <button 
              onClick={() => scrollToSection('pricing')}
              className="w-full sm:w-auto px-6 py-3.5 bg-white/5 hover:bg-white/10 text-white border border-white/10 font-bold text-sm rounded-xl transition-all flex items-center justify-center gap-2 cursor-pointer"
            >
              <Download size={16} />
              Download App (1.0)
            </button>
          </div>
        </div>
      </header>

      {/* App Workspace Preview Showcase (Interactive Demo Section) */}
      <section id="demo" className="py-16 px-6 bg-gradient-to-b from-[#0F0F0F] via-[#0A0A0C] to-[#0F0F0F] relative">
        <div className="max-w-7xl mx-auto space-y-10">
          <div className="text-center max-w-2xl mx-auto space-y-3">
            <h2 className="text-3xl font-black text-white">Experience the Workspace</h2>
            <p className="text-sm text-gray-400">
              Check out the live interactive mockup below. Switch between **DSA** and **System Design** modes to see how LogicCanvas converts hand-sketches and structure layouts into neat documentation.
            </p>
          </div>

          {/* Device Mockup Frame (iPad / Monitor style) */}
          <div className="w-full aspect-[16/10] max-h-[700px] border border-white/10 rounded-2xl overflow-hidden bg-[#1E1E24] shadow-2xl flex flex-col">
            {/* Browser Window Chrome */}
            <div className="h-10 bg-[#16161C] border-b border-white/5 flex items-center justify-between px-4 shrink-0">
              <div className="flex items-center gap-1.5">
                <span className="w-3 h-3 rounded-full bg-red-500/60" />
                <span className="w-3 h-3 rounded-full bg-yellow-500/60" />
                <span className="w-3 h-3 rounded-full bg-green-500/60" />
              </div>
              <div className="text-[10px] font-mono text-gray-500 tracking-wider">LOGICCANVAS APP INTERACTION</div>
              <div className="w-12" /> {/* spacer */}
            </div>

            {/* Simulated App Client */}
            <div className="flex-1 flex overflow-hidden min-h-0 relative">
              {/* Workspace Board */}
              <InteractiveCanvas />

              {/* Side problem drawer (mimics app panel) */}
              <div className="hidden md:block shrink-0 h-full border-l border-white/5">
                <ProblemPanel />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Key Features Section */}
      <section id="features" className="py-20 px-6 max-w-7xl mx-auto space-y-16">
        <div className="text-center max-w-2xl mx-auto space-y-4">
          <h2 className="text-3xl sm:text-4xl font-black text-white">Engineered For Visual Coders</h2>
          <p className="text-sm sm:text-base text-gray-400">
            Ditch the scratchpad. LogicCanvas is custom-tailored with features to make whiteboard algorithm analysis and software architecture sketching intuitive.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-8">
          {features.map((feat, idx) => (
            <div key={idx} className="p-6 rounded-2xl bg-white/[0.02] border border-white/5 hover:border-white/10 transition-all hover:translate-y-[-4px] text-left space-y-4 group">
              <div className="w-12 h-12 rounded-xl bg-blue-500/10 border border-blue-500/20 flex items-center justify-center transition-all group-hover:scale-110">
                {feat.icon}
              </div>
              <h3 className="text-lg font-bold text-white">{feat.title}</h3>
              <p className="text-sm text-gray-400 leading-relaxed">{feat.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* How It Works Section */}
      <section className="py-20 bg-black/40 border-y border-white/5 px-6">
        <div className="max-w-7xl mx-auto space-y-16">
          <div className="text-center max-w-2xl mx-auto space-y-4">
            <h2 className="text-3xl font-black text-white">How It Works</h2>
            <p className="text-sm text-gray-400">
              Mastering coding interview questions is a cycle of code, dry-runs, and system breakdown. LogicCanvas guides your preparation.
            </p>
          </div>

          <div className="grid sm:grid-cols-4 gap-8 relative">
            {steps.map((step, idx) => (
              <div key={idx} className="text-left space-y-4 relative">
                {/* Connector line on desktop */}
                {idx < 3 && (
                  <div className="hidden sm:block absolute top-10 left-[60%] right-[-40%] h-[1px] bg-gradient-to-r from-blue-500/30 to-transparent" />
                )}
                <div className="text-3xl font-black text-blue-500/20">{step.num}</div>
                <h3 className="text-lg font-bold text-white">{step.title}</h3>
                <p className="text-xs text-gray-400 leading-relaxed">{step.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing / App Store Paywall Section */}
      <section id="pricing" className="py-24 px-6 max-w-7xl mx-auto space-y-16">
        <div className="text-center max-w-2xl mx-auto space-y-4">
          <h2 className="text-3xl sm:text-4xl font-black text-white">Get Full Access</h2>
          <p className="text-sm text-gray-400">
            Start with the starter packs, or upgrade to LogicCanvas Pro to unlock advanced AI, handwriting recognition models, and cloud infrastructure sets.
          </p>
        </div>

        {/* Dynamic Paywall Card */}
        <PaywallCard />
      </section>

      {/* FAQ Section */}
      <section id="faq" className="py-20 px-6 max-w-4xl mx-auto space-y-12">
        <h2 className="text-3xl font-black text-white text-center">Frequently Asked Questions</h2>
        
        <div className="space-y-4">
          {faqs.map((faq, idx) => {
            const isOpen = activeFaq === idx;
            return (
              <div key={idx} className="rounded-2xl border border-white/5 bg-white/[0.01] overflow-hidden transition-all duration-300">
                <button
                  onClick={() => toggleFaq(idx)}
                  className="w-full p-5 text-left flex items-center justify-between text-base font-bold text-white hover:bg-white/[0.02] transition-colors cursor-pointer"
                >
                  <span>{faq.q}</span>
                  {isOpen ? <ChevronUp size={18} className="text-blue-400" /> : <ChevronDown size={18} className="text-gray-500" />}
                </button>
                {isOpen && (
                  <div className="px-5 pb-5 text-sm text-gray-400 leading-relaxed border-t border-white/5 pt-4">
                    {faq.a}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-white/5 bg-[#0A0A0C] py-16 px-6 text-center text-xs text-gray-500">
        <div className="max-w-7xl mx-auto space-y-8">
          
          <div className="flex flex-col sm:flex-row justify-between items-center gap-6">
            {/* Identity */}
            <div className="flex items-center gap-3">
              <img src="/logo.png" alt="LogicCanvas Logo" className="w-8 h-8 object-contain" />
              <span className="text-base font-black tracking-tight text-white">LogicCanvas</span>
            </div>

            {/* Links */}
            <div className="flex gap-6 text-gray-400 font-medium">
              <button onClick={() => scrollToSection('features')} className="hover:text-white transition-colors cursor-pointer">Features</button>
              <button onClick={() => scrollToSection('demo')} className="hover:text-white transition-colors cursor-pointer">Workspace Demo</button>
              <button onClick={() => scrollToSection('pricing')} className="hover:text-white transition-colors cursor-pointer">Pricing</button>
              <button onClick={() => setShowSupport(true)} className="hover:text-white transition-colors cursor-pointer">Support</button>
              <a href="https://github.com/abdulsalamdeveloper1999/logic-canvas" target="_blank" rel="noreferrer" className="hover:text-white transition-colors flex items-center gap-1.5">
                GitHub <ExternalLink size={12} />
              </a>
            </div>
          </div>

          <div className="h-px bg-white/5 w-full" />

          {/* Compliance Legal terms */}
          <div className="space-y-4 max-w-4xl mx-auto text-left sm:text-center text-[10px] leading-relaxed text-gray-600">
            <p>
              In-app purchases are handled via Apple App Store transactions and managed with RevenueCat. Subscriptions auto-renew unless auto-renew is turned off at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period at the rate of the selected plan.
            </p>
            <p className="flex justify-center gap-4 text-gray-500 font-semibold pt-2">
              <a href={TERMS_URL} onClick={(e) => { e.preventDefault(); setShowTerms(true); }} className="hover:underline">Terms of Use</a>
              <span>•</span>
              <a href={PRIVACY_URL} onClick={(e) => { e.preventDefault(); setShowPrivacy(true); }} className="hover:underline">Privacy Policy</a>
            </p>
          </div>

          {/* Copyright */}
          <div className="pt-2 text-gray-600 font-medium">
            © 2026 asdevify. All rights reserved.
          </div>
        </div>
      </footer>

      {/* Support / Contact Modal */}
      {showSupport && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4">
          <div className="glass-panel max-w-lg w-full rounded-2xl p-6 space-y-4 relative">
            <button 
              onClick={() => { setShowSupport(false); setSupportMessageSent(false); }} 
              className="absolute top-4 right-4 text-gray-400 hover:text-white cursor-pointer"
            >
              <ChevronDown size={24} className="rotate-90" />
            </button>
            <h3 className="text-xl font-black text-white flex items-center gap-2">
              <HelpCircle className="text-blue-500" /> Support & Feedback
            </h3>
            
            {supportMessageSent ? (
              <div className="py-8 text-center space-y-3">
                <div className="w-12 h-12 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-500 flex items-center justify-center mx-auto">
                  <Check size={24} className="stroke-[3]" />
                </div>
                <h4 className="text-base font-bold text-white">Message Sent!</h4>
                <p className="text-xs text-gray-400 max-w-sm mx-auto leading-relaxed">
                  Thank you for reaching out to LogicCanvas support. We will get back to you at your email address within 24 hours.
                </p>
              </div>
            ) : (
              <form onSubmit={(e) => { e.preventDefault(); setSupportMessageSent(true); }} className="space-y-4 text-left">
                <p className="text-xs text-gray-400 leading-relaxed">
                  Have a question, feedback, or found a bug? Send us a message and our support team will help you out.
                </p>
                <div>
                  <label className="block text-[10px] font-black text-gray-400 uppercase tracking-wider mb-1.5">Email Address</label>
                  <input required type="email" placeholder="you@example.com" className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-2.5 text-xs text-white focus:outline-none focus:border-blue-500 transition-colors" />
                </div>
                <div>
                  <label className="block text-[10px] font-black text-gray-400 uppercase tracking-wider mb-1.5">Subject</label>
                  <input required type="text" placeholder="How can we help you?" className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-2.5 text-xs text-white focus:outline-none focus:border-blue-500 transition-colors" />
                </div>
                <div>
                  <label className="block text-[10px] font-black text-gray-400 uppercase tracking-wider mb-1.5">Message</label>
                  <textarea required rows={4} placeholder="Describe your issue or suggestions in detail..." className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-2.5 text-xs text-white focus:outline-none focus:border-blue-500 transition-colors resize-none" />
                </div>
                <button type="submit" className="w-full py-3 bg-blue-600 hover:bg-blue-500 text-white rounded-xl text-xs font-bold transition-all cursor-pointer shadow-lg shadow-blue-600/25">
                  Submit Support Ticket
                </button>
                <div className="text-center pt-2 text-[10px] text-gray-500">
                  Or email directly: <a href="mailto:support@asdevify.com" className="text-blue-400 hover:underline">support@asdevify.com</a>
                </div>
              </form>
            )}
          </div>
        </div>
      )}

      {/* Privacy Policy Modal */}
      {showPrivacy && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4">
          <div className="glass-panel max-w-2xl w-full rounded-2xl p-6 md:p-8 space-y-6 max-h-[80vh] overflow-y-auto relative text-left">
            <button 
              onClick={() => setShowPrivacy(false)} 
              className="absolute top-4 right-4 text-gray-400 hover:text-white cursor-pointer"
            >
              <ChevronDown size={24} className="rotate-90" />
            </button>
            <h3 className="text-2xl font-black text-white">Privacy Policy</h3>
            <p className="text-[10px] text-gray-500">Last updated: June 6, 2026</p>
            
            <div className="space-y-4 text-xs text-gray-300 leading-relaxed font-sans">
              <h4 className="text-sm font-bold text-white">1. Information We Do Not Collect</h4>
              <p>
                At LogicCanvas, we believe your work and algorithmic ideas are entirely your own. We do not collect, transmit, or store any of your custom drawings, text elements, variables, or whiteboard sketches. All data is kept strictly local on your device.
              </p>

              <h4 className="text-sm font-bold text-white">2. iCloud Backup & Sync</h4>
              <p>
                If you choose to enable iCloud Sync, your whiteboard states are backed up and synced via Apple's secure iCloud Storage API. This data is stored in your personal iCloud container, which means asdevify has no access, visibility, or control over your sketches.
              </p>

              <h4 className="text-sm font-bold text-white">3. In-App Subscriptions</h4>
              <p>
                LogicCanvas Pro purchases are handled by RevenueCat and validated using Apple App Store anonymous receipts. No personal or credit card identifiers are processed or stored by our servers.
              </p>

              <h4 className="text-sm font-bold text-white">4. On-Device Intelligence</h4>
              <p>
                Our AI-based shape recognition and ML-powered handwriting recognition models run completely on your local device. We do not upload your strokes or handwriting to any external servers or third-party APIs.
              </p>

              <h4 className="text-sm font-bold text-white">5. Contact Information</h4>
              <p>
                For questions regarding this policy, please reach out to <a href="mailto:privacy@asdevify.com" className="text-blue-400 hover:underline">privacy@asdevify.com</a>.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Terms of Use Modal */}
      {showTerms && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4">
          <div className="glass-panel max-w-2xl w-full rounded-2xl p-6 md:p-8 space-y-6 max-h-[80vh] overflow-y-auto relative text-left">
            <button 
              onClick={() => setShowTerms(false)} 
              className="absolute top-4 right-4 text-gray-400 hover:text-white cursor-pointer"
            >
              <ChevronDown size={24} className="rotate-90" />
            </button>
            <h3 className="text-2xl font-black text-white">Terms of Use</h3>
            <p className="text-[10px] text-gray-500">Last updated: June 6, 2026</p>
            
            <div className="space-y-4 text-xs text-gray-300 leading-relaxed font-sans">
              <h4 className="text-sm font-bold text-white">1. License Grant</h4>
              <p>
                asdevify grants you a limited, non-exclusive, revocable, non-transferable license to download, install, and use LogicCanvas strictly for personal, educational, and interview preparation purposes on your iOS devices.
              </p>

              <h4 className="text-sm font-bold text-white">2. Pro Subscriptions & Trials</h4>
              <p>
                Some features (AI shape detection, cloud architecture icons, ML recognition) are premium benefits requiring a Monthly or Annual membership. Free trials automatically convert to standard paid subscriptions unless canceled at least 24 hours prior to the trial expiration.
              </p>

              <h4 className="text-sm font-bold text-white">3. App Content & Data Integrity</h4>
              <p>
                All drawings, diagrams, and structures are saved locally. We are not responsible for any data loss, deleted canvases, or synchronized database corruptions.
              </p>

              <h4 className="text-sm font-bold text-white">4. Disclaimers & Limitations</h4>
              <p>
                LogicCanvas is provided "as is" and "as available" without warranty of any kind. asdevify does not warrant that the application will meet your requirements or run uninterrupted. In no event shall we be liable for any special, incidental, or consequential damages resulting from your use of the software.
              </p>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
