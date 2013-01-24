Introduction
============

Pattern Case is a pattern matching and destructuring system designed
to mesh well with the philosophy of Scheme.  Pattern Case comprises
two main components: matcher procedures and the `case*` macro.  They
conspire to make examples like this (contrived one) work:

```scheme
  (case* foo
   ((pair a (pair ad dd)) (+ a ad dd))
   ((pair _ d) d)
   ((null) 3)
```

This evaluates `foo`; if it turns out to be a pair whose cdr is also a
pair, it will (try to) sum the car, cadr, and cddr of `foo`; otherwise
if it turns out to be pair, will return its cdr; otherwise if it turns
out to be null, will return 3; otherwise will return an unspecified
value.  The matcher procedures used in the above example are `pair`
and `null`, provided with Pattern Case.

The motivation and design are discussed in pattern-matching.txt, of
which discussion Pattern Case is an implementation (in MIT Scheme).
Pattern Case differs from what is described in that document as
follows:

- Interface: matchers pass the pieces of the object to the win
  continuation, and nothing to the lose continuation.  Since MIT
  Scheme does not do flow analysis, no measures to make it more
  effective are taken.

- Naming convention: matchers are named after the type name, with
  no typographic markers.  What is called `pair?*' in the text is
  called `pair' here.

- List matchers, segment variables, and guards are not implemented.

- As patterns are implemented, with the syntax `(pair a d :as foo)`.

- Be sure to `(declare (integrate-external "pattern-matching"))` in
  any file that uses this, or you will start consing closures like mad
  and probably suffer around 5x-10x slowdown in `case*` forms.

Syntax
======

Pattern Case revolves around the `case*` macro and its variant
`define-case*`, as well as provided [matcher
procedures](#matcher-procedures) and facilities for adding your own.

Case*
-----

The `case*` macro has the following syntax:

```
<case*>   = (case* <expr> <clause> ...)
<clause>  = (<pattern> <body-form> ...)
          | (<matcher> => <receiver>)
<pattern> = _
          | <var>
          | (<matcher> <pattern> ...)
          | (<matcher> <pattern> ... :as <var>)

<matcher>, <receiver>, <expr>, and <body-form> are Scheme
expressions.
```

The semantics of a `case*` form are as follows.  First, the `<expr>`
is evaluated (once) to produce an object to be matched against.  Then
each clause is tried in turn (described [below](#clause-matching))
until one matches; in which case the value of the `case*` form is the
value produced by that clause.  If none of the clauses match, the
value of the `case*` form is unspecified.

Clause Matching
---------------

There are two types of clauses: normal pattern clauses and "arrow
clauses", the latter being distinguished by the presence of the
token `=>` in the second position in the clause.  The arrow
clauses are simpler so I describe them first.

If the clause is an arrow clause, both expressions in the clause are
evaluated.  The first is expected to return a matcher procedure, as
[below](#matcher-procedures), and the second is expected to return a
procedure.  The matcher procedure is then called on the object being
matched against, the procedure returned by the receiver form, and a
nullary procedure that, if invoked, will continue matching later
clauses.  The effect is that if the object matches the matcher, the
`case*` form will reduce to a call to the receiver with the match data
as defined by the matcher; otherwise evaluation will continue.

If the clause is a pattern clause, the behavior depends on the
pattern.  If the pattern is a variable, it will automatically match,
and the body of the clause will be evaluated in an environment where
the object is bound to that variable.  The special variable `_` is
treated as an ignore directive, and the object is not bound in this
case.  If the pattern is a list, then the first element of the pattern
is evaluated to produce a matcher procedure, as per arrow clauses
above.  This matcher procedure is called on the object, a procedure
constructed from the rest of the pattern together with the clause
body, and a nullary procedure that will continue by trying the
remaining clauses.  If the remaining elements of the pattern are all
variables, then, if the object matches, the body will be evaluated in
an environment where the match data is bound to those variables
(underscores are again treated as ignore directives).  If any of the
elements of the pattern are nontrivial subpatterns, the corresponding
part of the object will be matched recursively.  If the whole pattern
matches, the body will be evaluated in an environment where all the
parts are bound to the given names; if not, the next clause will be
tried.

If the second-to-last element of a pattern is the token `:as`, this is
an "as-pattern".  The object being matched against this pattern will
be bound to the last element of the pattern (which must be a
variable), and the match will proceed using the pattern without the
`:as` token or that variable.  In other words, if the match succeeds,
the whole object will be available to the clause body in the variable
that followed the `:as` token.

TODO For example, foo expands into bar (mention procedure integration)

Define-case*
------------

The `define-case*` macro defines a unary procedure that operates by
`case*` on its one argument.  To wit,

```scheme
(define-case* <name>
  <clause> ...)
```
becomes
```scheme
(define (<name> thing)
  (case* thing
    <clause> ...))
```

Matcher Procedures
==================

The provided matcher procedures are:

- `pair` matches Scheme pairs and destructures them into their car and cdr
- `null` matches the empty list and destructures it into nothing
- `boolean` matches Scheme booleans and "destructures" them into themselves
- `number` matches Scheme numbers and "destructures" them into themselves

You are free and encouraged to write your own.  In fact, that was the
point.  A matcher procedure must accept three arguments: the object to
match, a procedure to call if it matches, and a procedure to call if
it does not.  The meaning of matching depends on the particular
matcher procedure; in the case of `pair` that would be being a pair,
and in the case of `null` that would be being the empty list.  If the
object indeed matches, the matcher procedure must call its second
argument with the results of destructuring, as separate arguments.
What destructuring a matcher performs is also defined by the
particular matcher procedure -- in the case of `pair`, that would be
the car and the cdr of the pair, and in the case of `null`, there are
no destructing results (so the second argument to `null` must accept no
arguments).  If the object does not match, the matcher procedure must
call its third argument with no arguments.

For example, `pair` could have been defined with
```scheme
(define-integrable (pair thing win lose)
  (if (pair? thing)
      (win (car thing) (cdr thing))
      (lose)))
```

Defining matcher procedures with `define-integrable` where possible is
recommended for performance (as is appropriate application of
`(declare (integrate-external ...))` in files that use your custom
matcher procedures).

The thing that makes Pattern Case Schemely is that the matcher
procedure slot in the `case*` macro is evaluated, so you can compute
matchers on the fly.  To repeat the example from the motivational
essay, you could make a matcher that matches hash tables by looking a
given key up in them (with the destructuring result being the datum
associated with that key):

```scheme
(define (has-key key)
  (lambda (table win lose)
    (hash-table/lookup table key win lose)))
```

Then you could use such matchers in any `case*` expressions you
wanted, choosing keys on the fly:
```scheme
(case* some-table
  (((has-key "foo") d) ...) ; The datum under "foo" is now in d
  (((has-key "bar") d) ...) ; There was no "foo"; the datum under "bar" is now in d
  ...) ; There was neither "foo" nor "bar"
```

`(define-algebraic-matcher name predicate accessor ...)` For the
fairly common case when your matcher procedure tests the object with
an existing predicate and destructures it by applying several existing
accessors.  This defines a matcher procedure named `name` that tests
with `predicate` and produces destructuring results by applying each
of the `accessor`s.  `pair` could have been defined with
`(define-algebraic-matcher pair pair? car cdr)`.  There can be zero
accessors; `null` could have been defined with
`(define-algebraic-matcher null null?)`.

`(id-project thing)` Returns `thing`.  Useful as the "accessor" for a
matcher (like `boolean`) that returns the object being matched itself,
without actually destructuring it.  `boolean` could have been defined
with `(define-algebraic-matcher boolean boolean? id-project)`.