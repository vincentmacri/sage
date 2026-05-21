r"""
Utility functions for matrices

Inline utility functions for matrices. This module is mainly to reduce code
duplication, as well as ensure error messages are kept consistent.

AUTHORS:

- Vincent Macri (2026): refactored old code into `check_matrix_multiplication_sizes`
"""

# ****************************************************************************
#       Copyright (C) 2026 Vincent Macri <vincent.macri@ucalgary.ca>
#
#  Distributed under the terms of the GNU General Public License (GPL)
#  as published by the Free Software Foundation; either version 2 of
#  the License, or (at your option) any later version.
#                  https://www.gnu.org/licenses/
# ****************************************************************************

from sage.matrix.matrix0 cimport Matrix

cdef inline void check_matrix_multiplication_sizes(Matrix left, Matrix right) except *:
    if left._ncols != right._nrows:
        raise ArithmeticError("number of columns of left must equal number of rows of right")

cdef inline void check_set_matrix_product_sizes(Matrix destination, Matrix left, Matrix right) except *:
    check_matrix_multiplication_sizes(left, right)
    if destination is left or destination is right:
        raise ValueError("destination cannot refer to the same matrix as left or right")
    if destination._ncols != right._ncols:
        raise ValueError("number of columns of destination and right must be equal")
    if destination._nrows != left._nrows:
        raise ValueError("number of rows of destination and left must be equal")
    if destination._base_ring is not left._base_ring or destination._base_ring is not right._base_ring:
        raise ValueError("base rings of destination, left, and right must be the same")
