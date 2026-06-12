import React from 'react';
import { Check, ShieldCheck, Apple, Sparkles } from 'lucide-react';

const APP_STORE_URL = "https://apps.apple.com/ru/app/logiccanvas/id6760606299?l=en-GB";

export default function PaywallCard() {
  const plans = [
    {
      id: 'monthly',
      title: 'Monthly',
      price: '£4.99',
      period: 'per month',
      trial: '3-day free trial',
      description: 'Flexible. Cancel anytime with no penalty.',
      badge: null,
    },
    {
      id: 'annual',
      title: 'Annual',
      price: '£29.99',
      period: 'per year',
      trial: '1-week free trial',
      description: '£2.50 / month · Save 50% vs monthly.',
      badge: 'BEST VALUE',
    }
  ];

  const features = [
    { text: 'AI Shape Detection', note: 'circles, squares, arrows' },
    { text: 'ML Handwriting Recognition', note: 'paint-to-text, on-device' },
    { text: 'iCloud Sync', note: 'cross-device, auto-backup' },
    { text: 'Cloud Icon Packs', note: 'AWS · GCP · Azure' },
    { text: 'Unlimited Canvases', note: 'with local archiving' },
    { text: 'PDF & Image Exports', note: 'high-fidelity output' },
  ];

  return (
    <div className="w-full max-w-4xl mx-auto rounded-3xl relative overflow-hidden">
      {/* Outer glow border */}
      <div className="absolute inset-0 rounded-3xl bg-gradient-to-br from-indigo-500/15 via-violet-500/8 to-transparent pointer-events-none" />
      <div className="absolute inset-[1px] rounded-3xl bg-[#0d0d1a] pointer-events-none" />

      <div className="relative p-7 md:p-10">
        <div className="grid md:grid-cols-5 gap-8 items-stretch">

          {/* ── Left: Features ── */}
          <div className="md:col-span-3 flex flex-col gap-7">
            {/* Header */}
            <div>
              <div className="flex items-center gap-2 mb-4">
                <div className="w-6 h-6 rounded-md bg-indigo-500/20 border border-indigo-500/30 flex items-center justify-center">
                  <Sparkles size={12} className="text-indigo-400" />
                </div>
                <span className="text-[11px] font-black tracking-widest text-indigo-400 uppercase">LogicCanvas Pro</span>
              </div>
              <h3 className="text-2xl md:text-3xl font-black text-white leading-tight tracking-tight">
                Every tool you need.<br />
                <span className="text-gradient">Nothing you don't.</span>
              </h3>
              <p className="text-[13px] text-gray-500 mt-3 leading-relaxed">
                Unlock the full AI toolkit, cloud icon libraries, and unlimited canvases. Billed through Apple — cancel anytime.
              </p>
            </div>

            {/* Feature grid */}
            <ul className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {features.map(({ text, note }, idx) => (
                <li key={idx} className="flex items-start gap-3">
                  <span className="mt-0.5 w-4 h-4 rounded-full bg-indigo-500/15 border border-indigo-500/25 flex items-center justify-center shrink-0">
                    <Check size={9} className="text-indigo-400 stroke-[3]" />
                  </span>
                  <div>
                    <span className="text-[13px] font-semibold text-gray-200">{text}</span>
                    <span className="block text-[11px] text-gray-600">{note}</span>
                  </div>
                </li>
              ))}
            </ul>

            {/* Trust line */}
            <div className="flex items-center gap-2 text-[11px] text-gray-600 mt-auto">
              <ShieldCheck size={13} />
              <span>Secured by RevenueCat · Managed in your Apple ID · Cancel anytime</span>
            </div>
          </div>

          {/* ── Right: Pricing cards ── */}
          <div className="md:col-span-2 flex flex-col gap-4 justify-center">
            {plans.map((plan) => (
              <div
                key={plan.id}
                className={`relative rounded-2xl p-4 border transition-all duration-300 flex items-center gap-4 overflow-hidden ${
                  plan.badge
                    ? 'border-indigo-500/40 bg-indigo-500/[0.05]'
                    : 'border-white/6 bg-white/[0.02]'
                }`}
              >
                {/* Accent top line for best value */}
                {plan.badge && (
                  <div className="absolute top-0 left-0 right-0 h-[1px] bg-gradient-to-r from-transparent via-indigo-500/60 to-transparent" />
                )}

                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1.5">
                    <span className="text-[9px] font-black px-2 py-0.5 rounded-md bg-indigo-500/20 border border-indigo-500/30 text-indigo-300 tracking-wide uppercase">
                      {plan.trial}
                    </span>
                    {plan.badge && (
                      <span className="text-[9px] font-black px-2 py-0.5 rounded-md bg-white/8 text-gray-400 tracking-wide uppercase">
                        {plan.badge}
                      </span>
                    )}
                  </div>
                  <h4 className="text-[14px] font-bold text-white leading-tight">{plan.title}</h4>
                  <p className="text-[11px] text-gray-500 mt-0.5">{plan.description}</p>
                </div>

                <div className="text-right shrink-0">
                  <div className={`text-xl font-black ${plan.badge ? 'text-white' : 'text-gray-300'}`}>{plan.price}</div>
                  <div className="text-[10px] text-gray-600 mt-0.5">{plan.period}</div>
                </div>
              </div>
            ))}

            {/* CTA */}
            <button
              onClick={() => window.open(APP_STORE_URL, '_blank')}
              className="w-full mt-2 py-3.5 flex items-center justify-center gap-2.5 bg-indigo-600 hover:bg-indigo-500 text-white rounded-2xl font-bold text-[14px] transition-all hover:scale-[1.02] active:scale-[0.98] cursor-pointer shadow-xl shadow-indigo-600/25"
            >
              <Apple size={16} />
              Download on the App Store
            </button>

            <p className="text-[10px] text-gray-600 text-center leading-relaxed">
              Pricing shown for reference only. Trials & subscriptions are started inside the iOS app via your Apple ID.
            </p>
          </div>

        </div>
      </div>
    </div>
  );
}
