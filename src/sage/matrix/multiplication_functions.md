`matrix2.pyx:9402:    def _multiply_strassen(self, Matrix right, int cutoff=0):`
    - ~~Checks bounds~~
    - Allows rectangular
    - Allocates zero matrix and sets it to product

`matrix_dense.pyx:300:    def _multiply_classical(left, matrix.Matrix right):`
    - ~~Checks bounds~~
    - Allows rectangular
    - Allocates zero matrix and sets it to product

`matrix_generic_dense.pyx:298:    def _multiply_classical(left, matrix.Matrix _right):`
    - ~~Checks bounds~~
    - Allows rectangular
    - Allocates zero matrix and sets it to product
    - Also allocates list of `None` for intermediate computations
    - ~~**This is weird, I added a print statement*~~

~~`matrix_gf2e_dense.pxd:11:    cpdef Matrix_gf2e_dense _multiply_newton_john(Matrix_gf2e_dense self, Matrix_gf2e_dense right)`~~
~~`matrix_gf2e_dense.pxd:12:    cpdef Matrix_gf2e_dense _multiply_karatsuba(Matrix_gf2e_dense self, Matrix_gf2e_dense right)`~~
~~`matrix_gf2e_dense.pxd:13:    cpdef Matrix_gf2e_dense _multiply_strassen(Matrix_gf2e_dense self, Matrix_gf2e_dense right, cutoff=*)`~~

`matrix_gf2e_dense.pyx:394:    def _multiply_classical(self, Matrix right):`
    - ~~Checks bounds~~
    - Allows rectangular
    - Allocates zero matrix and sets it to product

`matrix_gf2e_dense.pyx:484:    cpdef Matrix_gf2e_dense _multiply_newton_john(Matrix_gf2e_dense self, Matrix_gf2e_dense right):`
    - ~~Checks bounds~~
    - Allows rectangular
    - Allocates zero matrix and sets it to product

`matrix_gf2e_dense.pyx:546:    cpdef Matrix_gf2e_dense _multiply_karatsuba(Matrix_gf2e_dense self, Matrix_gf2e_dense right):`
    - ~~Checks bounds~~
    - Allows rectangular
    - Allocates zero matrix and sets it to product

`matrix_gf2e_dense.pyx:594:    cpdef Matrix_gf2e_dense _multiply_strassen(Matrix_gf2e_dense self, Matrix_gf2e_dense right, cutoff=0):`
    - ~~Checks bounds~~
    - Allows rectangular
    - Allocates zero matrix and sets it to product

~~`matrix_gfpn_dense.pxd:33:    cpdef Matrix_gfpn_dense _multiply_classical(Matrix_gfpn_dense self, Matrix_gfpn_dense right) noexcept`~~
~~`matrix_gfpn_dense.pxd:34:    cpdef Matrix_gfpn_dense _multiply_strassen(Matrix_gfpn_dense self, Matrix_gfpn_dense right, cutoff=*) noexcept`~~

`matrix_gfpn_dense.pyx:1344:    cpdef Matrix_gfpn_dense _multiply_classical(Matrix_gfpn_dense self, Matrix_gfpn_dense right) noexcept:`
    - ~~Checks bounds~~
    - Allows rectangular
    - Does in-place multiplication on a copy 

`matrix_gfpn_dense.pyx:1372:    cpdef Matrix_gfpn_dense _multiply_strassen(Matrix_gfpn_dense self, Matrix_gfpn_dense right, cutoff=0) noexcept:`
    - ~~Checks bounds~~
    - Allows rectangular
    - **Not sure if this function exists in meataxe??? I added a print statement**

`matrix_integer_dense.pyx:757:    def _multiply_linbox(self, Matrix_integer_dense right):`
    - ~~**Does not checks bounds!!!**
        - Added bounds check~~
    - Allows rectangular
    - Allocates new matrix and sets it to product

`matrix_integer_dense.pyx:796:    def _multiply_classical(self, Matrix_integer_dense right):`
    - ~~Checks bounds~~
    - Allows rectangular
    - Allocates new matrix and sets it to product

`matrix_integer_dense.pyx:1565:    def _multiply_multi_modular(self, Matrix_integer_dense right):`
    - **Does not check bounds!!!**
        - Bounds are checked by another function this calls
    - Allows rectangular
    - Allocates new matrix and sets it to product
    
~~`matrix_mod2_dense.pxd:9:    cpdef Matrix_mod2_dense _multiply_m4rm(Matrix_mod2_dense self, Matrix_mod2_dense right, int k)`~~
~~`matrix_mod2_dense.pxd:10:    cpdef Matrix_mod2_dense _multiply_strassen(Matrix_mod2_dense self, Matrix_mod2_dense right, int cutoff)`~~

`matrix_mod2_dense.pyx:776:    cpdef Matrix_mod2_dense _multiply_m4rm(Matrix_mod2_dense self, Matrix_mod2_dense right, int k):`
    - ~~Checks bounds~~
    - Allows rectangular
    - Allocates new matrix and sets it to product

`matrix_mod2_dense.pyx:854:    def _multiply_classical(Matrix_mod2_dense self, Matrix_mod2_dense right):`
    - **Does not check bounds!!!**
    	- This is okay somehow?
    - Allows rectangular
    - Allocates new matrix and sets it to product

`matrix_mod2_dense.pyx:905:    cpdef Matrix_mod2_dense _multiply_strassen(Matrix_mod2_dense self, Matrix_mod2_dense right, int cutoff):`
    - ~~Checks bounds~~
    - Allows rectangular
    - Allocates new matrix and sets it to product

`matrix_rational_dense.pyx:1187:    def _multiply_flint(self, Matrix_rational_dense right):`
    - **Does not check bounds!!!**
    	- Does not error when bounds don't match
    - Allows rectangular
    - Allocates new matrix and sets it to product

`matrix_rational_dense.pyx:1218:    def _multiply_over_integers(self, Matrix_rational_dense right, algorithm='default'):`
    - **Does not check bounds!!!**
    	- Bounds are checked elsewhere
    - Allows rectangular
    - Allocates new matrix and sets it to product
    - Also does stuff to handle denominators
        - Does this allocate yet another matrix? **Need to check**

`matrix_rational_dense.pyx:2886:    def _multiply_pari(self, Matrix_rational_dense right):`
    - ~~Checks bounds **with weird error message, test this**~~
    - I do not really understand how the allocation here works

`matrix_sparse.pyx:174:    def _multiply_classical(Matrix_sparse left, Matrix_sparse right):`
    - Doesn't check bounds
    	- "Works" anyway
    - Sparse multiplication
    - I don't see how to improve this given the nature of sparse matrix arithmetic

`matrix_sparse.pyx:230:    def _multiply_classical_with_cache(Matrix_sparse left, Matrix_sparse right):`
    - Doesn't check bounds
    	- "Works" anyway
    - Sparse multiplication
    - A bit weird, we can probably leave it alone though

`matrix0.pyx:5569:    cdef sage.structure.element.Matrix _matrix_times_matrix_(self, sage.structure.element.Matrix right):`
    - **Does not check bounds!!!**
    	- The functions it calls can check the bounds (should they?)
    - Assumes bounds are satisfied in the docstring!
    - Calls `self._multiply_strassen(right)` or `self._multiply_classical(right)`

`matrix_complex_ball_dense.pyx:499:    cdef _matrix_times_matrix_(self, Matrix other):`
    - **Does not check bounds!!!** (**should it? The base class version of `_matrix_times_matrix_` require this by assumption**)
    - Allocates new matrix and sets to product
    - Simple

`matrix_cyclo_dense.pyx:638:    cdef _matrix_times_matrix_(self, baseMatrix right):`
    - **Does not check bounds!!!** (**should it? The base class version of `_matrix_times_matrix_` requires this by assumption**)
    - Allocates new matrix and sets to product

`matrix_double_dense.pyx:223:    cdef sage.structure.element.Matrix _matrix_times_matrix_(self, sage.structure.element.Matrix right):`
    - ~~Checks bounds~~ (**should it? The base class version of `_matrix_times_matrix_` requires this by assumption**)
    - Allocates matrix and sets to product

`matrix_gap.pyx:350:    cdef Matrix _matrix_times_matrix_(left, Matrix right):`
    - ~~Checks bounds~~ (**should it? The base class version of `_matrix_times_matrix_` requires this by assumption**)
    - Allocates matrix and sets to product

`matrix_gf2e_dense.pyx:441:    cdef _matrix_times_matrix_(self, Matrix right):`
    - ~~Checks bounds~~ (**should it? The base class version of `_matrix_times_matrix_` requires this by assumption**)
    - Allocates matrix and sets to product
        - **Check how this works**

`matrix_integer_dense.pyx:863:    cdef sage.structure.element.Matrix _matrix_times_matrix_(self, sage.structure.element.Matrix right):`
    - ~~Checks bounds~~ (**should it? The base class version of `_matrix_times_matrix_` requires this by assumption**)
    - Allocates matrix and sets to product

`matrix_integer_sparse.pyx:277:    cdef sage.structure.element.Matrix _matrix_times_matrix_(self, sage.structure.element.Matrix _right):`
    - Allocates matrix and sets to product

`matrix_mod2_dense.pyx:763:    cdef _matrix_times_matrix_(self, Matrix right):`
    - Just calls `_multiply_strassen`

`matrix_modn_dense_template.pxi:1044:    cdef _matrix_times_matrix_(self, Matrix right):`
    - ~~Checks bounds~~
    - Allocates new matrix and sets to product

`matrix_modn_sparse.pyx:287:    cdef Matrix _matrix_times_matrix_(self, Matrix _right):`
    - Allocates new matrix and sets to product

`matrix_modn_sparse.pyx:362:    def _matrix_times_matrix_dense(self, Matrix _right):`
    - Allocates new matrix and sets to product

`matrix_rational_dense.pyx:1169:    cdef sage.structure.element.Matrix _matrix_times_matrix_(self, sage.structure.element.Matrix right):`
    - Wrapper around `_multiply_flint`

`matrix_rational_sparse.pyx:217:    cdef sage.structure.element.Matrix _matrix_times_matrix_(self, sage.structure.element.Matrix _right):`
    - Allocates new matrix and sets to product

`matrix_rational_sparse.pyx:262:    def _matrix_times_matrix_dense(self, sage.structure.element.Matrix _right):`
    - Allocates new matrix and sets to product
