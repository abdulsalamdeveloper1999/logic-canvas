import React, { useState } from 'react';
import { BookOpen, X, ChevronDown, ChevronRight, HelpCircle } from 'lucide-react';

export default function ProblemPanel() {
  const [isExpanded, setIsExpanded] = useState(true);
  const [activeHint, setActiveHint] = useState(null);

  const problem = {
    title: 'Invert Binary Tree',
    category: 'Trees',
    difficulty: 'EASY',
    description: 'Given the root of a binary tree, invert the tree, and return its root. Inverting a binary tree means swapping the left and right children of all nodes recursively.',
    examples: [
      {
        input: 'root = [4,2,7,1,3,6,9]',
        output: '[4,7,2,9,6,3,1]',
        explanation: 'The root node 4 remains. Its left child 2 and right child 7 are swapped. Then their children are swapped: 1 and 3 are swapped under 7 (now 2), and 6 and 9 are swapped under 2 (now 7).'
      },
      {
        input: 'root = [2,1,3]',
        output: '[2,3,1]',
      }
    ],
    hints: [
      'Try doing a post-order traversal and swap the left and right children at each node.',
      'Think about recursion. What is the base case? If the root is null, what should you return?',
      'You can also solve this iteratively using a queue (Breadth-First Search) and swapping children level-by-level.'
    ]
  };

  return (
    <div className={`relative transition-all duration-500 ease-in-out select-none ${isExpanded ? 'w-full md:w-[350px]' : 'w-[50px]'} h-full flex flex-col`}>
      {/* Toggle Button */}
      <button
        onClick={() => setIsExpanded(!isExpanded)}
        className="absolute -left-4 top-4 w-8 h-8 rounded-full bg-blue-600 hover:bg-blue-500 text-white flex items-center justify-center shadow-lg transition-transform hover:scale-105 z-20 cursor-pointer"
      >
        {isExpanded ? <X size={16} /> : <BookOpen size={16} />}
      </button>

      {/* Main Container */}
      <div className={`w-full h-full glass-panel rounded-2xl overflow-hidden flex flex-col transition-opacity duration-300 ${isExpanded ? 'opacity-100' : 'opacity-0 pointer-events-none'}`}>
        {/* Header */}
        <div className="p-4 border-b border-white/5 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="text-xs font-semibold px-2 py-0.5 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
              {problem.difficulty}
            </span>
            <span className="text-xs font-medium text-gray-400">
              {problem.category}
            </span>
          </div>
        </div>

        {/* Scrollable Content */}
        <div className="flex-1 overflow-y-auto p-5 space-y-5 text-left">
          <div>
            <h3 className="text-lg font-bold text-white mb-2">{problem.title}</h3>
            <p className="text-sm text-gray-300 leading-relaxed font-sans">{problem.description}</p>
          </div>

          {/* Examples */}
          <div className="space-y-3">
            <h4 className="text-xs font-black tracking-wider text-gray-400 uppercase">Examples</h4>
            {problem.examples.map((ex, idx) => (
              <div key={idx} className="p-3 rounded-xl bg-white/[0.02] border border-white/5 font-mono text-xs space-y-1.5">
                <div className="flex">
                  <span className="w-14 text-blue-400 font-bold">Input:</span>
                  <span className="text-gray-300 break-all">{ex.input}</span>
                </div>
                <div className="flex">
                  <span className="w-14 text-blue-400 font-bold">Output:</span>
                  <span className="text-gray-300 break-all">{ex.output}</span>
                </div>
                {ex.explanation && (
                  <div className="text-gray-400 text-[11px] leading-relaxed pt-1.5 border-t border-white/5 mt-1.5">
                    {ex.explanation}
                  </div>
                )}
              </div>
            ))}
          </div>

          {/* Hints */}
          <div className="space-y-3 pb-2">
            <h4 className="text-xs font-black tracking-wider text-gray-400 uppercase">Hints</h4>
            {problem.hints.map((hint, idx) => {
              const isOpen = activeHint === idx;
              return (
                <div key={idx} className="rounded-xl border border-amber-500/15 overflow-hidden">
                  <button
                    onClick={() => setActiveHint(isOpen ? null : idx)}
                    className="w-full p-3 bg-amber-500/[0.02] hover:bg-amber-500/[0.04] text-left flex items-center justify-between text-xs font-bold text-amber-400 cursor-pointer"
                  >
                    <span className="flex items-center gap-2">
                      <HelpCircle size={14} />
                      Hint {idx + 1}
                    </span>
                    {isOpen ? <ChevronDown size={14} /> : <ChevronRight size={14} />}
                  </button>
                  {isOpen && (
                    <div className="p-3 bg-amber-500/[0.01] border-t border-amber-500/10 text-xs text-gray-300 leading-relaxed">
                      {hint}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}
