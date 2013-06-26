Black Coffee is a large integer and cryptography package written to support host-proof web
applications.  It uses both Barrett and Montgomery reduction, as well as specialized 


Prior Art:

Peter Olson's BigInteger.js

git@github.com:peterolson/BigInteger.js.git

While not cryptographically relevant due to the lack of an accelerated powmod operator, this
library presents the basic structure of an arbitrary precision arithmetic package.  It is also
used in the stochastic consensus tests.

Default radix: 1.0e7, uses 24 bits (log_2 1.0e7 = 23.25349666421154).

Leemon Baird's BigInt.js

http://www.leemon.com/crypto/BigInt.js

Uses Montgomery reduction to accelerate powmod.  Notable for having a method to select radix based
on the underlying Javascript implementation, though the radix sizes are smaller than optimal.  It
provides support for randomly generating primes (using the Miller-Rabin primality test), but no
cryptographic functions.

Default radix: calculated on each platform. Chrome (OS/X 27.0.1453.93): 32768, 15 bits. Safari
(Version 6.0.4 (8536.29.13)): 32767, 15 bits.

Tom Wu's jsbn.js, et al

Fastest of the prior work.  Powmod selects reduction technique based on the bit length of the
exponent.  Also has a method to select radix size based on the underlying javascript
implementation, but usually chooses a larger and more efficient size than BigInt.js.
Notable for having adder-multipliers specialized to radix size.  Contains a complete set of
cryptographic utilities in additional files.

Current Work

The current work uses both Montgomery and Barrett reduction, includes specialized 
  differences

Comparisons
  o