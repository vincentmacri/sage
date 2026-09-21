from cpython.object cimport *
from libc.string cimport memcpy

from cysignals.memory cimport check_allocarray, check_malloc, sig_free

cimport sage.structure.element

from sage.libs.flint.fmpz cimport *
from sage.libs.flint.pylong cimport *
from sage.cpython.string cimport char_to_str, str_to_bytes
from sage.cpython.python_debug cimport if_Py_TRACE_REFS_then_PyObject_INIT
from sage.rings import integer_ring
from sage.structure.parent cimport Parent
from sage.ext.stdsage cimport PY_NEW

cdef extern from *:
    int likely(int) nogil
    int unlikely(int) nogil  # Defined by Cython

cdef extern from "Python.h":
    void Py_SET_REFCNT(PyObject*, Py_ssize_t) nogil

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
            fmpz_set_pylong(self.value, x)
        else:
            raise TypeError(f'cannot convert type {type(x)} to FlintInt')

    def __dealloc__(self):
        fmpz_clear(self.value)

    def __add__(FlintInt self, FlintInt other):
        cdef FlintInt x = <FlintInt>PY_NEW(FlintInt)
        fmpz_add(x.value, self.value, other.value)
        return x

    def __mul__(FlintInt self, FlintInt other):
        cdef FlintInt x = <FlintInt>PY_NEW(FlintInt)
        fmpz_mul(x.value, self.value, other.value)
        return x

    def str(self, int base=10) -> str:
        return char_to_str(fmpz_get_str(NULL, base, self.value))

    def __repr__(self):
        return self.str()

    def __int__(self):
        """
        Return the Python int corresponding to this Sage integer.

        EXAMPLES::

            sage: n = 920938
            sage: int(n)
            920938
            sage: int(-n)
            -920938
            sage: type(n.__int__())
            <... 'int'>
            sage: n = 99028390823409823904823098490238409823490820938
            sage: int(n)
            99028390823409823904823098490238409823490820938
            sage: int(-n)
            -99028390823409823904823098490238409823490820938
            sage: type(n.__int__())
            <class 'int'>
            sage: int(-1), int(0), int(1)
            (-1, 0, 1)
        """
        return fmpz_get_pyintlong(self.value)

cdef FlintInt global_dummy_Integer
global_dummy_Integer = FlintInt()

# A global pool for performance when integers are rapidly created and destroyed.
# It operates on the following principles:
#
# - The pool starts out empty.
# - When a new integer is needed, one from the pool is returned
#   if available, otherwise a new Integer object is created
# - When an integer is collected, it will add it to the pool
#   if there is room, otherwise it will be deallocated.
cdef int integer_pool_size = 100

cdef PyObject** integer_pool
cdef int integer_pool_count = 0

# used for profiling the pool
cdef int total_alloc = 0
cdef int use_pool = 0


cdef PyObject* fast_tp_new(type t, args, kwds) except NULL:
    global integer_pool, integer_pool_count, total_alloc, use_pool

    cdef PyObject* new

    # for profiling pool usage
    # total_alloc += 1

    # If there is a ready integer in the pool, we will
    # decrement the counter and return that.

    if integer_pool_count > 0:

        # for profiling pool usage
        # use_pool += 1

        integer_pool_count -= 1
        new = <PyObject *> integer_pool[integer_pool_count]

    # Otherwise, we have to create one.
    else:

        # allocate enough room for the Integer, sizeof_Integer is
        # sizeof(Integer). The use of PyObject_Malloc directly
        # assumes that Integers are not garbage collected, i.e.
        # they do not possess references to other Python
        # objects (as indicated by the Py_TPFLAGS_HAVE_GC flag).
        # See below for a more detailed description.
        new = <PyObject*>PyObject_Malloc(sizeof_Integer)
        if unlikely(new == NULL):
            raise MemoryError

        # Now set every member as set in z, the global dummy Integer
        # created before this tp_new started to operate.
        memcpy(new, (<void*>global_dummy_Integer), sizeof_Integer)

        # In sufficiently new versions of GMP, mpz_init() does not allocate
        # any memory. We assume that memcpy a newly-initialized mpz results
        # in a valid new mpz. Normally, one would use mpz_init() for this.
        # This saves time by avoiding extra function calls.
        #
        # What is done here is potentially very dangerous as it reaches
        # deeply into the internal structure of GMP. Consequently things
        # may break if a new release of GMP changes some internals. To
        # emphasize this, this is what the GMP manual has to say about
        # the documentation for the struct we are using:
        #
        #  "This chapter is provided only for informational purposes and the
        #  various internals described here may change in future GMP releases.
        #  Applications expecting to be compatible with future releases should use
        #  only the documented interfaces described in previous chapters."

    # This line is only needed if Python is compiled in debugging mode
    # './configure --with-pydebug' or SAGE_DEBUG=yes. If that is the
    # case a Python object has a bunch of debugging fields which are
    # initialized with this macro.

    if_Py_TRACE_REFS_then_PyObject_INIT(
            new, Py_TYPE(global_dummy_Integer))

    # The global_dummy_Integer may have a reference count larger than
    # one, but it is expected that newly created objects have a
    # reference count of one. This is potentially unneeded if
    # everybody plays nice, because the global_dummy_Integer has only
    # one reference in that case.

    # Objects from the pool have reference count zero, so this
    # needs to be set in this case.

    Py_SET_REFCNT(<PyObject*>new, 1)

    return new


cdef void fast_tp_dealloc(PyObject* o) noexcept:
    # If there is room in the pool for a used integer object,
    # then put it in rather than deallocating it.
    global integer_pool, integer_pool_count

    cdef fmpz_t o_fmpz = <fmpz_t>((<FlintInt>o).value)

    if integer_pool_count < integer_pool_size:
        # It's cheap to zero out an integer, so do it here.
        fmpz_set_si(o_fmpz, 0)

        # And add it to the pool.
        integer_pool[integer_pool_count] = o
        integer_pool_count += 1
        return

    # No space in the pool, so just free the mpz_t.
    fmpz_clear(o_fmpz)

    # Free the object. This assumes that Py_TPFLAGS_HAVE_GC is not
    # set. If it was set another free function would need to be
    # called.
    PyObject_Free(o)


from sage.misc.allocator cimport hook_tp_functions
cdef hook_fast_tp_functions():
    """
    Initialize the fast integer creation functions.
    """
    global global_dummy_Integer, sizeof_Integer, integer_pool

    integer_pool = <PyObject**>check_allocarray(integer_pool_size, sizeof(PyObject*))

    cdef PyObject* o
    o = <PyObject *>global_dummy_Integer

    # store how much memory needs to be allocated for an Integer.
    sizeof_Integer = o.ob_type.tp_basicsize

    # Finally replace the functions called when an Integer needs
    # to be constructed/destructed.
    hook_tp_functions(global_dummy_Integer, <newfunc>(&fast_tp_new), <destructor>(&fast_tp_dealloc), False)

def free_integer_pool():
    cdef int i
    cdef PyObject *o

    global integer_pool_count, integer_pool_size

    for i in range(integer_pool_count):
        o = integer_pool[i]
        fmpz_clear((<FlintInt>o).value)
        # Free the object. This assumes that Py_TPFLAGS_HAVE_GC is not
        # set. If it was set another free function would need to be
        # called.
        PyObject_Free(o)

    integer_pool_size = 0
    integer_pool_count = 0
    sig_free(integer_pool)


# Replace default allocation and deletion with faster custom ones
hook_fast_tp_functions()

## zero and one initialization
#initialized = False
#cdef set_zero_one_elements():
#    global the_integer_ring, initialized
#    if initialized:
#        return
#    the_integer_ring._zero_element = FlintInteger(0)
#    the_integer_ring._one_element = FlintInteger(1)
#    initialized = True
#set_zero_one_elements()

#cdef Integer zero = the_integer_ring._zero_element
#cdef Integer one = the_integer_ring._one_element

# pool of small integer for fast sign computation
# Use the same defaults as Python3 documented at
# https://docs.python.org/3/c-api/long.html#c.PyLong_FromLong
DEF small_pool_min = -5
DEF small_pool_max = 256
# we could use the above zero and one here
cdef list small_pool = [FlintInt(k) for k in range(small_pool_min, small_pool_max+1)]

cdef inline FlintInt smallInteger(long value):
    """
    This is the fastest way to create a (likely) small Integer.
    """
    cdef FlintInt z
    if small_pool_min <= value <= small_pool_max:
        return <FlintInt>small_pool[value - small_pool_min]
    else:
        z = PY_NEW(FlintInt)
        fmpz_set_si(z.value, value)
        return z

# Support Python's numbers abstract base class
import numbers
numbers.Integral.register(FlintInt)

# Free the memory used by the integer pool when sage exits. This is
# not strictly necessary because the OS should immediately reclaim
# these resources when sage terminates. However, it may aid valgrind
# or similar tools, and can help expose bugs in other code.
import atexit
atexit.register(free_integer_pool)
