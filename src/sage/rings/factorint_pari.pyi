from typing import overload, Literal
from sage.rings.integer import Int

@overload
def factor_using_pari(n: Int, int_: Literal[True], debug_level: int = 0, proof: bool | None = None) -> list[tuple[int, int]]:
    ...

@overload
def factor_using_pari(n: Int, int_: Literal[False], debug_level: int = 0, proof: bool | None = None) -> list[tuple[Integer, int]]:
    ...

def factor_using_pari(n: Int, int_: bool = False, debug_level: int = 0, proof: bool | None = None) -> list[tuple[Int, int]]:
    ...
