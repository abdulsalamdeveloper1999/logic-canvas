import 'package:logic_canvas/domain/entities/viz_scene.dart';

/// Animated walkthroughs for the Arrays & Hashing problems (01–08).
///
/// Every trace is produced by running the algorithm and recording each step,
/// so the frames cannot disagree with the logic they teach.
class ArraysHashingTraces {
  const ArraysHashingTraces._();

  static List<AlgorithmTrace> get all => [
    containsDuplicate(),
    validAnagram(),
    twoSum(),
    groupAnagrams(),
    topKFrequent(),
    validSudoku(),
    productExceptSelf(),
    longestConsecutive(),
  ];

  static List<({String key, String value, VizState state})> _entries(
    Map<Object, Object> map, {
    Object? hit,
  }) {
    return map.entries
        .map(
          (e) => (
            key: '${e.key}',
            value: '${e.value}',
            state: e.key == hit ? VizState.success : VizState.idle,
          ),
        )
        .toList();
  }

  // ----------------------------------------------------------------- 01

  static AlgorithmTrace containsDuplicate() {
    const nums = [1, 2, 3, 1];
    final values = nums.map((n) => '$n').toList();
    final steps = <VizStep>[];
    final seen = <int>{};

    steps.add(
      const VizStep(
        caption:
            'Does any number appear twice? Comparing every pair would take '
            'n squared steps. Instead keep a set of what we have already '
            'passed, and check membership as we go.',
        codeLine: 0,
        scenes: [
          ArrayScene(values: ['1', '2', '3', '1'], title: 'nums'),
          MapScene(entries: [], title: 'seen', emptyLabel: 'nothing seen yet'),
        ],
      ),
    );

    var duplicateAt = -1;
    for (var i = 0; i < nums.length; i++) {
      final isDuplicate = seen.contains(nums[i]);

      steps.add(
        VizStep(
          caption: isDuplicate
              ? 'We have seen ${nums[i]} before. That is a duplicate, so we '
                    'can answer true right now without looking further.'
              : '${nums[i]} is new. Add it to the set and move on.',
          codeLine: isDuplicate ? 2 : 3,
          scenes: [
            ArrayScene(
              values: values,
              title: 'nums',
              states: {
                for (var j = 0; j < i; j++) j: VizState.done,
                i: isDuplicate ? VizState.success : VizState.active,
              },
              pointers: {'i': i},
            ),
            MapScene(
              entries: seen
                  .map(
                    (v) => (
                      key: '$v',
                      value: '✓',
                      state: v == nums[i] ? VizState.success : VizState.idle,
                    ),
                  )
                  .toList(),
              title: 'seen',
              emptyLabel: 'nothing seen yet',
            ),
          ],
        ),
      );

      if (isDuplicate) {
        duplicateAt = i;
        break;
      }
      seen.add(nums[i]);
    }

    steps.add(
      VizStep(
        caption: duplicateAt >= 0
            ? 'Answer: true. We stopped at index $duplicateAt without needing '
                  'to read the rest of the array.'
            : 'We reached the end with no repeats, so the answer is false.',
        codeLine: 4,
        insight:
            'A HashSet turns "have I seen this before?" from a scan into a '
            'single O(1) check. That swap is the foundation of almost every '
            'hashing problem.',
        scenes: [
          ValueScene(
            readings: [
              (
                label: 'result',
                value: duplicateAt >= 0 ? 'true' : 'false',
                state: VizState.success,
              ),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'contains-duplicate',
      title: 'Contains Duplicate',
      pattern: 'Hash Map',
      patternIdea:
          'A set answers "have I seen this?" instantly, which removes the '
          'inner loop from a pairwise comparison.',
      pseudocode: const [
        'Set<Integer> seen = new HashSet<>();',
        'for (int num : nums) {',
        '    if (seen.contains(num)) return true;',
        '    seen.add(num);',
        '}',
        'return false;',
      ],
      steps: steps,
      timeComplexity: 'O(n) — one pass, O(1) lookups',
      spaceComplexity: 'O(n) — the set may hold every number',
      takeaway:
          'Return as soon as you find the duplicate. There is no reason to '
          'finish scanning the array.',
      problemIds: const ['01', 'b3'],
    );
  }

  // ----------------------------------------------------------------- 02

  static AlgorithmTrace validAnagram() {
    const a = 'anagram';
    const b = 'nagaram';
    final steps = <VizStep>[];
    final counts = <String, int>{};

    steps.add(
      VizStep(
        caption:
            'Are "$a" and "$b" the same letters rearranged? Sorting both '
            'works but costs n log n. Counting letters costs only n.',
        codeLine: 1,
        scenes: [
          ArrayScene(values: a.split(''), title: 's'),
          ArrayScene(values: b.split(''), title: 't'),
        ],
      ),
    );

    for (var i = 0; i < a.length; i++) {
      counts[a[i]] = (counts[a[i]] ?? 0) + 1;
      steps.add(
        VizStep(
          caption:
              'Count up for "${a[i]}" from the first word. We are tallying '
              'how many of each letter the answer must contain.',
          codeLine: 3,
          scenes: [
            ArrayScene(
              values: a.split(''),
              title: 's',
              states: {
                for (var j = 0; j < i; j++) j: VizState.done,
                i: VizState.active,
              },
              pointers: {'i': i},
            ),
            MapScene(
              entries: _entries(counts, hit: a[i]),
              title: 'letter counts',
            ),
          ],
        ),
      );
    }

    var ok = true;
    for (var i = 0; i < b.length; i++) {
      final ch = b[i];
      final before = counts[ch] ?? 0;
      if (before == 0) {
        ok = false;
        steps.add(
          VizStep(
            caption:
                '"$ch" is not available in the tally, so the second word has '
                'a letter the first does not. Not an anagram.',
            codeLine: 5,
            scenes: [
              ArrayScene(
                values: b.split(''),
                title: 't',
                states: {i: VizState.fail},
                pointers: {'i': i},
              ),
              MapScene(entries: _entries(counts), title: 'letter counts'),
            ],
          ),
        );
        break;
      }
      counts[ch] = before - 1;
      if (counts[ch] == 0) counts.remove(ch);

      steps.add(
        VizStep(
          caption:
              'Count down for "$ch" from the second word. Every letter that '
              'cancels out brings the tally closer to empty.',
          codeLine: 6,
          scenes: [
            ArrayScene(
              values: b.split(''),
              title: 't',
              states: {
                for (var j = 0; j < i; j++) j: VizState.done,
                i: VizState.active,
              },
              pointers: {'i': i},
            ),
            MapScene(
              entries: _entries(counts),
              title: 'letter counts',
              emptyLabel: 'all letters cancelled',
            ),
          ],
        ),
      );
    }

    if (ok) {
      steps.add(
        VizStep(
          caption:
              'Every letter cancelled and the tally is empty, so the two '
              'words are anagrams.',
          codeLine: 8,
          insight:
              'Because both words have the same length, an empty tally at the '
              'end is enough. Check the lengths first and you can skip a whole '
              'class of edge cases.',
          scenes: [
            MapScene(
              entries: _entries(counts),
              title: 'letter counts',
              emptyLabel: 'empty',
            ),
            const ValueScene(
              readings: [
                (label: 'result', value: 'true', state: VizState.success),
              ],
            ),
          ],
        ),
      );
    }

    return AlgorithmTrace(
      id: 'valid-anagram',
      title: 'Valid Anagram',
      pattern: 'Hash Map',
      patternIdea:
          'When order does not matter but quantity does, count instead of '
          'sorting.',
      pseudocode: const [
        'if (s.length() != t.length()) return false;',
        'Map<Character, Integer> count = new HashMap<>();',
        'for (char c : s.toCharArray())',
        '    count.merge(c, 1, Integer::sum);',
        'for (char c : t.toCharArray()) {',
        '    if (count.getOrDefault(c, 0) == 0) return false;',
        '    count.merge(c, -1, Integer::sum);',
        '}',
        'return true;',
      ],
      steps: steps,
      timeComplexity: 'O(n) — one pass up, one pass down',
      spaceComplexity: 'O(1) — at most 26 letters',
      takeaway:
          'Compare lengths first, then count up and down. If a count ever goes '
          'negative, stop.',
      problemIds: const ['02'],
    );
  }

  // ----------------------------------------------------------------- 03

  static AlgorithmTrace twoSum() {
    const nums = [2, 7, 11, 15];
    const target = 9;
    final values = nums.map((n) => '$n').toList();
    final steps = <VizStep>[];
    final seen = <int, int>{};

    steps.add(
      const VizStep(
        caption:
            'We need two numbers that add up to 9. The obvious way is to try '
            'every pair, which is slow. Instead we will walk the list once, '
            'keeping a notebook of every number we have already passed.',
        codeLine: 0,
        scenes: [
          ArrayScene(values: ['2', '7', '11', '15'], title: 'nums'),
          MapScene(
            entries: [],
            title: 'seen  (number → index)',
            emptyLabel: 'nothing written down yet',
          ),
        ],
      ),
    );

    for (var i = 0; i < nums.length; i++) {
      final need = target - nums[i];

      steps.add(
        VizStep(
          caption:
              'Look at ${nums[i]}. To reach $target we would still need '
              '$need.',
          codeLine: 2,
          scenes: [
            ArrayScene(
              values: values,
              title: 'nums',
              states: {
                for (var j = 0; j < i; j++) j: VizState.done,
                i: VizState.active,
              },
              pointers: {'i': i},
            ),
            MapScene(
              entries: _entries(seen),
              title: 'seen  (number → index)',
              emptyLabel: 'nothing written down yet',
            ),
            ValueScene(
              readings: [
                (
                  label: 'need',
                  value: '$target − ${nums[i]} = $need',
                  state: VizState.active,
                ),
              ],
            ),
          ],
        ),
      );

      steps.add(
        VizStep(
          caption:
              'Now the real question: is $need already in the notebook? This '
              'is one instant lookup, not another scan of the array.',
          codeLine: 3,
          scenes: [
            ArrayScene(
              values: values,
              title: 'nums',
              states: {
                for (var j = 0; j < i; j++) j: VizState.done,
                i: VizState.active,
              },
              pointers: {'i': i},
            ),
            MapScene(
              entries: _entries(seen),
              title: 'seen  (number → index)',
              emptyLabel: 'nothing written down yet',
            ),
            ValueScene(
              readings: [
                (label: 'looking up', value: '$need', state: VizState.compare),
              ],
            ),
          ],
        ),
      );

      if (seen.containsKey(need)) {
        final partner = seen[need]!;
        steps.add(
          VizStep(
            caption:
                'Yes — $need is in the notebook, written down at index '
                '$partner. So nums[$partner] + nums[$i] = $need + ${nums[i]} '
                '= $target. The answer is [$partner, $i].',
            codeLine: 4,
            insight:
                'The notebook turned "search the whole list again" into a '
                'single instant lookup. That is the whole trick behind hash '
                'maps: trade a little memory to avoid a repeated scan.',
            scenes: [
              ArrayScene(
                values: values,
                title: 'nums',
                states: {
                  for (var j = 0; j < nums.length; j++) j: VizState.dim,
                  partner: VizState.success,
                  i: VizState.success,
                },
                pointers: {'i': i},
              ),
              MapScene(
                entries: _entries(seen, hit: need),
                title: 'seen  (number → index)',
              ),
              ValueScene(
                readings: [
                  (
                    label: 'answer',
                    value: '[$partner, $i]',
                    state: VizState.success,
                  ),
                ],
              ),
            ],
          ),
        );
        break;
      }

      seen[nums[i]] = i;
      steps.add(
        VizStep(
          caption:
              'No, $need is not in the notebook yet. Write down that we saw '
              '${nums[i]} at index $i, then move on. Nothing is ever '
              'searched twice.',
          codeLine: 5,
          scenes: [
            ArrayScene(
              values: values,
              title: 'nums',
              states: {for (var j = 0; j <= i; j++) j: VizState.done},
              pointers: {'i': i},
            ),
            MapScene(
              entries: _entries(seen, hit: nums[i]),
              title: 'seen  (number → index)',
            ),
          ],
        ),
      );
    }

    return AlgorithmTrace(
      id: 'two-sum',
      title: 'Two Sum',
      pattern: 'Hash Map',
      patternIdea:
          'When you catch yourself scanning the list again from inside a loop, '
          'a hash map usually removes the inner scan entirely.',
      pseudocode: const [
        'Map<Integer, Integer> seen = new HashMap<>();',
        'for (int i = 0; i < nums.length; i++) {',
        '    int need = target - nums[i];',
        '    if (seen.containsKey(need))',
        '        return new int[]{seen.get(need), i};',
        '    seen.put(nums[i], i);',
        '}',
        'return new int[]{};',
      ],
      steps: steps,
      timeComplexity: 'O(n) — one pass, and each lookup is O(1)',
      spaceComplexity: 'O(n) — the notebook can hold every number',
      takeaway:
          'Ask "what value would complete my answer?", then look that value up '
          'instead of searching for it.',
      problemIds: const ['03', 'b1'],
    );
  }

  // ----------------------------------------------------------------- 04

  static AlgorithmTrace groupAnagrams() {
    const words = ['eat', 'tea', 'tan', 'ate'];
    final steps = <VizStep>[];
    final groups = <String, List<String>>{};

    steps.add(
      const VizStep(
        caption:
            'Group words that are rearrangements of each other. The trick is '
            'to give every word a fingerprint that is identical for anagrams — '
            'its sorted letters.',
        codeLine: 0,
        scenes: [
          ArrayScene(values: ['eat', 'tea', 'tan', 'ate'], title: 'words'),
          MapScene(
            entries: [],
            title: 'fingerprint → group',
            emptyLabel: 'no groups yet',
          ),
        ],
      ),
    );

    for (var i = 0; i < words.length; i++) {
      final key = (words[i].split('')..sort()).join();
      final isNew = !groups.containsKey(key);
      groups.putIfAbsent(key, () => []).add(words[i]);

      steps.add(
        VizStep(
          caption: isNew
              ? 'Sorting "${words[i]}" gives "$key". No group has that '
                    'fingerprint yet, so start a new one.'
              : 'Sorting "${words[i]}" gives "$key", which already exists. '
                    'Drop it into that group.',
          codeLine: 4,
          scenes: [
            ArrayScene(
              values: words,
              title: 'words',
              states: {
                for (var j = 0; j < i; j++) j: VizState.done,
                i: VizState.active,
              },
              pointers: {'i': i},
            ),
            MapScene(
              entries: groups.entries
                  .map(
                    (e) => (
                      key: e.key,
                      value: e.value.join(', '),
                      state: e.key == key ? VizState.success : VizState.idle,
                    ),
                  )
                  .toList(),
              title: 'fingerprint → group',
            ),
          ],
        ),
      );
    }

    steps.add(
      VizStep(
        caption:
            'Every word is filed. The map values are the answer: '
            '${groups.values.map((g) => '[${g.join(", ")}]').join(', ')}.',
        codeLine: 4,
        insight:
            'Any function that collapses equivalent inputs to the same key '
            'works here. A 26-slot letter count is an O(n) alternative to '
            'sorting each word.',
        scenes: [
          MapScene(
            entries: groups.entries
                .map(
                  (e) => (
                    key: e.key,
                    value: e.value.join(', '),
                    state: VizState.success,
                  ),
                )
                .toList(),
            title: 'fingerprint → group',
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'group-anagrams',
      title: 'Group Anagrams',
      pattern: 'Hash Map',
      patternIdea:
          'To group "equivalent" things, invent a key that is identical for '
          'members of a group and different otherwise.',
      pseudocode: const [
        'Map<String, List<String>> groups = new HashMap<>();',
        'for (String w : strs) {',
        '    char[] c = w.toCharArray();',
        '    Arrays.sort(c);',
        '    groups.computeIfAbsent(new String(c), k -> new ArrayList<>()).add(w);',
        '}',
        'return new ArrayList<>(groups.values());',
      ],
      steps: steps,
      timeComplexity: 'O(n · k log k) — sorting each of n words of length k',
      spaceComplexity: 'O(n · k) — every word is stored once',
      takeaway:
          'Sorted letters make a fine fingerprint; a letter-count array makes '
          'a faster one.',
      problemIds: const ['04'],
    );
  }

  // ----------------------------------------------------------------- 05

  static AlgorithmTrace topKFrequent() {
    const nums = [1, 1, 1, 2, 2, 3];
    const k = 2;
    final values = nums.map((n) => '$n').toList();
    final steps = <VizStep>[];
    final counts = <int, int>{};

    steps.add(
      const VizStep(
        caption:
            'Find the 2 most frequent numbers. Sorting by count costs '
            'n log n, but a count can never exceed the array length — so we '
            'can bucket by frequency and read the buckets backwards.',
        codeLine: 0,
        scenes: [
          ArrayScene(values: ['1', '1', '1', '2', '2', '3'], title: 'nums'),
        ],
      ),
    );

    for (var i = 0; i < nums.length; i++) {
      counts[nums[i]] = (counts[nums[i]] ?? 0) + 1;
    }
    steps.add(
      VizStep(
        caption:
            'First pass: tally how often each number appears. '
            '${counts.entries.map((e) => '${e.key} appears ${e.value}×').join(', ')}.',
        codeLine: 2,
        scenes: [
          ArrayScene(
            values: values,
            title: 'nums',
            states: {for (var j = 0; j < values.length; j++) j: VizState.done},
          ),
          MapScene(entries: _entries(counts), title: 'number → count'),
        ],
      ),
    );

    // buckets[f] holds every number seen exactly f times.
    final buckets = List.generate(nums.length + 1, (_) => <int>[]);
    counts.forEach((value, count) => buckets[count].add(value));

    steps.add(
      VizStep(
        caption:
            'Now place each number in a bucket named after its count. Bucket '
            'index is the frequency, so no sorting is needed.',
        codeLine: 3,
        scenes: [
          MapScene(
            entries: [
              for (var f = 1; f < buckets.length; f++)
                (
                  key: '$f×',
                  value: buckets[f].isEmpty ? '—' : buckets[f].join(', '),
                  state: buckets[f].isEmpty ? VizState.dim : VizState.idle,
                ),
            ],
            title: 'buckets  (frequency → numbers)',
          ),
        ],
      ),
    );

    final result = <int>[];
    for (var f = buckets.length - 1; f >= 1 && result.length < k; f--) {
      if (buckets[f].isEmpty) continue;
      for (final value in buckets[f]) {
        if (result.length == k) break;
        result.add(value);
        steps.add(
          VizStep(
            caption:
                'Walk the buckets from the highest frequency down. $value '
                'appears $f times, so it is next in the answer. We now have '
                '${result.length} of $k.',
            codeLine: 6,
            scenes: [
              MapScene(
                entries: [
                  for (var b = buckets.length - 1; b >= 1; b--)
                    if (buckets[b].isNotEmpty)
                      (
                        key: '$b×',
                        value: buckets[b].join(', '),
                        state: b == f ? VizState.success : VizState.idle,
                      ),
                ],
                title: 'buckets  (frequency → numbers)',
              ),
              ValueScene(
                readings: [
                  (
                    label: 'answer so far',
                    value: '[${result.join(", ")}]',
                    state: VizState.active,
                  ),
                ],
              ),
            ],
          ),
        );
      }
    }

    steps.add(
      VizStep(
        caption:
            'We have $k numbers, so we stop. The answer is '
            '[${result.join(", ")}].',
        codeLine: 7,
        insight:
            'Bucket sort works here only because frequencies are bounded by n. '
            'Whenever your keys live in a small known range, buckets beat '
            'comparison sorting.',
        scenes: [
          ValueScene(
            readings: [
              (
                label: 'answer',
                value: '[${result.join(", ")}]',
                state: VizState.success,
              ),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'top-k-frequent',
      title: 'Top K Frequent Elements',
      pattern: 'Hash Map',
      patternIdea:
          'When the thing you are sorting by is bounded by n, bucket it '
          'instead of sorting it.',
      pseudocode: const [
        'Map<Integer, Integer> count = new HashMap<>();',
        'for (int n : nums)',
        '    count.merge(n, 1, Integer::sum);',
        'List<Integer>[] buckets = new List[nums.length + 1];',
        'for (var e : count.entrySet()) buckets[e.getValue()].add(e.getKey());',
        'for (int f = buckets.length - 1; f >= 1; f--)',
        '    for (int v : buckets[f]) if (res.size() < k) res.add(v);',
        'return res;',
      ],
      steps: steps,
      timeComplexity: 'O(n) — counting and bucketing are both linear',
      spaceComplexity: 'O(n) — counts plus buckets',
      takeaway:
          'Frequency can never exceed the array length, which is exactly what '
          'makes the bucket array safe to size as n + 1.',
      problemIds: const ['05'],
    );
  }

  // ----------------------------------------------------------------- 06

  static AlgorithmTrace validSudoku() {
    // A small 4x4 stand-in keeps every cell visible on a phone while teaching
    // the identical row / column / box rule.
    const board = [
      ['5', '3', '.', '.'],
      ['6', '.', '.', '1'],
      ['.', '9', '8', '.'],
      ['.', '.', '.', '6'],
    ];
    final cells = board.map((r) => r.toList()).toList();
    final steps = <VizStep>[];

    final rowSeen = List.generate(4, (_) => <String>{});
    final colSeen = List.generate(4, (_) => <String>{});
    final boxSeen = List.generate(4, (_) => <String>{});

    int boxOf(int r, int c) => (r ~/ 2) * 2 + (c ~/ 2);

    steps.add(
      VizStep(
        caption:
            'A board is valid when no digit repeats in any row, any column, '
            'or any box. Rather than three separate scans, check all three '
            'rules in a single pass using three sets.',
        codeLine: 0,
        scenes: [GridScene(cells: cells, title: 'board')],
      ),
    );

    var valid = true;
    outer:
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        final v = board[r][c];
        if (v == '.') continue;

        final b = boxOf(r, c);
        final clash =
            rowSeen[r].contains(v) ||
            colSeen[c].contains(v) ||
            boxSeen[b].contains(v);

        steps.add(
          VizStep(
            caption: clash
                ? 'Cell ($r,$c) holds $v, which already appears in its row, '
                      'column or box. The board is invalid.'
                : 'Cell ($r,$c) holds $v. It is new to row $r, column $c and '
                      'box $b, so record it in all three sets.',
            codeLine: clash ? 5 : 4,
            scenes: [
              GridScene(
                cells: cells,
                title: 'board',
                states: {
                  for (var i = 0; i < 4; i++) ...{
                    r * 4 + i: VizState.compare,
                    i * 4 + c: VizState.compare,
                  },
                  r * 4 + c: clash ? VizState.fail : VizState.active,
                },
              ),
              ValueScene(
                readings: [
                  (
                    label: 'row $r',
                    value: rowSeen[r].isEmpty ? '—' : rowSeen[r].join(','),
                    state: VizState.idle,
                  ),
                  (
                    label: 'col $c',
                    value: colSeen[c].isEmpty ? '—' : colSeen[c].join(','),
                    state: VizState.idle,
                  ),
                  (
                    label: 'box $b',
                    value: boxSeen[b].isEmpty ? '—' : boxSeen[b].join(','),
                    state: VizState.idle,
                  ),
                ],
              ),
            ],
          ),
        );

        if (clash) {
          valid = false;
          break outer;
        }
        rowSeen[r].add(v);
        colSeen[c].add(v);
        boxSeen[b].add(v);
      }
    }

    steps.add(
      VizStep(
        caption: valid
            ? 'Every filled cell passed all three checks, so the board is '
                  'valid.'
            : 'A clash was found, so the board is invalid.',
        codeLine: 7,
        insight:
            'The only real insight is the box index: (row / 3) * 3 + (col / 3) '
            'on a real 9×9 board. Get that formula right and the rest is '
            'bookkeeping.',
        scenes: [
          ValueScene(
            readings: [
              (
                label: 'result',
                value: '$valid',
                state: valid ? VizState.success : VizState.fail,
              ),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'valid-sudoku',
      title: 'Valid Sudoku',
      pattern: 'Hash Map',
      patternIdea:
          'Three independent constraints can share one pass if you keep one '
          'set per constraint.',
      pseudocode: const [
        'Set<String>[] rows, cols, boxes;  // 9 each',
        'for (int r = 0; r < 9; r++)',
        '    for (int c = 0; c < 9; c++) {',
        '        char v = board[r][c];  int b = (r/3)*3 + (c/3);',
        '        if (!rows[r].add(v) || !cols[c].add(v) || !boxes[b].add(v))',
        '            return false;',
        '    }',
        'return true;',
      ],
      steps: steps,
      timeComplexity: 'O(1) — a 9×9 board is a fixed 81 cells',
      spaceComplexity: 'O(1) — 27 sets of at most 9 digits',
      takeaway:
          'Set.add returns false when the value was already present, so the '
          'check and the insert are the same operation.',
      problemIds: const ['06'],
    );
  }

  // ----------------------------------------------------------------- 07

  static AlgorithmTrace productExceptSelf() {
    const nums = [1, 2, 3, 4];
    final values = nums.map((n) => '$n').toList();
    final steps = <VizStep>[];
    final result = List<int>.filled(nums.length, 1);

    steps.add(
      const VizStep(
        caption:
            'Each answer is the product of everything except the current '
            'number — and division is not allowed. The trick: the answer at i '
            'is (everything to the left) × (everything to the right).',
        codeLine: 0,
        scenes: [
          ArrayScene(values: ['1', '2', '3', '4'], title: 'nums'),
        ],
      ),
    );

    var prefix = 1;
    for (var i = 0; i < nums.length; i++) {
      result[i] = prefix;
      steps.add(
        VizStep(
          caption:
              'Left-to-right pass: store the product of everything before '
              'index $i, which is $prefix.',
          codeLine: 2,
          scenes: [
            ArrayScene(
              values: values,
              title: 'nums',
              states: {
                for (var j = 0; j < i; j++) j: VizState.done,
                i: VizState.active,
              },
              pointers: {'i': i},
            ),
            ArrayScene(
              values: result.map((n) => '$n').toList(),
              title: 'answer (prefix products)',
              states: {i: VizState.success},
            ),
          ],
        ),
      );
      prefix *= nums[i];
    }

    var suffix = 1;
    for (var i = nums.length - 1; i >= 0; i--) {
      result[i] *= suffix;
      steps.add(
        VizStep(
          caption:
              'Right-to-left pass: multiply in the product of everything '
              'after index $i, which is $suffix. Index $i is now final at '
              '${result[i]}.',
          codeLine: 6,
          scenes: [
            ArrayScene(
              values: values,
              title: 'nums',
              states: {
                for (var j = nums.length - 1; j > i; j--) j: VizState.done,
                i: VizState.active,
              },
              pointers: {'i': i},
            ),
            ArrayScene(
              values: result.map((n) => '$n').toList(),
              title: 'answer',
              states: {i: VizState.success},
            ),
          ],
        ),
      );
      suffix *= nums[i];
    }

    steps.add(
      VizStep(
        caption:
            'Both passes are done. The answer is [${result.join(", ")}], '
            'computed without a single division.',
        codeLine: 8,
        insight:
            'Reusing the output array for the prefix products is what gets '
            'this to O(1) extra space. The suffix only ever needs one running '
            'variable.',
        scenes: [
          ArrayScene(
            values: result.map((n) => '$n').toList(),
            title: 'answer',
            states: {
              for (var j = 0; j < result.length; j++) j: VizState.success,
            },
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'product-except-self',
      title: 'Product of Array Except Self',
      pattern: 'Prefix Sum',
      patternIdea:
          'Anything of the form "all elements except this one" splits neatly '
          'into a left part and a right part.',
      pseudocode: const [
        'int[] res = new int[nums.length];  int prefix = 1;',
        'for (int i = 0; i < nums.length; i++) {',
        '    res[i] = prefix;  prefix *= nums[i];',
        '}',
        'int suffix = 1;',
        'for (int i = nums.length - 1; i >= 0; i--) {',
        '    res[i] *= suffix;  suffix *= nums[i];',
        '}',
        'return res;',
      ],
      steps: steps,
      timeComplexity: 'O(n) — two passes',
      spaceComplexity: 'O(1) extra — the output array does not count',
      takeaway:
          'Write the prefix products into the answer first, then fold the '
          'suffix in on the way back.',
      problemIds: const ['07', 'b4'],
    );
  }

  // ----------------------------------------------------------------- 08

  static AlgorithmTrace longestConsecutive() {
    const nums = [100, 4, 200, 1, 3, 2];
    final values = nums.map((n) => '$n').toList();
    final steps = <VizStep>[];
    final set = nums.toSet();

    steps.add(
      const VizStep(
        caption:
            'Find the longest run of consecutive numbers. Sorting would cost '
            'n log n. Instead, put everything in a set and only start counting '
            'from numbers that begin a run.',
        codeLine: 0,
        scenes: [
          ArrayScene(values: ['100', '4', '200', '1', '3', '2'], title: 'nums'),
        ],
      ),
    );

    var best = 0;
    var bestStart = 0;
    for (var i = 0; i < nums.length; i++) {
      final n = nums[i];
      final isStart = !set.contains(n - 1);

      if (!isStart) {
        steps.add(
          VizStep(
            caption:
                '$n is not the start of a run, because ${n - 1} is also in '
                'the set. Skip it — the run containing $n gets counted from '
                'its own beginning.',
            codeLine: 3,
            scenes: [
              ArrayScene(
                values: values,
                title: 'nums',
                states: {i: VizState.dim},
                pointers: {'i': i},
              ),
            ],
          ),
        );
        continue;
      }

      var length = 1;
      while (set.contains(n + length)) {
        length++;
      }
      if (length > best) {
        best = length;
        bestStart = n;
      }

      steps.add(
        VizStep(
          caption:
              '${n - 1} is not in the set, so $n starts a run. Walk upward '
              'while the next number exists: the run reaches length $length. '
              'Best so far is $best.',
          codeLine: 4,
          scenes: [
            ArrayScene(
              values: values,
              title: 'nums',
              states: {
                for (var j = 0; j < values.length; j++)
                  if (nums[j] >= n && nums[j] < n + length)
                    j: VizState.success
                  else
                    j: VizState.idle,
              },
              pointers: {'i': i},
            ),
            ValueScene(
              readings: [
                (
                  label: 'run from $n',
                  value: '$length',
                  state: VizState.active,
                ),
                (label: 'best', value: '$best', state: VizState.idle),
              ],
            ),
          ],
        ),
      );
    }

    steps.add(
      VizStep(
        caption:
            'The longest consecutive run is $best long, starting at '
            '$bestStart.',
        codeLine: 7,
        insight:
            'The "only start from a run beginning" check is what keeps this '
            'linear. Without it the inner while loop would re-walk the same '
            'run once per member.',
        scenes: [
          ValueScene(
            readings: [
              (label: 'answer', value: '$best', state: VizState.success),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'longest-consecutive',
      title: 'Longest Consecutive Sequence',
      pattern: 'Hash Map',
      patternIdea:
          'A set lets you ask "does the neighbour exist?" instantly, which '
          'replaces sorting entirely.',
      pseudocode: const [
        'Set<Integer> set = new HashSet<>();  int best = 0;',
        'for (int n : nums) set.add(n);',
        'for (int n : set) {',
        '    if (set.contains(n - 1)) continue;   // not a run start',
        '    int len = 1;  while (set.contains(n+len)) len++;',
        '    best = Math.max(best, len);',
        '}',
        'return best;',
      ],
      steps: steps,
      timeComplexity: 'O(n) — each run is walked exactly once',
      spaceComplexity: 'O(n) — the set',
      takeaway:
          'Only expand from numbers with no left neighbour. That single guard '
          'is the difference between O(n) and O(n²).',
      problemIds: const ['08'],
    );
  }
}
