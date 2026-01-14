from __future__ import annotations

from typing import overload, reveal_type

from sage.rings.integer import Integer, Int

reveal_type(Integer)
reveal_type(Int)

a: Integer = Integer(1)
b: int = 2

c = a + b
d = b + a

reveal_type(c)
reveal_type(d)
