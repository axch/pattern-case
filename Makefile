### This file is part of Pattern Case, a Schemely pattern matching
### case facility in MIT Scheme.
### Copyright 2011 Alexey Radul.
###
### Pattern Case is free software; you can redistribute it and/or
### modify it under the terms of the GNU Affero General Public License
### as published by the Free Software Foundation; either version 3 of
### the License, or (at your option) any later version.
### 
### Pattern Case is distributed in the hope that it will be useful,
### but WITHOUT ANY WARRANTY; without even the implied warranty of
### MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
### GNU General Public License for more details.
### 
### You should have received a copy of the GNU Affero General Public
### License along with Pattern Case; if not, see
### <http://www.gnu.org/licenses/>.

test:
	mit-scheme --compiler -heap 6000 --batch-mode --no-init-file --eval '(set! load/suppress-loading-message? #t)' --eval '(begin (load "load") (load "test/load") (run-tests-and-exit))'

.PHONY: test
