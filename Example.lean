-- Example.lean: A simple Lean4 file for testing various integrations

import Lean

-- A simple anagram checker
-- Given two strings, determine if they are anagrams of each other
-- Anagrams are strings that have the same characters with the same frequency
-- Example: "listen" and "silent" are anagrams

def isAnagram (s1 s2 : String) : Bool :=
  let chars1 := s1.toList.qsort (· < ·)
  let chars2 := s2.toList.qsort (· < ·)
  chars1 == chars2

-- Examples
def testCases : List (String × String × Bool) := [
  ("listen", "silent", true),
  ("hello", "world", false),
  ("rail safety", "fairy tales", true),
  ("hi there", "bye there", false)
]

def runTests : IO Unit := do
  for (s1, s2, expected) in testCases do
    let result := isAnagram s1 s2
    if result == expected then
      IO.println s!"Test passed: isAnagram {s1} {s2} = {result}"
    else
      IO.println s!"Test failed: isAnagram {s1} {s2} = {result}, expected {expected}"

-- Entry point
def main : IO Unit := do
  IO.println "Running anagram tests..."
  runTests
  IO.println "Done!"

-- COMMENT THE FOLLOWING LINE TO REMOVE THE ERROR
-- This will intentionally cause an error for testing diagnostics
#check noSuchFunction

#eval isAnagram "listen" "silent" -- Should return true
#eval isAnagram "hello" "world"   -- Should return false