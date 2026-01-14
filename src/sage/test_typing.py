from sage.rings.integer import Integer
from typing import reveal_type

a = Integer(1)
b = 2

reveal_type(a + b)
reveal_type(b + a)

reveal_type(a - b)
reveal_type(b - a)

reveal_type(a * b)
reveal_type(b * a)

reveal_type(a ** b)
reveal_type(b ** a)
