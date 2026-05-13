from sage.matrix.matrix cimport Matrix

cdef class Matrix_sparse(Matrix):
    cpdef _multiply_classical(self, Matrix right)
