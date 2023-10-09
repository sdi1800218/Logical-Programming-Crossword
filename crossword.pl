/* (Τα γράφω αγγλικά, με βολεύει πιότερο.)

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
*/

%:- compile("input/cross14").
:- compile("input/crosshard").

% Solution is gonna be a List of Slots filled in!
crossword(WordsLetters) :-

    % 1. MODELING/TEMPLATING:

    % a. get dimnsion from global state
    dimension(N),

    % b. Set N+1 as the limit for unification purposes
    AnotherN is N+1,

    % c. Get the box/3 triples and enumerate them
    get_boxes(AnotherN, Boxes),
    %enum_boxes(Boxes, EnumBoxes),

    % d. Get Slots and enumerate them
    get_slots(Boxes, AnotherN, Slots),
    %enum_slots(Slots, EnumSlots).

    % 2. Play with words
    words(Words),
    words_transform(Words, EnumWords),

    % 3. Length Frequency sorting to simplify backtracking
    length_freq_sort(EnumWords, OptWords),
    length_freq_sort(Slots, OptSlots),

    % 4. Solusolve
    solve(OptWords, OptSlots),
    words_transform(WordsLetters, Slots),

    % 5. Print
    print_result(AnotherN, Boxes), nl.

% Iterate per Row from 1 to N
% and check whether the head of Boxes is same as the index
% If it's not, print black, else print it and recurse on the rest.
print_result(N, Boxes) :- print_result_row(N, 1, Boxes), !.

print_result_row(N, N, _) :- !.
print_result_row(N, Row, Boxes) :-
    print_result_col(N, Row, 1, Boxes, Boxes1),
    Row1 is Row+1,
    print_result_row(N, Row1, Boxes1).

% eol
print_result_col(N, _, N, Boxes, Boxes) :- nl, !.

% eof
print_result_col(N, _, N, [], _) :- !.

% match
print_result_col(N, Row, Col, [box(Row, Col, Value)|Boxes], Boxes1) :-
    char_code(C, Value),
    write(" "), write(C), write(" "),
    Col1 is Col+1,
    print_result_col(N, Row, Col1, Boxes, Boxes1).

% black
print_result_col(N, Row, Col, [box(A, B, C)|Boxes], Boxes1) :-
    write("###"),
    Col1 is Col+1,
    print_result_col(N, Row, Col1, [box(A, B, C)|Boxes], Boxes1).

solve([], []).
solve([W|Words], Slots) :-
	select(W, Slots, SlotsR),
	solve(Words, SlotsR).

words_transform([], []).
words_transform([W|Words], [WT|Transformed]) :-
    words_transform(Words, Transformed),

    name(W, WT).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                               Slots                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Master Slots, calls horizontal and vertical workers.
get_slots(Boxes, N, Slots) :-

    % 1. Get me horizontal slots and format.
    make_slots_horizontal(Boxes, N, 1, SlotsH, []),
    reverse(SlotsH, SlotsHorthodox),

    % 2. Get me vertical ones.
    make_slots_vertical(Boxes, N, 1, SlotsV, []),
    reverse(SlotsV, SlotsVorthodox),

    append(SlotsHorthodox, SlotsVorthodox, Slots).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            Vertical                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% make_slots_vertical/6 :- (+, +, +, +, -, -)
% Check whether current column > N
make_slots_vertical(_, N, Col, Slots, Slots) :- Col > N, !.

% Call the bigger preds
make_slots_vertical(Boxes, N, Col, Slots, AccSlots) :-

    make_slots_vertical(Boxes, N, 1, Col, AccSlots1, AccSlots),
    Col1 is Col + 1,
	make_slots_vertical(Boxes, N, Col1, Slots, AccSlots1).

% Check whether current row > N
make_slots_vertical(_, N, Row, _, Slots, Slots) :- Row > N, !.

% Scraper, fails if the current one is black or there is only 1 box and then black.
make_slots_vertical(Boxes, N, Row, Col, Slots, AccSlots) :-

    % 1. Get me the first Slot you find
    get_slot_v(Boxes, Row, Col, Slot, Iter), !,

    % 2. Augment
    Row1 is Row + Iter,
    AccSlots1 = [Slot|AccSlots],

    % 3. Recoursa
    make_slots_vertical(Boxes, N, Row1, Col, Slots, AccSlots1).

% Skipper, goes over the blacks
make_slots_vertical(Boxes, N, Row, Col, Slots, AccSlots) :-
    Row1 is Row + 1,
    make_slots_vertical(Boxes, N, Row1, Col, Slots, AccSlots).

% Runs only the first time.
get_slot_v(Boxes, Row, Col, [A, B|Slot], Iter) :-

    % 1. Get a box with anon value A
    member( box(Row, Col, A), Boxes),

    % 2. Get next box with anon value Y
    Row1 is Row+1,
    member( box(Row1, Col, B), Boxes),

    % 3. Success, continue construction one by one.
    Row2 is Row1+1,
    scrap_slot_v(Boxes, Row2, Col, Slot, 3, Iter).

% Runs after construct is successful.
% Adds next element to current Slot.
scrap_slot_v(Boxes, Row, Col, [A|Slot], Acc, Iter) :-

    % 1. Fetch
    member( box(Row, Col, A), Boxes), !,

    % 2. Next
    Acc1 is Acc + 1,
    Row1 is Row + 1,

    % 3. Re-curse
    scrap_slot_v(Boxes, Row1, Col, Slot, Acc1, Iter).

% Unify, base
scrap_slot_v(_, _, _, [], Iter, Iter).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        Horizontal                                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% make_slots_horizontal/6 :- (+, +, +, +, -, -)
% Check whether current column > N
make_slots_horizontal(_, N, Row, Slots, Slots) :- Row > N, !.

% Call the bigger preds
make_slots_horizontal(Boxes, N, Row, Slots, AccSlots) :-

    make_slots_horizontal(Boxes, N, Row, 1, AccSlots1, AccSlots),
    Row1 is Row + 1,
	make_slots_horizontal(Boxes, N, Row1, Slots, AccSlots1).

% Check whether current row > N
make_slots_horizontal(_, N, _, Col, Slots, Slots) :- Col > N, !.

% Scraper, fails if the current one is black or there is only 1 box and then black.
make_slots_horizontal(Boxes, N, Row, Col, Slots, AccSlots) :-

    % 1. Get me the first Slot you find
    get_slot_h(Boxes, Row, Col, Slot, Iter), !,

    % 2. Augment
    Col1 is Col + Iter,
    AccSlots1 = [Slot|AccSlots],

    % 3. Recoursa
    make_slots_horizontal(Boxes, N, Row, Col1, Slots, AccSlots1).

% Skipper, goes over the blacks
make_slots_horizontal(Boxes, N, Row, Col, Slots, AccSlots) :-
    Col1 is Col + 1,
    make_slots_horizontal(Boxes, N, Row, Col1, Slots, AccSlots).

% Runs only the first time.
get_slot_h(Boxes, Row, Col, [A, B|Slot], Iter) :-

    % 1. Get a box with anon value A
    member( box(Row, Col, A), Boxes),

    % 2. Get next box with anon value Y
    Col1 is Col + 1,
    member( box(Row, Col1, B), Boxes),

    % 3. Success, continue construction one by one.
    Col2 is Col1 + 1,
    scrap_slot_h(Boxes, Row, Col2, Slot, 3, Iter).

% Runs after construct is successful.
% Adds next element to current Slot.
scrap_slot_h(Boxes, Row, Col, [A|Slot], Acc, Iter) :-

    % 1. Fetch
    member( box(Row, Col, A), Boxes), !,

    % 2. Next
    Acc1 is Acc + 1,
    Col1 is Col + 1,

    % 3. Re-curse
    scrap_slot_h(Boxes, Row, Col1, Slot, Acc1, Iter).

% Unify, base
scrap_slot_h(_, _, _, [], Iter, Iter).


% TODO:
/*
get_horizontal_slots(Boxes, N, Slots) :- get_horizontal_slots(Boxes, N, 1, Slots), !.

get_horizontal_slots(_, N, N, []). % Base
get_horizontal_slots(Boxes, N, Row, Slots) :-

    % 1. Recursive Step
    Row1 is Row + 1,
    get_horizontal_slots(Boxes, N, Row1, Slots1),

    % 2. Get the blacks of this Row
    findall(Column, black(Row, Column), Blacks),

    % 3. Magic
    scrap_row(Boxes, N, Row, Blacks, RowSlots, [], 0),

    % 4. Concat
    reverse(RowSlots, RowSlots1),
    append(RowSlots1, Slots1, Slots).

% Special Cay
scrap_row(Boxes, N, Row, [], Slots, SlotsAcc, PrevBlack) :-

    get_hslot(Boxes, Row, N, PrevBlack, Slot),

    length(Slot, LSL),
    (LSL < 2 ->
        Slots = SlotsAcc
    ;
        Slots = [Slot|SlotsAcc]
    ).

% Main case
scrap_row(Boxes, N, Row, [Black|Blacks], Slots, SlotsAcc, PrevBlack) :-

    % 1. Get the slot from PrevBlack till Current Black
    get_hslot(Boxes, Row, Black, PrevBlack, Slot),

    PrevBlack1 is Black,

    length(Slot, LSL),
    (LSL < 2 ->
        scrap_row(Boxes, N, Row, Blacks, Slots, SlotsAcc, PrevBlack1)
    ;
        scrap_row(Boxes, N, Row, Blacks, Slots, [Slot|SlotsAcc], PrevBlack1)
    ).

% get_hslot/ :-
get_hslot(Boxes, Row, Col, PrevBlack, Slot) :-

    % Make a slot with the boxes from PrevBlack to Current Column
    Prev is PrevBlack + 1,
    Col1 is Col - 1,
    construct_hslot(Boxes, Row, Prev, Col1, Slot).

% Construct me coordinate pairs from PrevBlack+1 to Col
construct_hslot(Boxes, Row, PrevBlack, Col, Slot) :-
    %Prev is PrevBlack+1,

    findall(X,
        (between(PrevBlack, Col, Index),
        member(box(Row, Index, X), Boxes)
        ),
    Slot).
*/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                               Boxes                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get_boxes/2 :- Produce Boxes given the N by N dimension/limit.
get_boxes(N, Boxes) :- get_boxes_by_row(N, 1, Boxes), !.

% get_boxes_by_row/3 :- First iterate over all the rows
get_boxes_by_row(N, N, []).
get_boxes_by_row(N, Row, Boxes) :-

    % 1. Recursive step
    Row1 is Row + 1,
    get_boxes_by_row(N, Row1, Boxes1),

    % 2. Work and back.
    get_boxes_by_col(N, Row, 1, BoxesRow),
    append(BoxesRow, Boxes1, Boxes).

% get_boxes_by_col/3 :- Given the Row number iterate all the Columns
get_boxes_by_col(N, _, N, []).
get_boxes_by_col(N, Row, Col, Boxes) :-

    % 1. Recurse deeper to instantiate
    Col1 is Col+1,
    get_boxes_by_col(N, Row, Col1, Boxes1),

    % 2. If the square is blackened -> null, else append current.
    (black(Row, Col) ->
        Square = []
    ;
        Square = [box(Row, Col, _)]
    ),
    append(Square, Boxes1, Boxes).

% enum_boxes/2 :- Enumerate boxes
enum_boxes(Boxes, EnumBoxes) :-

    % 1. Get length and create a list 1..NB
    length(Boxes, NB),

    % in builtins we trust
    findall(Index, between(1, NB, Index), Indexes),

    % 2. Magic
    zip_index(Indexes, Boxes, EnumBoxes).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                           Length Frequency Sort                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The final predicate that combines all the steps
length_freq_sort(Lists, SortedLists) :-

    % 1. Find the length of each list in the input
    lengths(Lists, Lengths),

    % 2. Create a list of pairs with the frequency
    %       of each length and the corresponding list
    freq(Lists, Lengths, Pairs),

    % 3. Sort the list of pairs in, freq -> desc,
    sort_pairs(Pairs, SortedPairs),

    % 4. Extrac the values
    my_pairs_values(SortedPairs, SortedLists).

% Extract the values from a list of key-value pairs
my_pairs_values([], []).
my_pairs_values([_-Value|Pairs], [Value|Values]) :-
    my_pairs_values(Pairs, Values).

% Get lengths of all lists
lengths([], []).
lengths([H|T], [L|Ls]) :-
    length(H, L),
    lengths(T, Ls).

% Count the frequency of each length in the input list
count_freq(_, [], 0).
count_freq(X, [X|T], N) :-
    count_freq(X, T, N1),
    N is N1 + 1.
count_freq(X, [Y|T], N) :-
    different(X, Y),
    count_freq(X, T, N).

% Ensure X and Y are different integers
different(X, Y) :-
    X \= Y.

% Create a list of pairs with the frequency of each length and the corresponding list
freq([], _, []).
freq([H|T], Lengths, [Freq-H|Pairs]) :-
    length(H, L),
    count_freq(L, Lengths, Freq),
    freq(T, Lengths, Pairs).

% soert
sort_pairs(Pairs, SortedPairs) :-
    keysort(Pairs, SortedPairs).
    %reverse(KeySorted, SortedPairs).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                               Helpers                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check if next is true aka it exists aka is not black/2
valid(Row, Col) :-
    \+ black(Row, Col).

% Helper zip()per, more like a map()per, but w/e.
zip_index([], [], []).
zip_index([X|Xs], [Y|Ys], [(X, Y)|Zs]) :- zip_index(Xs, Ys, Zs).

% Scraped from the book.
between(I, J, I) :-
    I =< J.
between(I, J, X) :-
    I < J,
    I1 is I+1,
    between(I1, J, X).
