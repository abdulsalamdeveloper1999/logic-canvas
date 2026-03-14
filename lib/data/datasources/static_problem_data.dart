import 'package:logic_canvas/domain/entities/problem.dart';

class ProblemData {
  static const List<Problem> paretoProblems = [
    // Arrays & Hashing
    Problem(
      id: '01',
      title: 'Contains Duplicate',
      category: 'Arrays & Hashing',
      difficulty: Difficulty.easy,
      url: 'https://leetcode.com/problems/contains-duplicate/',
      description:
          'Given an integer array nums, return true if any value appears at least twice in the array, and return false if every element is distinct.',
      examples: [
        ProblemExample(input: 'nums = [1,2,3,1]', output: 'true'),
        ProblemExample(input: 'nums = [1,2,3,4]', output: 'false'),
        ProblemExample(input: 'nums = [1,1,1,3,3,4,3,2,4,2]', output: 'true'),
      ],
      hints: [
        'A naive solution would be to compare every pair of elements.',
        'Can we use a data structure to track elements we have seen before?',
        'Think about the time complexity of searching in a Hash Set.',
      ],
    ),
    Problem(
      id: '02',
      title: 'Valid Anagram',
      category: 'Arrays & Hashing',
      difficulty: Difficulty.easy,
      url: 'https://leetcode.com/problems/valid-anagram/',
      description:
          'Given two strings s and t, return true if t is an anagram of s, and false otherwise.',
      examples: [
        ProblemExample(input: 's = "anagram", t = "nagaram"', output: 'true'),
        ProblemExample(input: 's = "rat", t = "car"', output: 'false'),
      ],
      hints: [
        'An anagram uses the same characters with the same frequencies.',
        'Could we sort the strings and compare them?',
        'Is there a way to count character frequencies using an array or hash map?',
      ],
    ),
    Problem(
      id: '03',
      title: 'Two Sum',
      category: 'Arrays & Hashing',
      difficulty: Difficulty.easy,
      url: 'https://leetcode.com/problems/two-sum/',
      description:
          'Given an array of integers nums and an integer target, return indices of the two numbers such that they add up to target. You may assume that each input would have exactly one solution, and you may not use the same element twice.',
      examples: [
        ProblemExample(
          input: 'nums = [2,7,11,15], target = 9',
          output: '[0,1]',
          explanation: 'Because nums[0] + nums[1] == 9, we return [0, 1].',
        ),
        ProblemExample(input: 'nums = [3,2,4], target = 6', output: '[1,2]'),
        ProblemExample(input: 'nums = [3,3], target = 6', output: '[0,1]'),
      ],
      hints: [
        'The brute force approach is O(n²). Can we do better?',
        'If we know the target and the current value, what value are we looking for?',
        'A hash map can help us find the complement in O(1) time.',
      ],
    ),
    Problem(
      id: '04',
      title: 'Group Anagrams',
      category: 'Arrays & Hashing',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/group-anagrams/',
      description:
          'Given an array of strings strs, group the anagrams together. You can return the answer in any order.',
      examples: [
        ProblemExample(
          input: 'strs = ["eat","tea","tan","ate","nat","bat"]',
          output: '[["bat"],["nat","tan"],["ate","eat","tea"]]',
        ),
        ProblemExample(input: 'strs = [""]', output: '[[""]]'),
        ProblemExample(input: 'strs = ["a"]', output: '[["a"]]'),
      ],
    ),
    Problem(
      id: '05',
      title: 'Top K Frequent Elements',
      category: 'Arrays & Hashing',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/top-k-frequent-elements/',
      description:
          'Given an integer array nums and an integer k, return the k most frequent elements. You may return the answer in any order.',
      examples: [
        ProblemExample(input: 'nums = [1,1,1,2,2,3], k = 2', output: '[1,2]'),
        ProblemExample(input: 'nums = [1], k = 1', output: '[1]'),
      ],
    ),
    Problem(
      id: '06',
      title: 'Valid Sudoku',
      category: 'Arrays & Hashing',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/valid-sudoku/',
      description:
          'Determine if a 9 x 9 Sudoku board is valid. Only the filled cells need to be validated according to the following rules:\n1. Each row must contain the digits 1-9 without repetition.\n2. Each column must contain the digits 1-9 without repetition.\n3. Each of the nine 3 x 3 sub-boxes of the grid must contain the digits 1-9 without repetition.',
      examples: [
        ProblemExample(
          input:
              'board = [["5","3",".",".","7",".",".",".","."],["6",".",".","1","9","5",".",".","."],[".","9","8",".",".",".",".","6","."],["8",".",".",".","6",".",".",".","3"],["4",".",".","8",".","3",".",".","1"],["7",".",".",".","2",".",".",".","6"],[".","6",".",".",".",".","2","8","."],[".",".",".","4","1","9",".",".","5"],[".",".",".",".","8",".",".","7","9"]]',
          output: 'true',
        ),
      ],
    ),
    Problem(
      id: '07',
      title: 'Product of Array Except Self',
      category: 'Arrays & Hashing',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/product-of-array-except-self/',
      description:
          'Given an integer array nums, return an array answer such that answer[i] is equal to the product of all the elements of nums except nums[i]. The algorithm should run in O(n) time and without using the division operation.',
      examples: [
        ProblemExample(input: 'nums = [1,2,3,4]', output: '[24,12,8,6]'),
        ProblemExample(input: 'nums = [-1,1,0,-3,3]', output: '[0,0,9,0,0]'),
      ],
    ),
    Problem(
      id: '08',
      title: 'Longest Consecutive Sequence',
      category: 'Arrays & Hashing',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/longest-consecutive-sequence/',
      description:
          'Given an unsorted array of integers nums, return the length of the longest consecutive elements sequence. You must write an algorithm that runs in O(n) time.',
      examples: [
        ProblemExample(
          input: 'nums = [100,4,200,1,3,2]',
          output: '4',
          explanation:
              'The longest consecutive elements sequence is [1, 2, 3, 4]. Therefore its length is 4.',
        ),
        ProblemExample(input: 'nums = [0,3,7,2,5,8,4,6,0,1]', output: '9'),
      ],
    ),

    // Two Pointers
    Problem(
      id: '09',
      title: 'Valid Palindrome',
      category: 'Two Pointers',
      difficulty: Difficulty.easy,
      url: 'https://leetcode.com/problems/valid-palindrome/',
      description:
          'A phrase is a palindrome if, after converting all uppercase letters into lowercase letters and removing all non-alphanumeric characters, it reads the same forward and backward. Alphanumeric characters include letters and numbers.',
      examples: [
        ProblemExample(
          input: 's = "A man, a plan, a canal: Panama"',
          output: 'true',
          explanation: '"amanaplanacanalpanama" is a palindrome.',
        ),
        ProblemExample(
          input: 's = "race a car"',
          output: 'false',
          explanation: '"raceacar" is not a palindrome.',
        ),
        ProblemExample(
          input: 's = " "',
          output: 'true',
          explanation:
              's is an empty string "" after removing non-alphanumeric characters. Since an empty string reads the same forward and backward, it is a palindrome.',
        ),
      ],
    ),
    Problem(
      id: '10',
      title: 'Two Sum II - Input Array Is Sorted',
      category: 'Two Pointers',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/two-sum-ii-input-array-is-sorted/',
      description:
          'Given a 1-indexed array of integers numbers that is already sorted in non-decreasing order, find two numbers such that they add up to a specific target number. Let these two numbers be numbers[index1] and numbers[index2] where 1 <= index1 < index2 <= numbers.length.',
      examples: [
        ProblemExample(
          input: 'numbers = [2,7,11,15], target = 9',
          output: '[1,2]',
          explanation:
              'The sum of 2 and 7 is 9. Therefore, index1 = 1, index2 = 2. We return [1, 2].',
        ),
        ProblemExample(input: 'numbers = [2,3,4], target = 6', output: '[1,3]'),
        ProblemExample(input: 'numbers = [-1,0], target = -1', output: '[1,2]'),
      ],
    ),
    Problem(
      id: '11',
      title: '3Sum',
      category: 'Two Pointers',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/3sum/',
      description:
          'Given an integer array nums, return all the triplets [nums[i], nums[j], nums[k]] such that i != j, i != k, and j != k, and nums[i] + nums[j] + nums[k] == 0.',
      examples: [
        ProblemExample(
          input: 'nums = [-1,0,1,2,-1,-4]',
          output: '[[-1,-1,2],[-1,0,1]]',
        ),
        ProblemExample(input: 'nums = [0,1,1]', output: '[]'),
        ProblemExample(input: 'nums = [0,0,0]', output: '[[0,0,0]]'),
      ],
    ),
    Problem(
      id: '12',
      title: 'Container With Most Water',
      category: 'Two Pointers',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/container-with-most-water/',
      description:
          'You are given an integer array height of length n. There are n vertical lines drawn such that the two endpoints of the ith line are (i, 0) and (i, height[i]). Find two lines that together with the x-axis form a container, such that the container contains the most water.',
      examples: [
        ProblemExample(
          input: 'height = [1,8,6,2,5,4,8,3,7]',
          output: '49',
          explanation:
              'The above vertical lines are represented by array [1,8,6,2,5,4,8,3,7]. In this case, the max area of water (blue section) the container can contain is 49.',
        ),
        ProblemExample(input: 'height = [1,1]', output: '1'),
      ],
    ),

    // Sliding Window
    Problem(
      id: '13',
      title: 'Best Time to Buy and Sell Stock',
      category: 'Sliding Window',
      difficulty: Difficulty.easy,
      url: 'https://leetcode.com/problems/best-time-to-buy-and-sell-stock/',
      description:
          'You are given an array prices where prices[i] is the price of a given stock on the ith day. You want to maximize your profit by choosing a single day to buy one stock and choosing a different day in the future to sell that stock.',
      examples: [
        ProblemExample(
          input: 'prices = [7,1,5,3,6,4]',
          output: '5',
          explanation:
              'Buy on day 2 (price = 1) and sell on day 5 (price = 6), profit = 6-1 = 5.',
        ),
        ProblemExample(
          input: 'prices = [7,6,4,3,1]',
          output: '0',
          explanation:
              'In this case, no transactions are done and the max profit = 0.',
        ),
      ],
    ),
    Problem(
      id: '14',
      title: 'Longest Substring Without Repeating Characters',
      category: 'Sliding Window',
      difficulty: Difficulty.medium,
      url:
          'https://leetcode.com/problems/longest-substring-without-repeating-characters/',
      description:
          'Given a string s, find the length of the longest substring without repeating characters.',
      examples: [
        ProblemExample(
          input: 's = "abcabcbb"',
          output: '3',
          explanation: 'The answer is "abc", with the length of 3.',
        ),
        ProblemExample(
          input: 's = "bbbbb"',
          output: '1',
          explanation: 'The answer is "b", with the length of 1.',
        ),
        ProblemExample(
          input: 's = "pwwkew"',
          output: '3',
          explanation: 'The answer is "wke", with the length of 3.',
        ),
      ],
    ),
    Problem(
      id: '15',
      title: 'Longest Repeating Character Replacement',
      category: 'Sliding Window',
      difficulty: Difficulty.medium,
      url:
          'https://leetcode.com/problems/longest-repeating-character-replacement/',
      description:
          'You are given a string s and an integer k. You can choose any character of the string and change it to any other uppercase English character. You can perform this operation at most k times.',
      examples: [
        ProblemExample(
          input: 's = "ABAB", k = 2',
          output: '4',
          explanation: 'Replace the two \'A\'s with two \'B\'s or vice versa.',
        ),
        ProblemExample(
          input: 's = "AABABBA", k = 1',
          output: '4',
          explanation:
              'Replace the one \'A\' in the middle with \'B\' and form "AABBBBA". The substring "BBBB" has the longest repeating character, which is 4.',
        ),
      ],
    ),

    // Stack
    Problem(
      id: '16',
      title: 'Valid Parentheses',
      category: 'Stack',
      difficulty: Difficulty.easy,
      url: 'https://leetcode.com/problems/valid-parentheses/',
      description:
          'Given a string s containing just the characters \'(\', \')\', \'{\', \'}\', \'[\' and \']\', determine if the input string is valid.',
      examples: [
        ProblemExample(input: 's = "()"', output: 'true'),
        ProblemExample(input: 's = "()[]{}"', output: 'true'),
        ProblemExample(input: 's = "(]"', output: 'false'),
      ],
    ),
    Problem(
      id: '17',
      title: 'Min Stack',
      category: 'Stack',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/min-stack/',
      description:
          'Design a stack that supports push, pop, top, and retrieving the minimum element in constant time.',
      examples: [
        ProblemExample(
          input:
              '["MinStack","push","push","push","getMin","pop","top","getMin"]\n[[],[-2],[0],[-3],[],[],[],[]]',
          output: '[null,null,null,null,-3,null,0,-2]',
        ),
      ],
    ),
    Problem(
      id: '18',
      title: 'Daily Temperatures',
      category: 'Stack',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/daily-temperatures/',
      description:
          'Given an array of integers temperatures represents the daily temperatures, return an array answer such that answer[i] is the number of days you have to wait after the ith day to get a warmer temperature.',
      examples: [
        ProblemExample(
          input: 'temperatures = [73,74,75,71,69,72,76,73]',
          output: '[1,1,4,2,1,1,0,0]',
        ),
        ProblemExample(
          input: 'temperatures = [30,40,50,60]',
          output: '[1,1,1,0]',
        ),
        ProblemExample(input: 'temperatures = [30,60,90]', output: '[1,1,0]'),
      ],
    ),

    // Binary Search
    Problem(
      id: '19',
      title: 'Binary Search',
      category: 'Binary Search',
      difficulty: Difficulty.easy,
      url: 'https://leetcode.com/problems/binary-search/',
      description:
          'Given an array of integers nums which is sorted in ascending order, and an integer target, write a function to search target in nums. If target exists, then return its index. Otherwise, return -1.',
      examples: [
        ProblemExample(
          input: 'nums = [-1,0,3,5,9,12], target = 9',
          output: '4',
          explanation: '9 exists in nums and its index is 4',
        ),
        ProblemExample(
          input: 'nums = [-1,0,3,5,9,12], target = 2',
          output: '-1',
          explanation: '2 does not exist in nums so return -1',
        ),
      ],
    ),
    Problem(
      id: '20',
      title: 'Find Minimum in Rotated Sorted Array',
      category: 'Binary Search',
      difficulty: Difficulty.medium,
      url:
          'https://leetcode.com/problems/find-minimum-in-rotated-sorted-array/',
      description:
          'Suppose an array of length n sorted in ascending order is rotated between 1 and n times. For example, the array nums = [0,1,2,4,5,6,7] might become [4,5,6,7,0,1,2]. Given the sorted rotated array nums of unique elements, return the minimum element of this array.',
      examples: [
        ProblemExample(
          input: 'nums = [3,4,5,1,2]',
          output: '1',
          explanation: 'The original array was [1,2,3,4,5] rotated 3 times.',
        ),
        ProblemExample(
          input: 'nums = [4,5,6,7,0,1,2]',
          output: '0',
          explanation:
              'The original array was [0,1,2,4,5,6,7] rotated 4 times.',
        ),
        ProblemExample(
          input: 'nums = [11,13,15,17]',
          output: '11',
          explanation:
              'The original array was [11,13,15,17] and it was rotated 4 times.',
        ),
      ],
    ),
    Problem(
      id: '21',
      title: 'Search in Rotated Sorted Array',
      category: 'Binary Search',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/search-in-rotated-sorted-array/',
      description:
          'There is an integer array nums sorted in ascending order (with distinct values). Prior to being passed to your function, nums is possibly rotated at an unknown pivot index k. Given the array nums after the possible rotation and an integer target, return the index of target if it is in nums, or -1 if it is not in nums.',
      examples: [
        ProblemExample(
          input: 'nums = [4,5,6,7,0,1,2], target = 0',
          output: '4',
        ),
        ProblemExample(
          input: 'nums = [4,5,6,7,0,1,2], target = 3',
          output: '-1',
        ),
        ProblemExample(input: 'nums = [1], target = 0', output: '-1'),
      ],
    ),

    // Linked List
    Problem(
      id: '22',
      title: 'Reverse Linked List',
      category: 'Linked List',
      difficulty: Difficulty.easy,
      url: 'https://leetcode.com/problems/reverse-linked-list/',
      description:
          'Given the head of a singly linked list, reverse the list, and return the reversed list.',
      examples: [
        ProblemExample(input: 'head = [1,2,3,4,5]', output: '[5,4,3,2,1]'),
        ProblemExample(input: 'head = [1,2]', output: '[2,1]'),
        ProblemExample(input: 'head = []', output: '[]'),
      ],
    ),
    Problem(
      id: '23',
      title: 'Merge Two Sorted Lists',
      category: 'Linked List',
      difficulty: Difficulty.easy,
      url: 'https://leetcode.com/problems/merge-two-sorted-lists/',
      description:
          'You are given the heads of two sorted linked lists list1 and list2. Merge the two lists in a sorted list. The list should be made by splicing together the nodes of the first two lists.',
      examples: [
        ProblemExample(
          input: 'list1 = [1,2,4], list2 = [1,3,4]',
          output: '[1,1,2,3,4,4]',
        ),
        ProblemExample(input: 'list1 = [], list2 = []', output: '[]'),
        ProblemExample(input: 'list1 = [], list2 = [0]', output: '[0]'),
      ],
    ),
    Problem(
      id: '24',
      title: 'Reorder List',
      category: 'Linked List',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/reorder-list/',
      description:
          'You are given the head of a singly linked-list. The list can be represented as: L0 → L1 → … → Ln-1 → Ln. Reorder the list to be on the following form: L0 → Ln → L1 → Ln-1 → L2 → Ln-2 → …',
      examples: [
        ProblemExample(input: 'head = [1,2,3,4]', output: '[1,4,2,3]'),
        ProblemExample(input: 'head = [1,2,3,4,5]', output: '[1,5,2,4,3]'),
      ],
    ),
    Problem(
      id: '25',
      title: 'Remove Nth Node From End of List',
      category: 'Linked List',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/remove-nth-node-from-end-of-list/',
      description:
          'Given the head of a linked list, remove the nth node from the end of the list and return its head.',
      examples: [
        ProblemExample(input: 'head = [1,2,3,4,5], n = 2', output: '[1,2,3,5]'),
        ProblemExample(input: 'head = [1], n = 1', output: '[]'),
        ProblemExample(input: 'head = [1,2], n = 1', output: '[1]'),
      ],
    ),
    Problem(
      id: '26',
      title: 'Linked List Cycle',
      category: 'Linked List',
      difficulty: Difficulty.easy,
      url: 'https://leetcode.com/problems/linked-list-cycle/',
      description:
          'Given head, the head of a linked list, determine if the linked list has a cycle in it.',
      examples: [
        ProblemExample(
          input: 'head = [3,2,0,-4], pos = 1',
          output: 'true',
          explanation:
              'There is a cycle in the linked list, where the tail connects to the 1st node (0-indexed).',
        ),
        ProblemExample(
          input: 'head = [1,2], pos = 0',
          output: 'true',
          explanation:
              'There is a cycle in the linked list, where the tail connects to the 0th node.',
        ),
        ProblemExample(
          input: 'head = [1], pos = -1',
          output: 'false',
          explanation: 'There is no cycle in the linked list.',
        ),
      ],
    ),
    Problem(
      id: '27',
      title: 'LRU Cache',
      category: 'Linked List',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/lru-cache/',
      description:
          'Design a data structure that follows the constraints of a Least Recently Used (LRU) cache.',
      examples: [
        ProblemExample(
          input:
              '["LRUCache", "put", "put", "get", "put", "get", "put", "get", "get", "get"]\n[[2], [1, 1], [2, 2], [1], [3, 3], [2], [4, 4], [1], [3], [4]]',
          output: '[null, null, null, 1, null, -1, null, -1, 3, 4]',
        ),
      ],
    ),

    // Trees
    Problem(
      id: '28',
      title: 'Invert Binary Tree',
      category: 'Trees',
      difficulty: Difficulty.easy,
      url: 'https://leetcode.com/problems/invert-binary-tree/',
      description:
          'Given the root of a binary tree, invert the tree, and return its root.',
      examples: [
        ProblemExample(
          input: 'root = [4,2,7,1,3,6,9]',
          output: '[4,7,2,9,6,3,1]',
        ),
        ProblemExample(input: 'root = [2,1,3]', output: '[2,3,1]'),
        ProblemExample(input: 'root = []', output: '[]'),
      ],
    ),
    Problem(
      id: '29',
      title: 'Maximum Depth of Binary Tree',
      category: 'Trees',
      difficulty: Difficulty.easy,
      url: 'https://leetcode.com/problems/maximum-depth-of-binary-tree/',
      description:
          'Given the root of a binary tree, return its maximum depth. A binary tree\'s maximum depth is the number of nodes along the longest path from the root node down to the farthest leaf node.',
      examples: [
        ProblemExample(input: 'root = [3,9,20,null,null,15,7]', output: '3'),
        ProblemExample(input: 'root = [1,null,2]', output: '2'),
      ],
    ),
    Problem(
      id: '30',
      title: 'Diameter of Binary Tree',
      category: 'Trees',
      difficulty: Difficulty.easy,
      url: 'https://leetcode.com/problems/diameter-of-binary-tree/',
      description:
          'Given the root of a binary tree, return the length of the diameter of the tree. The diameter of a binary tree is the length of the longest path between any two nodes in a tree. This path may or may not pass through the root.',
      examples: [
        ProblemExample(
          input: 'root = [1,2,3,4,5]',
          output: '3',
          explanation: '3 is the length of the path [4,2,1,3] or [5,2,1,3].',
        ),
        ProblemExample(input: 'root = [1,2]', output: '1'),
      ],
    ),
    Problem(
      id: '31',
      title: 'Balanced Binary Tree',
      category: 'Trees',
      difficulty: Difficulty.easy,
      url: 'https://leetcode.com/problems/balanced-binary-tree/',
      description: 'Given a binary tree, determine if it is height-balanced.',
      examples: [
        ProblemExample(input: 'root = [3,9,20,null,null,15,7]', output: 'true'),
        ProblemExample(
          input: 'root = [1,2,2,3,3,null,null,4,4]',
          output: 'false',
        ),
        ProblemExample(input: 'root = []', output: 'true'),
      ],
    ),
    Problem(
      id: '32',
      title: 'Same Tree',
      category: 'Trees',
      difficulty: Difficulty.easy,
      url: 'https://leetcode.com/problems/same-tree/',
      description:
          'Given the roots of two binary trees p and q, write a function to check if they are the same or not.',
      examples: [
        ProblemExample(input: 'p = [1,2,3], q = [1,2,3]', output: 'true'),
        ProblemExample(input: 'p = [1,2], q = [1,null,2]', output: 'false'),
      ],
    ),
    Problem(
      id: '33',
      title: 'Subtree of Another Tree',
      category: 'Trees',
      difficulty: Difficulty.easy,
      url: 'https://leetcode.com/problems/subtree-of-another-tree/',
      description:
          'Given the roots of two binary trees root and subRoot, return true if there is a subtree of root with the same structure and node values of subRoot and false otherwise.',
      examples: [
        ProblemExample(
          input: 'root = [3,4,5,1,2], subRoot = [4,1,2]',
          output: 'true',
        ),
        ProblemExample(
          input: 'root = [3,4,5,1,2,null,null,null,null,0], subRoot = [4,1,2]',
          output: 'false',
        ),
      ],
    ),
    Problem(
      id: '34',
      title: 'Lowest Common Ancestor of a Binary Search Tree',
      category: 'Trees',
      difficulty: Difficulty.easy,
      url:
          'https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-search-tree/',
      description:
          'Given a binary search tree (BST), find the lowest common ancestor (LCA) node of two given nodes in the BST.',
      examples: [
        ProblemExample(
          input: 'root = [6,2,8,0,4,7,9,null,null,3,5], p = 2, q = 8',
          output: '6',
        ),
        ProblemExample(
          input: 'root = [6,2,8,0,4,7,9,null,null,3,5], p = 2, q = 4',
          output: '2',
        ),
      ],
    ),
    Problem(
      id: '35',
      title: 'Binary Tree Level Order Traversal',
      category: 'Trees',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/binary-tree-level-order-traversal/',
      description:
          'Given the root of a binary tree, return the level order traversal of its nodes\' values. (i.e., from left to right, level by level).',
      examples: [
        ProblemExample(
          input: 'root = [3,9,20,null,null,15,7]',
          output: '[[3],[9,20],[15,7]]',
        ),
        ProblemExample(input: 'root = [1]', output: '[[1]]'),
        ProblemExample(input: 'root = []', output: '[]'),
      ],
    ),
    Problem(
      id: '36',
      title: 'Binary Tree Right Side View',
      category: 'Trees',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/binary-tree-right-side-view/',
      description:
          'Given the root of a binary tree, imagine yourself standing on the right side of it, return the values of the nodes you can see ordered from top to bottom.',
      examples: [
        ProblemExample(
          input: 'root = [1,2,3,null,5,null,4]',
          output: '[1,3,4]',
        ),
        ProblemExample(input: 'root = [1,null,3]', output: '[1,3]'),
      ],
    ),
    Problem(
      id: '37',
      title: 'Count Good Nodes in Binary Tree',
      category: 'Trees',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/count-good-nodes-in-binary-tree/',
      description:
          'Given a binary tree root, a node X in the tree is named good if in the path from root to X there are no nodes with a value greater than X. Return the number of good nodes in the binary tree.',
      examples: [
        ProblemExample(input: 'root = [3,1,4,3,null,1,5]', output: '4'),
        ProblemExample(input: 'root = [3,3,null,4,2]', output: '3'),
      ],
    ),
    Problem(
      id: '38',
      title: 'Validate Binary Search Tree',
      category: 'Trees',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/validate-binary-search-tree/',
      description:
          'Given the root of a binary tree, determine if it is a valid binary search tree (BST).',
      examples: [
        ProblemExample(input: 'root = [2,1,3]', output: 'true'),
        ProblemExample(input: 'root = [5,1,4,null,null,3,6]', output: 'false'),
      ],
    ),
    Problem(
      id: '39',
      title: 'Kth Smallest Element in a BST',
      category: 'Trees',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/kth-smallest-element-in-a-bst/',
      description:
          'Given the root of a binary search tree, and an integer k, return the kth smallest value (1-indexed) of all the values of the nodes in the tree.',
      examples: [
        ProblemExample(input: 'root = [3,1,4,null,2], k = 1', output: '1'),
        ProblemExample(
          input: 'root = [5,3,6,2,4,null,null,1], k = 3',
          output: '3',
        ),
      ],
    ),

    // Heap / Priority Queue
    Problem(
      id: '40',
      title: 'Kth Largest Element in a Stream',
      category: 'Heap / Priority Queue',
      difficulty: Difficulty.easy,
      url: 'https://leetcode.com/problems/kth-largest-element-in-a-stream/',
      description:
          'Design a class to find the kth largest element in a stream. Note that it is the kth largest element in the sorted order, not the kth distinct element.',
      examples: [
        ProblemExample(
          input:
              '["KthLargest", "add", "add", "add", "add", "add"]\n[[3, [4, 5, 8, 2]], [3], [5], [10], [9], [4]]',
          output: '[null, 4, 5, 5, 8, 8]',
        ),
      ],
    ),
    Problem(
      id: '41',
      title: 'Last Stone Weight',
      category: 'Heap / Priority Queue',
      difficulty: Difficulty.easy,
      url: 'https://leetcode.com/problems/last-stone-weight/',
      description:
          'You are given an array of integers stones where stones[i] is the weight of the ith stone. We are playing a game with the stones. On each turn, we choose the heaviest two stones and smash them together.',
      examples: [
        ProblemExample(
          input: 'stones = [2,7,4,1,8,1]',
          output: '1',
          explanation:
              'We combine 7 and 8 to get 1; the array becomes [2,4,1,1,1]. We combine 2 and 4 to get 2; the array becomes [2,1,1,1]. We combine 2 and 1 to get 1; the array becomes [1,1,1]. We combine 1 and 1 to get 0; the array becomes [1]. The last stone has weight 1.',
        ),
        ProblemExample(input: 'stones = [1]', output: '1'),
      ],
    ),
    Problem(
      id: '42',
      title: 'Kth Largest Element in an Array',
      category: 'Heap / Priority Queue',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/kth-largest-element-in-an-array/',
      description:
          'Given an integer array nums and an integer k, return the kth largest element in the array. Note that it is the kth largest element in the sorted order, not the kth distinct element.',
      examples: [
        ProblemExample(input: 'nums = [3,2,1,5,6,4], k = 2', output: '5'),
        ProblemExample(input: 'nums = [3,2,3,1,2,4,5,5,6], k = 4', output: '4'),
      ],
    ),

    // Graphs
    Problem(
      id: '43',
      title: 'Number of Islands',
      category: 'Graphs',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/number-of-islands/',
      description:
          'Given an m x n 2D binary grid grid which represents a map of \'1\'s (land) and \'0\'s (water), return the number of islands. An island is surrounded by water and is formed by connecting adjacent lands horizontally or vertically.',
      examples: [
        ProblemExample(
          input:
              'grid = [["1","1","1","1","0"],["1","1","0","1","0"],["1","1","0","0","0"],["0","0","0","0","0"]]',
          output: '1',
        ),
        ProblemExample(
          input:
              'grid = [["1","1","0","0","0"],["1","1","0","0","0"],["0","0","1","0","0"],["0","0","0","1","1"]]',
          output: '3',
        ),
      ],
    ),
    Problem(
      id: '44',
      title: 'Max Area of Island',
      category: 'Graphs',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/max-area-of-island/',
      description:
          'You are given an m x n binary matrix grid. An island is a group of 1\'s (representing land) connected 4-directionally (horizontal or vertical). You may assume all four edges of the grid are surrounded by water. Return the maximum area of an island in grid.',
      examples: [
        ProblemExample(
          input:
              'grid = [[0,0,1,0,0,0,0,1,0,0,0,0,0],[0,0,0,0,0,0,0,1,1,1,0,0,0],[0,1,1,0,1,0,0,0,0,0,0,0,0],[0,1,0,0,1,1,0,0,1,0,1,0,0],[0,1,0,0,1,1,0,0,1,1,1,0,0],[0,0,0,0,0,0,0,0,0,0,1,0,0],[0,0,0,0,0,0,0,1,1,1,0,0,0],[0,0,0,0,0,0,0,1,1,0,0,0,0]]',
          output: '6',
        ),
        ProblemExample(input: 'grid = [[0,0,0,0,0,0,0,0]]', output: '0'),
      ],
    ),
    Problem(
      id: '45',
      title: 'Clone Graph',
      category: 'Graphs',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/clone-graph/',
      description:
          'Given a reference of a node in a connected undirected graph. Return a deep copy (clone) of the graph.',
      examples: [
        ProblemExample(
          input: 'adjList = [[2,4],[1,3],[2,4],[1,3]]',
          output: '[[2,4],[1,3],[2,4],[1,3]]',
        ),
      ],
    ),
    Problem(
      id: '46',
      title: 'Pacific Atlantic Water Flow',
      category: 'Graphs',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/pacific-atlantic-water-flow/',
      description:
          'There is an m x n rectangular island that borders both the Pacific Ocean and Atlantic Ocean. The Pacific Ocean touches the island\'s left and top edges, and the Atlantic Ocean touches the island\'s right and bottom edges.',
      examples: [
        ProblemExample(
          input:
              'heights = [[1,2,2,3,5],[3,2,3,4,4],[2,4,5,3,1],[6,7,1,4,5],[5,1,1,2,4]]',
          output: '[[0,4],[1,3],[1,4],[2,2],[3,0],[3,1],[4,0]]',
        ),
      ],
    ),
    Problem(
      id: '47',
      title: 'Surrounded Regions',
      category: 'Graphs',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/surrounded-regions/',
      description:
          'Given an m x n matrix board containing \'X\' and \'O\', capture all regions that are 4-directionally surrounded by \'X\'.',
      examples: [
        ProblemExample(
          input:
              'board = [["X","X","X","X"],["X","O","O","X"],["X","X","O","X"],["X","O","X","X"]]',
          output:
              '[["X","X","X","X"],["X","X","X","X"],["X","X","X","X"],["X","O","X","X"]]',
        ),
      ],
    ),
    Problem(
      id: '48',
      title: 'Course Schedule',
      category: 'Graphs',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/course-schedule/',
      description:
          'There are a total of numCourses courses you have to take, labeled from 0 to numCourses - 1. You are given an array prerequisites where prerequisites[i] = [ai, bi] indicates that you must take course bi first if you want to take course ai.',
      examples: [
        ProblemExample(
          input: 'numCourses = 2, prerequisites = [[1,0]]',
          output: 'true',
        ),
        ProblemExample(
          input: 'numCourses = 2, prerequisites = [[1,0],[0,1]]',
          output: 'false',
        ),
      ],
    ),
    Problem(
      id: '49',
      title: 'Course Schedule II',
      category: 'Graphs',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/course-schedule-ii/',
      description:
          'There are a total of numCourses courses you have to take, labeled from 0 to numCourses - 1. You are given an array prerequisites where prerequisites[i] = [ai, bi] indicates that you must take course bi first if you want to take course ai. Return the ordering of courses you should take to finish all courses.',
      examples: [
        ProblemExample(
          input: 'numCourses = 2, prerequisites = [[1,0]]',
          output: '[0,1]',
        ),
        ProblemExample(
          input: 'numCourses = 4, prerequisites = [[1,0],[2,0],[3,1],[3,2]]',
          output: '[0,2,1,3]',
        ),
      ],
    ),
  ];

  static const List<Problem> blind75 = [
    // Array
    Problem(
      id: 'b1',
      title: 'Two Sum',
      category: 'Array',
      difficulty: Difficulty.easy,
      url: 'https://leetcode.com/problems/two-sum/',
      description:
          'Given an array of integers nums and an integer target, return indices of the two numbers such that they add up to target.',
      examples: [
        ProblemExample(
          input: 'nums = [2,7,11,15], target = 9',
          output: '[0,1]',
        ),
      ],
    ),
    Problem(
      id: 'b2',
      title: 'Best Time to Buy and Sell Stock',
      category: 'Array',
      difficulty: Difficulty.easy,
      url: 'https://leetcode.com/problems/best-time-to-buy-and-sell-stock/',
      description:
          'You are given an array prices where prices[i] is the price of a given stock on the ith day. You want to maximize your profit by choosing a single day to buy one stock and choosing a different day in the future to sell that stock.',
      examples: [ProblemExample(input: 'prices = [7,1,5,3,6,4]', output: '5')],
    ),
    Problem(
      id: 'b3',
      title: 'Contains Duplicate',
      category: 'Array',
      difficulty: Difficulty.easy,
      url: 'https://leetcode.com/problems/contains-duplicate/',
      description:
          'Given an integer array nums, return true if any value appears at least twice in the array, and return false if every element is distinct.',
      examples: [ProblemExample(input: 'nums = [1,2,3,1]', output: 'true')],
    ),
    Problem(
      id: 'b4',
      title: 'Product of Array Except Self',
      category: 'Array',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/product-of-array-except-self/',
      description:
          'Given an integer array nums, return an array answer such that answer[i] is equal to the product of all the elements of nums except nums[i].',
      examples: [
        ProblemExample(input: 'nums = [1,2,3,4]', output: '[24,12,8,6]'),
      ],
    ),
    Problem(
      id: 'b5',
      title: 'Maximum Subarray',
      category: 'Array',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/maximum-subarray/',
      description:
          'Given an integer array nums, find the subarray with the largest sum, and return its sum.',
      examples: [
        ProblemExample(
          input: 'nums = [-2,1,-3,4,-1,2,1,-5,4]',
          output: '6',
          explanation: 'The subarray [4,-1,2,1] has the largest sum 6.',
        ),
        ProblemExample(input: 'nums = [1]', output: '1'),
        ProblemExample(input: 'nums = [5,4,-1,7,8]', output: '23'),
      ],
    ),
    Problem(
      id: 'b6',
      title: 'Maximum Product Subarray',
      category: 'Array',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/maximum-product-subarray/',
      description:
          'Given an integer array nums, find a subarray that has the largest product, and return the product.',
      examples: [
        ProblemExample(
          input: 'nums = [2,3,-2,4]',
          output: '6',
          explanation: '[2,3] has the largest product 6.',
        ),
        ProblemExample(
          input: 'nums = [-2,0,-1]',
          output: '0',
          explanation:
              'The result cannot be 2, because [-2,-1] is not a subarray.',
        ),
      ],
    ),
    Problem(
      id: 'b7',
      title: 'Find Minimum in Rotated Sorted Array',
      category: 'Array',
      difficulty: Difficulty.medium,
      url:
          'https://leetcode.com/problems/find-minimum-in-rotated-sorted-array/',
      description:
          'Given the sorted rotated array nums of unique elements, return the minimum element of this array.',
      examples: [ProblemExample(input: 'nums = [3,4,5,1,2]', output: '1')],
    ),
    Problem(
      id: 'b8',
      title: 'Search in Rotated Sorted Array',
      category: 'Array',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/search-in-rotated-sorted-array/',
      description:
          'Given the array nums after the possible rotation and an integer target, return the index of target if it is in nums, or -1 if it is not in nums.',
      examples: [
        ProblemExample(
          input: 'nums = [4,5,6,7,0,1,2], target = 0',
          output: '4',
        ),
      ],
    ),
    Problem(
      id: 'b9',
      title: '3Sum',
      category: 'Array',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/3sum/',
      description:
          'Given an integer array nums, return all the triplets [nums[i], nums[j], nums[k]] such that nums[i] + nums[j] + nums[k] == 0.',
      examples: [
        ProblemExample(
          input: 'nums = [-1,0,1,2,-1,-4]',
          output: '[[-1,-1,2],[-1,0,1]]',
        ),
      ],
    ),
    Problem(
      id: 'b10',
      title: 'Container With Most Water',
      category: 'Array',
      difficulty: Difficulty.medium,
      url: 'https://leetcode.com/problems/container-with-most-water/',
      description:
          'Find two lines that together with the x-axis form a container, such that the container contains the most water.',
      examples: [
        ProblemExample(input: 'height = [1,8,6,2,5,4,8,3,7]', output: '49'),
      ],
    ),
  ];
}
