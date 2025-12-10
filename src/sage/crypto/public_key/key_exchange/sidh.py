from __future__ import annotations
from typing import TYPE_CHECKING
import random

from sage.rings.integer import Integer
from sage.schemes.elliptic_curves.ell_curve_isogeny import EllipticCurveIsogeny

from .key_exchange_base import KeyExchangeBase

if TYPE_CHECKING:
    from sage.schemes.elliptic_curves.ell_finite_field import EllipticCurve_finite_field
    from sage.schemes.elliptic_curves.ell_point import EllipticCurvePoint_finite_field


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
        sage: toy_sidh = key_exchange.SIDH(p, E, P_A, P_B, Q_A, Q_B)
        doctest:...: FutureWarning: SageMath's key exchange functionality is experimental and might change in the future.
                     See https://github.com/sagemath/sage/issues/41218 for details.
        sage: TestSuite(toy_sidh).run()
    """

    def __init__(
        self,
        p: Integer | int,
        E: EllipticCurve_finite_field,
        P_A: EllipticCurvePoint_finite_field,
        P_B: EllipticCurvePoint_finite_field,
        Q_A: EllipticCurvePoint_finite_field,
        Q_B: EllipticCurvePoint_finite_field,
    ) -> None:
        self._p = Integer(p)
        n = self._p + 1
        self._e_A: Integer = n.valuation(2)
        self._e_B: Integer = n.valuation(3)
        self._E = E
        self._P_A = P_A
        self._P_B = P_B
        self._Q_A = Q_A
        self._Q_B = Q_B

    def parameters(self):
        r"""
        Return the parameter set of the SIDH instance.

        OUTPUT:

        A tuple (`p`, `E`, `P_A`, `P_B`, `Q_A`, `Q_B`) where:
        """
        return (self._p, self._e_A, self._e_B, self._E, self._P_A, self._P_B, self._Q_A, self._Q_B)

    def alice_secret_key(self) -> Integer:
        return Integer(random.randint(0, self._e_A))

    def bob_secret_key(self) -> Integer:
        return Integer(random.randint(0, self._e_B))

    def alice_public_key(self, alice_secret_key):
        phi_A = self.alice_first_secret_isogeny(alice_secret_key)
        E_A = phi_A.codomain()
        P_B1 = phi_A(self._P_B)
        Q_B1 = phi_A(self._Q_B)
        return (E_A, P_B1, Q_B1)

    def bob_public_key(self, bob_secret_key):
        phi_B = self.bob_first_secret_isogeny(bob_secret_key)
        E_B = phi_B.codomain()
        P_A1 = phi_B(self._P_A)
        Q_A1 = phi_B(self._Q_A)
        return (E_B, P_A1, Q_A1)

    def alice_compute_shared_secret(self, alice_secret_key, bob_public_key):
        phi_A1 = self.alice_second_secret_isogeny(alice_secret_key, bob_public_key)
        E_AB = phi_A1.codomain()
        j_A = E_AB.j_invariant()
        return j_A

    def bob_compute_shared_secret(self, bob_secret_key, alice_public_key):
        phi_B1 = self.bob_second_secret_isogeny(bob_secret_key, alice_public_key)
        E_BA = phi_B1.codomain()
        j_B = E_BA.j_invariant()
        return j_B

    def alice_first_secret_isogeny(self, alice_secret_key):
        isogenyMap = self.buildIsogenyByBreakingDown(alice_secret_key, 2, self._E, self._P_A, self._Q_A)
        return isogenyMap[0]

    def bob_first_secret_isogeny(self, bob_secret_key):
        isogenyMap = self.buildIsogenyByBreakingDown(bob_secret_key, 3, self._E, self._P_B, self._Q_B)
        return isogenyMap[0]

    def alice_second_secret_isogeny(self, alice_secret_key, bob_public_key):
        (E_B, P_A1, Q_A1) = bob_public_key
        isogenyMap = self.buildIsogenyByBreakingDown(alice_secret_key, 2, E_B, P_A1, Q_A1)
        return isogenyMap[0]

    def bob_second_secret_isogeny(self, bob_secret_key, alice_public_key):
        (E_A, P_B1, Q_B1) = alice_public_key
        isogenyMap = self.buildIsogenyByBreakingDown(bob_secret_key, 3, E_A, P_B1, Q_B1)
        return isogenyMap[0]

    def buildIsogenyByBreakingDown(self, person_secret_key, ell, domain_EC, P_generate, Q_generate):
        sequenceOfIsogenies = []
        if ell == 2:
            e_power = self._e_A
        elif ell == 3:
            e_power = self._e_B
        temp_S = P_generate + person_secret_key * Q_generate
        temp_R = (ell ^ (e_power - 1)) * temp_S
        temp_phi = EllipticCurveIsogeny(domain_EC, temp_R)
        temp_S = temp_phi(temp_S)
        sequenceOfIsogenies.append((temp_phi, temp_S))
        finalIsogeny = temp_phi
        for i in range(1, e_power):
            (temp_phi_i1, temp_S_i1) = sequenceOfIsogenies[i - 1]
            temp_R = (ell ^ (e_power - i - 1)) * temp_S_i1
            temp_phi_i = EllipticCurveIsogeny(temp_phi_i1.codomain(), temp_R)
            temp_S_i = temp_phi_i(temp_S_i1)
            sequenceOfIsogenies.append((temp_phi_i, temp_S_i))
            finalIsogeny = temp_phi_i * finalIsogeny
        return (finalIsogeny, sequenceOfIsogenies)
