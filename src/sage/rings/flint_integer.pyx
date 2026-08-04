cimport sage.structure.element

from sage.libs.flint.fmpz cimport *
from sage.cpython.string cimport char_to_str, str_to_bytes
from sage.rings import integer_ring
from sage.structure.parent cimport Parent

cdef Parent the_integer_ring = integer_ring.ZZ

cdef class FlintInt(sage.structure.element.EuclideanDomainElement):

    def __cinit__(self):
        # this function is only called to create global_dummy_Integer,
        # after that it will be replaced by fast_tp_new
        global the_integer_ring
        fmpz_init(self.value)
        self._parent = the_integer_ring

    def __init__(self, x=None):
        if x is None:
            return
            #fmpz_set_si(self.value, 0)
        elif isinstance(x, int):
            fmpz_set_si(self.value, x)
        else:
            raise TypeError(f'cannot convert type {type(x)} to FlintInt')

    def __dealloc__(self):
        fmpz_clear(self.value)

    def __add__(FlintInt self, FlintInt other):
        result = FlintInt()
        fmpz_add(result.value, self.value, other.value)
        return result

    def __mul__(FlintInt self, FlintInt other):
        result = FlintInt()
        fmpz_mul(result.value, self.value, other.value)
        return result

    def str(self, int base=10) -> str:
        return char_to_str(fmpz_get_str(NULL, base, self.value))

    def __repr__(self):
        return self.str()
