Introduction
============

Pattern Case is a pattern matching and destructuring system designed
to mesh well with the philosophy of Scheme.  Pattern Case comprises
two main components: [matcher procedures](#matcher-procedures)
and the [`case*` macro](#case).  They
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
  Scheme does not do flow analysis, and certainly doesn't propagate
  negative information, I did not take that measure to improve its
  precision.

- Naming convention: matchers are named after the type name, with no
  typographic markers.  What is called `pair?*` in the text for
  distinctiveness is called `pair` here for typography.

- List matchers, segment variables, and guards are not implemented.

- As patterns are implemented, with the syntax `(pair a d :as foo)`.

- Compiler support is obtained though integration declarations.

Worked Example
==============

For example, one might use `case*` to define a simple `map` function
like this:

```scheme
; Inline matcher procedures for performance
(declare (integrate-external "path/to/pattern-case"))

(define (my-map f lst)
  (case* lst
    ((pair a d) (cons (f a) (my-map f d)))
    ((null) '())
    (_ (error "Improper list"))))
```

The [`case*` macro](#case) in this example macroexpands into a composition of the
[matcher procedures](#matcher-procedures) `pair` and `null`:
```scheme
(define (my-map f lst)
  (let ((expr-17 lst))
    (let ((lose-18
           (lambda ()
             (let ((lose-19 (lambda () (error "Improper list"))))
               ;; (2) Then to try the second clause, bind the
               ;; remaining clauses into yet another lose procedure.
               (null expr-17 (lambda () '()) lose-19)))))
      ;; (1) To try the first clause first, bind up the process of
      ;; trying the other clauses into a lose procedure.
      (pair expr-17 (lambda (a d) (cons (f a) (my-map f d))) lose-18))))
```
Each matcher takes the object to match and destructure, a procedure to
call with the results of destructuring if the match is successful, and
a procedure to call with no arguments if the match fails.

Since `pair` and `null` are declared integrable, and since there is an
appropriate `integrate-external` declaration in effect, MIT Scheme
inlines `pair` and `null`, and all the anonymous lambdas, to produce
this:
```scheme
(define (my-map f lst)
  (let ((expr-17 lst))
    (cond ((pair? expr-17)
           (let ((a (car expr-17)) (d (cdr expr-17)))
             (cons (f a) (my-map f d))))
          ((null? expr-17) '())
          (else (error "Improper list")))))
```
which, up to some extra temporary names (which are the register
allocator's problem anyway) is what you would have written without
`case*`.

In this case, the gain is fairly small: the only thing `case*` gives
you here is not having to write `car` and `cdr` in the `pair?` clause.
But as your data structures get more complicated than just cons
lists, that savings starts to add up.

Installation
============

Just `git clone` this repository,
```scheme
(load "pattern-case/load")
```
and hack away.  Be sure to
```scheme
(declare (integrate-external "path/to/pattern-case"))
```
in any file that uses this, or you will be consing closures like mad
and probably suffer around 5x-10x slowdown in `case*` forms.

If you want to develop Pattern Case, you will want to also get the
unit test framework that Pattern Case uses.  Type `git submodule
init` and `git submodule update`.

Case*
=====

The `case*` macro has the following syntax:

```
<case*>   = (case* <expr> <clause> ...)
<clause>  = (<pattern> <body-form> ...)
          | (<matcher> => <receiver>)
<pattern> = _
          | <var>
          | (<matcher> <pattern> ...)
          | (<matcher> <pattern> ... :as <var>)

<matcher>, <receiver>, <expr>, and <body-form> are Scheme expressions.
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
evaluated.  The first is expected to return a
[matcher procedure](#matcher-procedures), and the second is expected to return a
procedure.  The matcher procedure is then called on the object being
matched against, the procedure returned by the receiver form, and a
nullary procedure that, if invoked, will continue matching later
clauses.  The effect is that if the object matches the matcher, the
`case*` form will reduce to a call to the receiver with the destructuring results
as defined by the matcher; otherwise `case*` will try the next clause.

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
an environment where the destructuring results are bound to those variables
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

Matcher Procedures
==================

The provided matcher procedures are:

- `pair` matches Scheme pairs and destructures them into their car and cdr
- `null` matches the empty list and destructures it into nothing
- `boolean` matches Scheme booleans and "destructures" them into themselves
- `number` matches Scheme numbers and "destructures" them into themselves

You are free and encouraged to write your own.  In fact, that was the
point.

Defining your own matcher procedures
------------------------------------

A matcher procedure must accept three arguments: the object to
match, a procedure to call if it matches, and a procedure to call if
it does not.  The meaning of matching depends on the particular
matcher procedure; in the case of `pair` that would be being a pair,
and in the case of `null` that would be being the empty list.  If the
object indeed matches, the matcher procedure must call its second
argument with the results of destructuring, as separate arguments.
What destructuring a matcher performs is also defined by the
particular matcher procedure -- in the case of `pair`, that would be
the car and the cdr of the pair, and in the case of `null`, there are
no destructuring results (so the second argument to `null` must accept no
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

Help for defining your own matcher procedures
---------------------------------------------

- `(define-algebraic-matcher name predicate accessor ...)` For the
  fairly common case when your matcher procedure tests the object with
  an existing predicate and destructures it by applying several
  existing accessors.  This defines a matcher procedure named `name`
  that tests with `predicate` and produces destructuring results by
  applying each of the `accessor`s.  `pair` could have been defined
  with `(define-algebraic-matcher pair pair? car cdr)`.  There can be
  zero accessors; `null` could have been defined with
  `(define-algebraic-matcher null null?)`.

- `(id-project thing)` Returns `thing`.  Useful as the "accessor" for
  a matcher (like `boolean`) that returns the object being matched
  itself, without actually destructuring it.  `boolean` could have
  been defined with `(define-algebraic-matcher boolean boolean?
  id-project)`.

Variants
========

Lambda-case*
------------

The `lambda-case*` macro returns an anonymous unary procedure that
operates by `case*` on its one argument.  To wit,

```scheme
(lambda-case* <clause> ...)
```
becomes
```scheme
(lambda (thing)
  (case* thing
    <clause ...))
```

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
which is functionally the same as
```scheme
(define <name> (lambda-case* <clause> ...))
```

Developer Documentation
=======================

The developer documentation is the source code and the commentary
therein.  There's only one interesting code file, but you might want
to read the philosophy of the system as well.

- Interesting stuff

  - `pattern-matching.txt`: An essay on pattern matching in Scheme, of
    which this code is an implementation.
  - `pattern-case.scm`: The implementation.

- Boring support

  - `auto-compilation.scm`: Automatically invoke the MIT Scheme
    compiler, if necessary and possible, to (re)compile files before
    loading them.  This has nothing to do with Pattern Case, but I
    figured copying it in was easier than making an external
    dependency.
  - `load.scm`: Orchestrate the loading sequence.  Nothing interesting
    to see here.
  - `Makefile`: Run the test suite.  Note that there is no "build" as
    such; source is automatically recompiled at loading time as
    needed.
  - `LICENSE`: The AGPLv3, under which Pattern Case is licensed.

- Test suite

  - Run it with `make test`.
  - The `test/` directory contains the actual test suite.
  - `test/*-examples.scm` are example uses of `case*` that are
    automatically checked for compiling to the right result.
  - `test/*-results.scm` are expected results for compiling `case*`
    examples.
  - The `testing/` directory is a git submodule pointed at the [Test
    Manager](http://github.com/axch/test-manager/) framework that the
    test suite relies upon.

Portability
-----------

The idea of organizing pattern matching in Scheme like this should be
applicable to any Scheme system, with the caveat that some optimizer
support is necessary to get decent performance.  You really don't want
to make closures for the win and lose procedures that get passed to
the matcher procedures when you don't have to.

This actual implementation is just one giant explicit-renaming macro,
so it will only port to Schemes that support explicit-renaming macros;
which may not even be the right macro system to use in the target
Scheme for this job.  `Case*` is actually a hygienic macro, so it does
not necessarily require an escape into non-hygiene, but I didn't want
to even think about writing it in `syntax-rules`.

Unimplemented Features
======================

- Fixed length list patterns: `(case* ... ((list x y) ...))` could
  mean `(case* ... ((pair x (pair y (null))) ...))`.
- Pattern guards: application of arbitrary predicates which backtracks
  into the matching process if they do not pass.
- Integration with `define-structure`: Right now, to get pattern case
  to work on user structure types, the user has to incant
  `(define-algebraic-matcher foo foo? foo-x foo-y ...)`.  It would be
  nice if this could be made automatic; there may also be performance
  improvements available, because the inside of the destructurer could
  use unsafe accessors (because it already performed the type test).

Author
======

Alexey Radul, <axch@mit.edu>

License
=======

This file is part of Pattern Case, a Schemely pattern matching case
facility in MIT Scheme.
Copyright 2013 Alexey Radul.

Pattern Case is free software; you can redistribute it and/or
modify it under the terms of the GNU Affero General Public License
as published by the Free Software Foundation; either version 3 of
the License, or (at your option) any later version.

Pattern Case is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU Affero General Public
License along with Pattern Case; if not, see
<http://www.gnu.org/licenses/>.
