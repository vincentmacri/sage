"""
Various functions to deal with conversion fmpz <-> Python int/long
"""

from cpython.longintrepr cimport py_long
from sage.libs.flint.types cimport *

cdef fmpz_get_pylong(fmpz_t z)
cdef fmpz_get_pyintlong(fmpz_t z)
cdef int fmpz_set_pylong(fmpz_t z, py_long L) except -1
cdef Py_hash_t fmpz_pythonhash(fmpz_t z) noexcept
