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
crossword(EnumBoxes, Slots) :- % Solution is gonna be a List of Slots filled in!

    % 1. MODELING/TEMPLATING:
    %   v Make Boxes
    %   - Make Slots
    %   ? Play with words ?

    % a. get dimnsion from global state
    dimension(N),

    % b. Set N+1 as the limit for unification purposes
    AnotherN is N+1,

    % c. Get the box/3 triples and enumerate them
    get_boxes(AnotherN, Boxes),
    enum_boxes(Boxes, EnumBoxes),

    % d. Get Slots and enumerate them
    get_slots(AnotherN, Slots).
    %enum_slots(Slots, EnumSlots).

    % 3. Solve

    % 4. Print

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                               Slots                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Master Slots, calls horizontal and vertical workers.
get_slots(N, Slots) :-

    get_horizontal_slots(N, SlotsH),
    get_vertical_slots(N, SlotsV),
    append(SlotsH, SlotsV, Slots).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            Vertical                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TODO:
get_vertical_slots(N, Slots) :- get_vertical_slots(N, 1, Slots), !.

get_vertical_slots(N, N, []). % Base
get_vertical_slots(N, Col, Slots) :-

    % 1. Recursive Step
    Col1 is Col + 1,
    get_vertical_slots(N, Col1, Slots1),

    % 2. Get the blacks of this Row
    findall(Row, black(Row, Col), Blacks),

    % 3. Magic
    scrap_column(N, Col, Blacks, ColSlots, [], 0),

    % 4. Concat
    reverse(ColSlots, ColSlots1),
    append(ColSlots1, Slots1, Slots).

% Special Cay
scrap_column(N, Col, [], Slots, SlotsAcc, PrevBlack) :-

    get_vslot(Col, N, PrevBlack, Slot),

    length(Slot, LSL),
    (LSL < 2 ->
        Slots = SlotsAcc
    ;
        Slots = [Slot|SlotsAcc]
    ).

% Main case
scrap_column(N, Col, [Black|Blacks], Slots, SlotsAcc, PrevBlack) :-

    % 1. Get the slot from PrevBlack till Current Black
    get_vslot(Col, Black, PrevBlack, Slot),

    PrevBlack1 is Black,

    length(Slot, LSL),
    (LSL < 2 ->
        scrap_column(N, Col, Blacks, Slots, SlotsAcc, PrevBlack1)
    ;
        scrap_column(N, Col, Blacks, Slots, [Slot|SlotsAcc], PrevBlack1)
    ).

% get_vslot/ :-
get_vslot(Col, Row, PrevBlack, Slot) :-

    % Make a slot with the boxes from PrevBlack to Current Row
    Prev is PrevBlack + 1,
    Row1 is Row - 1,
    construct_vslot(Col, Prev, Row1, Slot).

% Construct me coordinate pairs from PrevBlack+1 to Col
construct_vslot(Col, PrevBlack, Row, Slot) :-
    %Prev is PrevBlack+1,

    findall((Index, Col), between(PrevBlack, Row, Index), Slot).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        Horizontal                                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TODO:
get_horizontal_slots(N, Slots) :- get_horizontal_slots(N, 1, Slots), !.

get_horizontal_slots(N, N, []). % Base
get_horizontal_slots(N, Row, Slots) :-

    % 1. Recursive Step
    Row1 is Row + 1,
    get_horizontal_slots(N, Row1, Slots1),

    % 2. Get the blacks of this Row
    findall(Column, black(Row, Column), Blacks),

    % 3. Magic
    scrap_row(N, Row, Blacks, RowSlots, [], 0),

    % 4. Concat
    reverse(RowSlots, RowSlots1),
    append(RowSlots1, Slots1, Slots).

% Special Cay
scrap_row(N, Row, [], Slots, SlotsAcc, PrevBlack) :-

    get_hslot(Row, N, PrevBlack, Slot),

    length(Slot, LSL),
    (LSL < 2 ->
        Slots = SlotsAcc
    ;
        Slots = [Slot|SlotsAcc]
    ).

% Main case
scrap_row(N, Row, [Black|Blacks], Slots, SlotsAcc, PrevBlack) :-

    % 1. Get the slot from PrevBlack till Current Black
    get_hslot(Row, Black, PrevBlack, Slot),

    PrevBlack1 is Black,

    length(Slot, LSL),
    (LSL < 2 ->
        scrap_row(N, Row, Blacks, Slots, SlotsAcc, PrevBlack1)
    ;
        scrap_row(N, Row, Blacks, Slots, [Slot|SlotsAcc], PrevBlack1)
    ).

% get_hslot/ :-
get_hslot(Row, Col, PrevBlack, Slot) :-

    % Make a slot with the boxes from PrevBlack to Current Column
    Prev is PrevBlack + 1,
    Col1 is Col - 1,
    construct_hslot(Row, Prev, Col1, Slot).

% Construct me coordinate pairs from PrevBlack+1 to Col
construct_hslot(Row, PrevBlack, Col, Slot) :-
    %Prev is PrevBlack+1,

    findall((Row, Index), between(PrevBlack, Col, Index), Slot).

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
