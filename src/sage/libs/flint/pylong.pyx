"""
Various functions to deal with conversion fmpz <-> Python int/long

For doctests, see :class:`Integer`.

Adapted from :module:`sage.libs.gmp.pylong`.

AUTHORS:

- Gonzalo Tornaria (2006): initial GMP version

- David Harvey (2007-08-18): added ``mpz_get_pyintlong`` function
  (:issue:`440`)

- Jeroen Demeyer (2015-02-24): moved from c_lib, rewritten using
  ``mpz_export`` and ``mpz_import`` (:issue:`17853`)

- Vincent Macri (2026): Adapt to FLINT
"""

# ***************************************************************************
#       Copyright (C) 2026 Vincent Macri <vincent.macri@ucalgary.ca>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#                  https://www.gnu.org/licenses/
# ***************************************************************************

from cpython.long cimport PyLong_FromLong, PyLong_FromString, PyLong_AsLong
from cpython.longintrepr cimport _PyLong_New, py_long, digit, PyLong_SHIFT
from sage.cpython.pycore_long cimport (
    ob_digit, _PyLong_IsNegative,
    _PyLong_DigitCount, _PyLong_SetSignAndDigitCount
)
from sage.libs.flint.fmpz cimport *

cdef extern from *:
    void Py_SET_SIZE(object, Py_ssize_t)
    int hash_bits """
        #ifdef _PyHASH_BITS
        _PyHASH_BITS         /* Python 3 */
        #else
        (8 * sizeof(void*))  /* Python 2 */
        #endif
        """
    int limb_bits "(8 * sizeof(mp_limb_t))"


# Unused bits in every PyLong digit
cdef size_t PyLong_nails = 8*sizeof(digit) - PyLong_SHIFT


cdef fmpz_get_pylong_large(fmpz_t z):
    """
    Convert a nonzero ``fmpz`` to a Python ``long``.
    """
    # TODO: Consider using fpmz_get_signed_ui_array and PyLong_FromNativeBytes instead
    cdef char* s = fmpz_get_str(NULL, 2, z)
    cdef py_long L = PyLong_FromString(s, NULL, 2)
    return L

cdef fmpz_get_pylong(fmpz_t z):
    """
    Convert an ``fmpz`` to a Python ``long``.
    """
    if fmpz_fits_si(z):
        return PyLong_FromLong(fmpz_get_si(z))
    return fmpz_get_pylong_large(z)


cdef fmpz_get_pyintlong(fmpz_t z):
    """
    Convert an ``fmpz`` to a Python ``int`` if possible, or a ``long``
    if the value is too large.
    """
    if fmpz_fits_si(z):
        return PyLong_FromLong(fmpz_get_si(z))
    return fmpz_get_pylong_large(z)


cdef int fmpz_set_pylong(fmpz_t z, py_long L) except -1:
    """
    Convert a Python ``long`` `L` to an ``fmpz``.
    """
    cdef long x = PyLong_AsLong(L)
    fmpz_set_si(z, L)


cdef Py_hash_t fmpz_pythonhash(fmpz_t z) noexcept:
    """
    Hash an ``fmpz``, where the hash value is the same as the hash value
    of the corresponding Python ``int`` or ``long``, except that we do
    not replace -1 by -2 (the Cython wrapper for ``__hash__`` does that).
    """
    if fmpz_sgn(z) == 0:
        return 0
    return hash(fmpz_get_pyintlong(z))
