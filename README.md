black-coffee
============


Black Coffee is an unlimited-precision integer and cryptography package.  It is intended to ba a fundamental
component of a framework to support NSA-proof web applications.  The algorithms are mostly based on The
Handbook of Applied Cryptography (HAC), but also include a couple clever tricks from other authors.  The code
is optimized for fast computation, but nonetheless generally has a small memory footprint.

As of the end of June 2013, the integer portion is complete, tested, and mostly optimized.
Unfortunately, Firefox seems to be the slowest of the major browsers, as the Tor Browser (based on
Firefox) is a key platform target.  (Much of this work could be easily translated to C++ and
encapsulated in an NPAPI plug-in.)  The prime finder is written but not yet optimized. The
cryptography routines are not yet written.  RSA, SHA256/512, and one of the symmetric key
algorithms will the first to be supported.

Two other packages provided working examples of some of the algorithms in HAC: jsbn, a library
written by Tom Wu, and BigInt by Leemon Baird.  They have significantly different approaches to
some of the main problems -- which is in itself instructive -- and thereby provide assurance that
consistency testing between the three will be an effective verification method.  This library is
in some ways a hybrid of the two.  On the one hand it uses the same representation as BigInt --
simply an Array instance -- but it uses the split-digit technique used in jsbn.  This library also
makes several new developments: the computations are written as simple functions on strings of
unsigned digits, while sign conventions, error checking, and parameter coercion are handled at an
object layer, allowing a simple very representation of numbers for computation; the multiplication
operation uses Karatsuba's technique to reduce the number of digit multiplications when operands
are sufficiently large, changing the scaling factor from O(n^2) to O(n^1.65); modular
exponentiation uses a Montgomery multiplier like BigInt and a sliding window technique like jsbn,
but it adds a Montgomery square operator -- an adaptation of Montgomery multiplication (HAC 14.36)
to multiple precision squaring (HAC 14.16).  The latter, in itself, provides a 17% reduction in
running time on Safari.



 ### Prior Art:

#### Peter Olson's [BigInteger.js](git@github.com:peterolson/BigInteger.js.git)


While not cryptographically relevant due to the lack of an accelerated powmod operator, this
library presents the basic structure of an arbitrary precision arithmetic package.

Default radix: 1.0e7, uses about  24 bits per digit (log_2 1.0e7 = 23.25349666421154).

#### Leemon Baird's [BigInt.js](http://www.leemon.com/crypto/BigInt.js)
    

Uses Montgomery reduction to accelerate powmod.  Notable for having a method to select radix based
on the underlying Javascript implementation, though the radix sizes are smaller than optimal.  It
provides support for randomly generating primes (using the Miller-Rabin primality test), but no
cryptographic functions.

Default radix: calculated on each platform. Chrome (OS/X 27.0.1453.93): 32768, 15 bits. Safari
(Version 6.0.4 (8536.29.13)): 32767, 15 bits.

#### Tom Wu's jsbn.js, et al

Fastest of the prior work.  Powmod selects reduction technique based on the bit length of the
exponent.  Also has a method to select radix size based on the underlying javascript
implementation, but usually chooses a larger and more efficient size than BigInt.js.
Notable for having adder-multipliers specialized to radix size.  Contains a complete set of
cryptographic utilities in additional files.

Current Work

It is di