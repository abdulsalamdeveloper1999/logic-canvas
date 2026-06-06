import React, { useState } from 'react';
import { Check, ShieldCheck, Sparkles, HelpCircle } from 'lucide-react';

export default function PaywallCard() {
  const [selectedPlan, setSelectedPlan] = useState('annual');

  const plans = [
    {
      id: 'monthly',
      title: 'Monthly Membership',
      price: '£4.99',
      period: '/month',
      trial: '3 DAYS FREE',
      description: 'Flexible month-to-month access, cancel anytime.',
      badge: null,
    },
    {
      id: 'annual',
      title: 'Annual Membership',
      price: '£29.99',
      period: '/year',
      trial: '1 WEEK FREE',
      description: 'Only £2.50/month. Save 50% compared to monthly.',
      badge: 'BEST VALUE',
    }
  ];

  const features = [
    'AI Shape Detection (circles, squares, arrows)',
    'ML Handwriting Recognition (paint-to-text)',
    'iCloud Storage & Cross-Device Sync',
    'Premium Cloud Architecture Icon Sets (AWS, GCP, Azure)',
    'Unlimited Whiteboard Canvases & Local Archiving',
    'High-Fidelity PDF & Image Exports'
  ];

  return (
    <div className="w-full max-w-4xl mx-auto p-6 md:p-10 rounded-3xl bg-black border border-white/5 relative overflow-hidden shadow-2xl">
      {/* Background radial highlight */}
      <div className="absolute -top-[120px] -right-[120px] w-[300px] h-[300px] rounded-full bg-blue-500/10 blur-[80px] pointer-events-none" />
      <div className="absolute -bottom-[120px] -left-[120px] w-[300px] h-[300px] rounded-full bg-blue-500/5 blur-[80px] pointer-events-none" />

      <div className="grid md:grid-cols-5 gap-8 items-stretch">
        
        {/* Left Side: Features Value List */}
        <div className="md:col-span-3 flex flex-col justify-between text-left space-y-6">
          <div>
            <div className="flex items-center gap-2 mb-3">
              <img src="/logo.png" alt="Logo" className="w-5 h-5 object-contain" />
              <span className="text-xs font-black tracking-widest text-blue-400 uppercase">LogicCanvas Pro</span>
            </div>
            <h3 className="text-2xl md:text-3xl font-black text-white leading-tight">
              Elevate Your System Design & DSA Practice
            </h3>
            <p className="text-gray-400 text-sm mt-2 leading-relaxed">
              Unlock the complete suite of visual thinking tools to streamline your interview preparation and code sketching.
            </p>
          </div>

          <ul className="space-y-3">
            {features.map((feat, idx) => (
              <li key={idx} className="flex items-start gap-3 text-sm text-gray-300">
                <span className="mt-0.5 w-4 h-4 rounded-full bg-blue-500/20 border border-blue-500/30 flex items-center justify-center text-blue-400 shrink-0">
                  <Check size={10} className="stroke-[3]" />
                </span>
                <span>{feat}</span>
              </li>
            ))}
          </ul>

          <div className="flex items-center gap-2 text-[11px] text-gray-500">
            <ShieldCheck size={14} />
            <span>Secured via RevenueCat. Cancel easily anytime.</span>
          </div>
        </div>

        {/* Right Side: Subscription Selection Cards */}
        <div className="md:col-span-2 flex flex-col justify-center space-y-4">
          {plans.map((plan) => {
            const isSelected = selectedPlan === plan.id;
            return (
              <div
                key={plan.id}
                onClick={() => setSelectedPlan(plan.id)}
                className={`p-4 rounded-2xl border-2 transition-all duration-300 cursor-pointer text-left relative overflow-hidden flex items-center gap-4 ${
                  isSelected 
                    ? 'border-blue-500 bg-blue-500/[0.04]' 
                    : 'border-white/5 bg-white/[0.02] hover:border-white/10 hover:bg-white/[0.04]'
                }`}
              >
                {/* Checkbox indicator */}
                <div className={`w-5 h-5 rounded-full border flex items-center justify-center shrink-0 transition-all ${
                  isSelected ? 'border-blue-500 bg-blue-500' : 'border-white/20'
                }`}>
                  {isSelected && <Check size={12} className="text-white stroke-[3]" />}
                </div>

                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-[9px] font-black px-2 py-0.5 rounded bg-blue-500 text-white tracking-wide">
                      {plan.trial}
                    </span>
                    {plan.badge && (
                      <span className="text-[9px] font-black px-2 py-0.5 rounded bg-white/10 text-gray-300 tracking-wide">
                        {plan.badge}
                      </span>
                    )}
                  </div>
                  <h4 className="text-sm font-bold text-white leading-tight">{plan.title}</h4>
                  <p className="text-[11px] text-gray-400 mt-1 leading-snug">{plan.description}</p>
                </div>

                <div className="text-right shrink-0">
                  <div className="text-lg font-black text-white">{plan.price}</div>
                  <div className="text-[10px] text-gray-500">{plan.period}</div>
                </div>
              </div>
            );
          })}

          <button className="w-full mt-4 py-3.5 bg-blue-600 hover:bg-blue-500 text-white rounded-xl font-bold text-sm transition-transform hover:scale-[1.02] active:scale-[0.98] cursor-pointer shadow-lg shadow-blue-600/20">
            {selectedPlan === 'annual' ? 'Start 1 Week Free Trial' : 'Start 3 Days Free Trial'}
          </button>

          <p className="text-[9px] text-gray-500 text-center leading-relaxed mt-2">
            After the trial period, payment will be charged to your App Store account. Subscription auto-renews unless canceled 24 hours before the period ends.
          </p>
        </div>

      </div>
    </div>
  );
}
