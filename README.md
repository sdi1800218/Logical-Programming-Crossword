# Crossword Puzzle Solver

- Hereby lies the implementation for the Crossword puzzle solver in `Prolog`.

```
    ABSTRACT
-------------------------------------------------------------------------------
To solve the below problem I went through most of the bibliography I could find
(and understand) that deals with crossword puzzle generation by modeling the
problem, after linear equations and reduces it to a constraint satisfaction
problem.
Dr. Berghel was the first one to take such an approach, as can be
outlined in Ref. 1 && 2, but the problem he was trying to solve was not crossword
solving, but crossword generation with Horn Clauses aka Logical Programming
aka Prolog. He outlines the data modeling of the problem and provides the notion
of Slots and and Words that fill them in such a way that they satisfy certain
constraints.

Graham and Vogel (Ref 3) build upon the above model to optimize the solution of
crosswords, by applying certain constraints that Berghel omits and additionally
optimizing the data.

Below are the 5 constraints they put they provide:
1. Control the order in which the word slots are assigned words,
2. Do not assign a word to a word slot that is already assigned to a
    diﬀerent word slot,
3. Do not assign a word to a word slot that is going to result in an im-
    posssible combination of characters in interlinking word slots,
4. When searching for a word to assign to a given word slot evaluate the
    prospective words using a heuristic value,
5. Only redo the insertion of a given word slot if redoing that word slot
    aﬀects the word slot that is causing the programm to backtrack.

This is the solution method I wanted to follow. The lack of paradigms in the
paper though and my intermediate Prolog skills proved this task to be quite
daunting. I chose to go with another path that kind of follows the ideas
in (3). I length frequency sort the words a slots so as to make sure that
the biggest words that are loners and probably have many intersection points
get filled up first. This way a lot of backtracking overweight gets skipped,
by making something of a template by placing the first words.
For example, if we have a single 14 letter word and a single 14 letter Slot,
they get matched up and a lot of trial and error is skipped. In this fashion
we make something of a template by solving the easy pickings first.
Additionally the length frequency sort trick, partially satisfies some of the
above 5 constraints and proves to be quite efficient.

    REFERENCES
-------------------------------------------------------------------------------
1. Berghel, H. (1987). Crossword Compilation with Horn Clauses. The Com-
puter Journal, 30 (2), 183–88.

2. Berghel, H. & Yi, C. (1989). Crossword Compilation with Horn Clauses. The
Computer Journal, 32 (3), 276–280.

3. Yvette Graham and Carl Vogel. Computer Construction of Crossword Puzzles
using Horn Clauses and Constraint Programming.
In Proceedings of the Fourth Workshop on Constraint Handling Rules (CHR 2005),
pages 49-63, October 2005.
```