# GeneBracket
Bracket variant, solely used for genetic programming.
This is a simplificaton of the language, which might make genetic programming
more simple.


### Symbols
Computer developed algorithms might not need symbols. Thus, GeneBracket does
not have symbols. Instead in a binding values are bound to a number.

### Fewer builtins
- GeneBracket removes non-necessary operators (e.g., `print`, `type`). 
- It removes the `esc` and backtick operator which were needed only for symobls.
- Side-effects in the can be performed with the `se` operator. This will run an 
  external function that may perform some side-effects in the environemnt
  in which the genetic programming is used.

### Types
- It is planned to reduce integers to 8-Bit, which might suffice for the intended
purposes


### Garbage collection
- As the whole point of GeneBracket is too run many short programs in parallel, 
there is no need for garbace collection. Instead a program terminates when the
stack space (the local heap) has be used.
- Global heap
Programms are safed on the global heap (they are immutable anyway)
