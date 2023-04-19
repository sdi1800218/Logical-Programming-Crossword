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

:- compile(input/cross01).

% We are given as facts:
%   1. dimension(N).
%   2. black(X, Y) multiple pairs,
%                   X == Row, Y == Column
%   3. words(List).

/*
- (each word slot is uniquely identiﬁed, but mutual constraints among words are maintained with variable sharing
*/
crosssword(Solution) :-

    % 1. Make template NxN matrix with black contrictions


    % 2. Get available horizontal targets of the form ((), Length)

    % 3. Solve

    % 4. Print

% TODO
make_tmpl().

% TODO: select_nth()
% Scraped from the book.
between(I, J, I) :-
    I =< J.
between(I, J, X) :-
    I < J,
    I1 is I+1,
    between(I1, J, X).
