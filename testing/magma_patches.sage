from sage.rings.function_field.function_field_polymod import FunctionField_global_integral

def _magma_init_(self, magma):
    R.<X, Y> = self.constant_base_field()[]
    poly = 0
    hom = self.base_field().hom(X)
    for i, a in enumerate(list(self.polynomial())):
        poly += hom(a) * Y^i
    mag_poly = magma(poly)
    return f'FunctionField({mag_poly._ref()})'

FunctionField_global_integral._magma_init_ = _magma_init_

def magma_genus(F):
    F.genus.set_cache(magma.Genus(magma(F)).sage())
