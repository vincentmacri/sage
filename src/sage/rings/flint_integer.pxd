from sage.libs.flint.types cimport fmpz_t

from sage.structure.element cimport EuclideanDomainElement, RingElement
from sage.categories.morphism cimport Morphism

cdef class FlintInt(EuclideanDomainElement):
    cdef fmpz_t value
