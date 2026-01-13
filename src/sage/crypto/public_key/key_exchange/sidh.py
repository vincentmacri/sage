r"""
Supersingular Isogeny Diffie-Hellman

Toy implementation of the historical SIDH scheme.
This implementation serves as an example of a class that implements :class:`KeyExchangeBase`
rather than :class:`CommutativeKeyExchangeBase`.

.. WARNING::

    This is a toy implementation of a broken cryptographic scheme for educational
    use only! Do not use this implementation, or any cryptographic features of
    Sage, in any setting where security is needed!
"""

from __future__ import annotations

import random
from typing import TYPE_CHECKING, Self

from sage.rings.finite_rings.finite_field_constructor import FiniteField
from sage.rings.integer import Integer
from sage.rings.integer_ring import ZZ
from sage.schemes.elliptic_curves.constructor import EllipticCurve
from sage.schemes.elliptic_curves.hom_composite import EllipticCurveHom_composite

from .key_exchange_base import KeyExchangeBase

if TYPE_CHECKING:
    from sage.schemes.elliptic_curves.ell_finite_field import EllipticCurve_finite_field
    from sage.schemes.elliptic_curves.ell_point import EllipticCurvePoint_finite_field

    PublicKeySIDH = tuple[EllipticCurve_finite_field, EllipticCurvePoint_finite_field, EllipticCurvePoint_finite_field]
    SecretKeySIDH = Integer | int

class SIDH(KeyExchangeBase):
    """
    Supersingular isogeny Diffie-Hellman key exchange.

    TODO: Cite Costello paper for example

    TESTS::

        sage: e_A = 4
        sage: e_B = 3
        sage: p = 2^e_A * 3^e_B - 1
        sage: K.<i> = GF(p^2, modulus=x^2 + 1)
        sage: a0 = 329 * i + 423
        sage: E = EllipticCurve(K, [0, a0, 0, 1, 0])
        sage: P_A = E(100 * i + 248, 304 * i + 199)
        sage: Q_A = E(426 * i + 394, 51 * i + 79)
        sage: P_B = E(358 * i + 275, 410 * i + 104)
        sage: Q_B = E(20 * i + 185, 281 * i + 239)
        sage: toy_sidh = key_exchange.SIDH(E, P_A, Q_A, P_B, Q_B)
        doctest:...: FutureWarning: SageMath's key exchange functionality is experimental and might change in the future.
                     See https://github.com/sagemath/sage/issues/41218 for details.
        sage: TestSuite(toy_sidh).run()
    """
    def __init__(
        self,
        E: EllipticCurve_finite_field,
        P_A: EllipticCurvePoint_finite_field,
        Q_A: EllipticCurvePoint_finite_field,
        P_B: EllipticCurvePoint_finite_field,
        Q_B: EllipticCurvePoint_finite_field,
    ) -> None:
        K = E.base_field()
        self._p: Integer = K.characteristic()
        n = self._p + 1
        self._e_A: Integer = n.valuation(2)
        self._e_B: Integer = n.valuation(3)

        # TODO: Test if anything breaks if we have a cofactor
        self._E = E

        def validate_point(P):
            if P not in self._E:
                raise ValueError(f'{P} is not on {self._E}')

        validate_point(P_A)
        self._P_A = P_A
        validate_point(Q_A)
        self._Q_A = Q_A
        validate_point(P_B)
        self._P_B = P_B
        validate_point(Q_B)
        self._Q_B = Q_B

    @classmethod
    def named_parameter_set(cls, name: str) -> Self:
        r"""
        Return an SIDH instance corresponding to a named parameter set.

        INPUT:

        - ``name`` -- one of the following:

            - ``"toy"``: a small SIDH instance over `\GF{431^2}`.
        """
        if name == 'toy':
            R = ZZ['x']
            x = R.gen()
            p = 2**4 * 3**3 - 1
            K = FiniteField(p**2, name='i', modulus=x**2 + 1)
            i = K.gen()
            E = EllipticCurve(K, [0, 329 * i + 423, 0, 1, 0])
            P_A = E(100 * i + 248, 304 * i + 199)
            Q_A = E(426 * i + 394, 51 * i + 79)
            P_B = E(358 * i + 275, 410 * i + 104)
            Q_B = E(20 * i + 185, 281 * i + 239)
            toy = cls(E, P_A, Q_A, P_B, Q_B)
            toy.rename('sidh-toy')
            return toy
        return super().named_parameter_set()

    def parameters(self) -> tuple[
            Integer,
            EllipticCurve_finite_field,
            EllipticCurvePoint_finite_field,
            EllipticCurvePoint_finite_field,
            EllipticCurvePoint_finite_field,
            EllipticCurvePoint_finite_field
            ]:
        r"""
        Return the parameter set of the SIDH instance.

        OUTPUT:

        A tuple (`E`, `P_A`, `Q_A`, `P_B`, `Q_B`) where:

        - `p` is the characteristic of the finite field `\GF{p^2}`
        - `E` is the starting curve
        - `P_A` and `Q_A` are the generators for Alice's secret key
        - `P_B` and `Q_B` are the generators for Bob's secret key
        """
        return (self._p, self._E, self._P_A, self._Q_A, self._P_B, self._Q_B)

    def alice_secret_key(self) -> Integer:
        r"""
        Generate Alice's secret key.

        EXAMPLES::

            sage: toy_sidh = key_exchange.SIDH.named_parameter_set('toy')
            sage: 0 <= toy_sidh.alice_secret_key() <= 4
            True
        """
        return Integer(random.randint(0, self._e_A))

    def bob_secret_key(self) -> Integer:
        r"""
        Generate Bob's secret key.

        EXAMPLES::

            sage: toy_sidh = key_exchange.SIDH.named_parameter_set('toy')
            sage: 0 <= toy_sidh.bob_secret_key() <= 3
            True
        """
        return Integer(random.randint(0, self._e_B))

    def alice_public_key(self, alice_secret_key: SecretKeySIDH) -> PublicKeySIDH:
        r"""
        Generate a valid public key for Alice.

        INPUT:

        - ``alice_secret_key`` -- Alice's secret key that will be used to generate
            the public key

        OUTPUT:

        Alice's public key as a tuple `(E_A, P'_B, Q'_B)`.
        """
        phi_A = self.alice_first_secret_isogeny(alice_secret_key)[0]
        E_A = phi_A.codomain()
        P_B1 = phi_A(self._P_B)
        Q_B1 = phi_A(self._Q_B)
        return (E_A, P_B1, Q_B1)

    def bob_public_key(self, bob_secret_key: SecretKeySIDH) -> PublicKeySIDH:
        r"""
        Generate a valid public key for Alice.

        INPUT:

        - ``alice_secret_key`` -- Alice's secret key that will be used to generate
            the public key

        OUTPUT:

        Bob's public key as a tuple `(E_B, P'_A, Q'_A)`.
        """
        phi_B = self.bob_first_secret_isogeny(bob_secret_key)[0]
        E_B = phi_B.codomain()
        P_A1 = phi_B(self._P_A)
        Q_A1 = phi_B(self._Q_A)
        return (E_B, P_A1, Q_A1)

    def alice_compute_shared_secret(self, alice_secret_key: SecretKeySIDH, bob_public_key: PublicKeySIDH) -> Integer:
        phi_A1 = self.alice_second_secret_isogeny(alice_secret_key, bob_public_key)[0]
        E_AB = phi_A1.codomain()
        return E_AB.j_invariant()

    def bob_compute_shared_secret(self, bob_secret_key: SecretKeySIDH, alice_public_key: PublicKeySIDH) -> Integer:
        phi_B1 = self.bob_second_secret_isogeny(bob_secret_key, alice_public_key)[0]
        E_BA = phi_B1.codomain()
        return E_BA.j_invariant()

    def alice_first_secret_isogeny(self, alice_secret_key: SecretKeySIDH) -> tuple[EllipticCurveHom_composite, tuple[Integer, ...]]:
        return self.secret_isogeny_path(self._E, alice_secret_key, self._P_A, self._Q_A)

    def alice_second_secret_isogeny(self, alice_secret_key: SecretKeySIDH, bob_public_key: PublicKeySIDH) -> tuple[EllipticCurveHom_composite, tuple[Integer, ...]]:
        E_B, P_A1, Q_A1 = bob_public_key
        return self.secret_isogeny_path(E_B, alice_secret_key, P_A1, Q_A1)

    def bob_first_secret_isogeny(self, bob_secret_key: SecretKeySIDH) -> tuple[EllipticCurveHom_composite, tuple[Integer, ...]]:
        return self.secret_isogeny_path(self._E, bob_secret_key, self._P_B, self._Q_B)

    def bob_second_secret_isogeny(self, bob_secret_key: SecretKeySIDH, alice_public_key: PublicKeySIDH) -> tuple[EllipticCurveHom_composite, tuple[Integer, ...]]:
        E_A, P_B1, Q_B1 = alice_public_key
        return self.secret_isogeny_path(E_A, bob_secret_key, P_B1, Q_B1)

    def secret_isogeny_path(self,
                            start_curve: EllipticCurve_finite_field,
                            secret_key: SecretKeySIDH,
                            P: EllipticCurvePoint_finite_field,
                            Q: EllipticCurvePoint_finite_field,
                            ) -> tuple[EllipticCurveHom_composite, tuple[Integer, ...]]:
        iso = start_curve.isogeny(P + secret_key * Q, algorithm='factored')
        j_invariant_path = [start_curve.j_invariant()]
        j_invariant_path.extend(E.codomain().j_invariant() for E in iso.factors())
        return iso, tuple(j_invariant_path)
