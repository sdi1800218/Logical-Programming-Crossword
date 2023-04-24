% Abstract
/*
We will attempt to model the solution of the problem, based on the reasearch
found in the below two papers that build one on top of the other.
    1.
    2.
*/

% TODO:
%   - lsort()
%   - lfsort() -> lfsort
%   - make_tmpl()

:- compile(input/cross01).

/*
- (each word slot is uniquely identiﬁed, but mutual constraints among words are maintained with variable sharing
*/
crossword(Boxes, Slots, WordsLetters) :- % Solution is gonna be a List of Slots filled in!

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
    words_transform(Words, EnumWords).

    % 3. Solusolve
    %solve(EnumWords, Slots),
    %words_transform(WordsLetters, Slots).

    % 4. Print

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

    %get_horizontal_slots(Boxes, N, SlotsH),
    %get_vertical_slots(Boxes, N, SlotsV),
    make_slots_vertical(Boxes, N, N, 1, Slots, []).

    %append(SlotsH, SlotsV, Slots).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            Vertical                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% construct_sites_vertical/6 :- (+, +, +, +, -, -)
% Check whether current column > N
make_slots_vertical(_, _, MaxCol, Col, Slots, Slots) :- Col > MaxCol, !.

% Call the bigger preds 
make_slots_vertical(Boxes, MaxRow, MaxCol, Col, Slots, AccSlots) :-

    make_slots_vertical(Boxes, MaxRow, MaxCol, 1, Col, AccSlots1, AccSlots),
    Col1 is Col + 1,
	make_slots_vertical(Boxes, MaxRow, MaxCol, Col1, Slots, AccSlots1).

% construct_sites_vertical/7 :- ()
% Check whether current row > N
make_slots_vertical(_, MaxRow, _, Row, _, Slots, Slots) :- Row > MaxRow, !.

% Scraper, fails if the current one is black or there is only 1 box and then black.
make_slots_vertical(Boxes, MaxRow, MaxCol, Row, Col, Slots, AccSlots) :-
    
    % 1. Get me the first Slot you find
    get_slot_v(Boxes, Row, Col, Slot, Incr), !,

    % 2. Augment
    Row1 is Row + Incr,
    AccSlots1 = [Slot|AccSlots],

    % 3. Recoursa
    make_slots_vertical(Boxes, MaxRow, MaxCol, Row1, Col, Slots, AccSlots1).

% Skipper, goes over the blacks
make_slots_vertical(Boxes, MaxRow, MaxCol, Row, Col, Slots, AccSlots) :-
    Row1 is Row + 1,
    make_slots_vertical(Boxes, MaxRow, MaxCol, Row1, Col, Slots, AccSlots).

% Runs only the first time.
get_slot_v(Boxes, Row, Col, [X,Y|Cs], Incr) :-
   
    % 1. Get a box with anon value X
    member( box(Row, Col, X), Boxes),

    % 2. Get next box with anon value Y
    Row1 is Row+1,
    member( box(Row1, Col, Y), Boxes),

    % 3. Success, continue construction one by one.
    Row2 is Row1+1,
    continue_slot_v(Boxes, Row2, Col, Cs, 3, Incr).

% Runs after construct is successful.
% Adds next element to current Slot.
continue_slot_v(Boxes, Row, Col, [X|Cs], Acc, Incr) :-

    member( box(Row, Col, X), Boxes), !,
    Acc1 is Acc + 1,
    Row1 is Row + 1,
    continue_slot_v(Boxes, Row1, Col, Cs, Acc1, Incr).

% Unify, base
continue_slot_v(_, _, _, [], Incr, Incr).

/*
% TODO:
get_vertical_slots(Boxes, N, Slots) :- get_vertical_slots(Boxes, N, 1, Slots), !.

get_vertical_slots(_, N, N, []). % Base
get_vertical_slots(Boxes, N, Col, Slots) :-

    % 1. Recursive Step
    Col1 is Col + 1,
    get_vertical_slots(Boxes, N, Col1, Slots1),

    % 2. Get the blacks of this Row
    findall(Row, black(Row, Col), Blacks),

    % 3. Magic
    scrap_column(Boxes, N, Col, Blacks, ColSlots, [], 0),

    % 4. Concat
    reverse(ColSlots, ColSlots1),
    append(ColSlots1, Slots1, Slots).

% Special Cay
scrap_column(Boxes, N, Col, [], Slots, SlotsAcc, PrevBlack) :-

    get_vslot(Boxes, Col, N, PrevBlack, Slot),

    length(Slot, LSL),
    (LSL < 2 ->
        Slots = SlotsAcc
    ;
        Slots = [Slot|SlotsAcc]
    ).

% Main case
scrap_column(Boxes, N, Col, [Black|Blacks], Slots, SlotsAcc, PrevBlack) :-

    % 1. Get the slot from PrevBlack till Current Black
    get_vslot(Boxes, Col, Black, PrevBlack, Slot),

    PrevBlack1 is Black,

    length(Slot, LSL),
    (LSL < 2 ->
        scrap_column(Boxes, N, Col, Blacks, Slots, SlotsAcc, PrevBlack1)
    ;
        scrap_column(Boxes, N, Col, Blacks, Slots, [Slot|SlotsAcc], PrevBlack1)
    ).

% get_vslot/ :-
get_vslot(Boxes, Col, Row, PrevBlack, Slot) :-

    % Make a slot with the boxes from PrevBlack to Current Row
    Prev is PrevBlack + 1,
    Row1 is Row - 1,
    construct_vslot(Boxes, Row, Col, Slot, Incr), !.

% Construct me coordinate pairs from PrevBlack+1 to Col

construct_vslot(Boxes, Col, PrevBlack, Row, Slot) :-
    %Prev is PrevBlack+1,

    findall(_X,
        (between(PrevBlack, Row, Index),
        get_current(Boxes, Index, Col, X)
        ),
    Slot).

get_current(Boxes, X, Y, Z) :-
    ord_memberchk(box(X, Y, Z), Boxes).


*/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        Horizontal                                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TODO:
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
