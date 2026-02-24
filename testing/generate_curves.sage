import argparse
import itertools
import logging
import os
import time

logger = logging.getLogger(__name__)

# Curve generation based on Theorem 3.4.1 of Adrian Tang's thesis

def genus_estimate(n, m):
    # Heuristic used for parameter generation, since we haven't proven this we still verify the genus with Sage.
    return Integer((n - 1) * (n * m / 2 - 1))

def random_curve_over_finite_field(K, n, m, attempts=0, already_found=None):
    if already_found is None:
        already_found = []

    if attempts >= 50:
        logger.warning(f'Could not find suitable curve for {K}, {n}, {m} after 50 attempts, giving up.')

    assert n >= 2
    Kx.<x> = FunctionField(K)
    K_polynomial_ring = K.polynomial_ring()
    R.<X, Y> = K[]
    while True:
        logger.debug('Choosing a')
        a = [Kx(K_polynomial_ring.random_element(degree=n * m - 1))]
        for i in range(1, n - 1):
            a.append(Kx(K_polynomial_ring.random_element(degree=(0, (n - i) * m - 1))))
        a.append(Kx(K_polynomial_ring.random_element(degree=m)))
        logger.debug('Chose a, verifying')

        assert a[0].degree() == n * m - 1
        for i in range(1, n - 1):
            assert a[0].degree() < (n * i) * m
        assert a[n - 1].degree() == m
        logger.debug('Verified a, computing zeta')

        t = polygen(Kx, name='t')
        zeta = t^n + sum((a[i] * t^i for i in range(n)))
        logger.debug('Found zeta, checking irreducibility')
        if zeta.is_irreducible():
            logger.debug('Zeta is irreducible, creating F')

            hom = Kx.hom(X)
            zeta_curve = Y^n + sum(hom(a[i]) * Y^i for i in range(n))

            F.<y> = Kx.extension(zeta)
            if F in already_found:
                logger.warning('Already found curve, trying again')
                return random_curve_over_finite_field(K, n, m, attempts=attempts+1, already_found=already_found)

            C = Curve(zeta_curve)
            logger.debug('Created F and C')

            logger.debug('Checking if C is singular')
            if C.is_singular():
                logger.debug('Curve is singular, trying again.', K, n, m)
                return random_curve_over_finite_field(K, n, m, attempts=attempts+1, already_found=already_found)
            
            logger.debug('Checking exact constant field of F')
            if F.constant_field() is not K:
                logger.debug('Exact constant field is not base field, trying again.', K, n, m)
                return random_curve_over_finite_field(K, n, m, attempts=attempts+1, already_found=already_found)


            assert F.degree() == n

            logger.debug('Created F, computing genus')
            g = F.genus()
            logger.debug('Genus is', g)
            if g < 2:
                logger.error(F)
                logger.error('Genus is only', F.genus(), 'failing. Input was', n, m)
                return None
            logger.debug('Computed g, setting finite and infinite maximal order bases')

            logger.debug('Finding infinite places')

            infinite_places = F.places_above(Kx.place_infinite())
            assert len(infinite_places) == 2
            infty1, infty2 = infinite_places
            assert infty1.degree() == 1
            assert infty2.degree() == 1

            infty1 = infty1.divisor()
            infty2 = infty2.divisor()
            assert infty1.degree() == 1
            assert infty2.degree() == 1
            return F
    else:
        logger.debug('zeta was not irreducible, trying again')
        return random_curve_over_finite_field(K, n, m, already_found=already_found)

def generation_params_for_finite_field(K, min_genus, max_genus):
    params = []

    # If n is 2 it definitely has a degree 2 subfield, making it hyperelliptic.
    # If n is odd it doesn't have a degree 2 subfield
    # I don't know of an easy way to determine whether or not a degree 2 subfield exists if n is even
    n = 3
    while genus_estimate(n, 1) <= max_genus:
        m = 1 if n > 3 else 2  # n = 3, m = 1 seems to always give a genus 1 (elliptic) curve
        while genus_estimate(n, m) <= max_genus:
            if genus_estimate(n, m) >= min_genus:
                params.append((K, n, m))
            m += 1
        n += 1
    return params

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)

    # Process command line parameters
    parser = argparse.ArgumentParser(prog='Function field generator')
    parser.add_argument('--repeat', default=3, type=int, help='Number of function fields to generate per parameter set (default: 3)')
    parser.add_argument('--min-g', default=3, type=int, help='Minimum genus (default: 3)')
    parser.add_argument('--max-g', default=10, type=int, help='Maximum genus (default: 10)')

    args, unknown = parser.parse_known_args()
    min_genus = Integer(args.min_g)
    max_genus = Integer(args.max_g)
    repeat = args.repeat
    assert min_genus <= max_genus
    assert min_genus >= 3

    logger.info(f'Generating curves for genera from {min_genus} to {max_genus}')

    params = []

    prime_exponent_range = (0, 1, 3, 10, 15)
    primes = [next_prime(2 ** i) for i in prime_exponent_range]
    for p in primes:
        params.extend(generation_params_for_finite_field(GF(p), min_genus, max_genus))

    params.sort(key=lambda param : (genus_estimate(param[1], param[2]), param[0].cardinality()))

    logger.info(f'Generating {len(params) * repeat} across {len(params)} parameter sets')

    all_function_fields = dict()
    for i, param in enumerate(params):
        generation_start_time = time.time()
        K, n, m = param
        expected_genus = genus_estimate(n, m)
        p = K.cardinality()

        logger.info(f'Generating curve for parameter set {i + 1} / {len(params)}')
        logger.info(f'p: {K.cardinality()} | g: {expected_genus} | n: {n} | m: {m}')

        function_fields = []
        while len(function_fields) < repeat:
            start_time = time.time()
            F = random_curve_over_finite_field(K, n, m, already_found=function_fields)
            end_time = time.time()
            if F is not None:
                if F.genus() != expected_genus:
                    logger.error('Found curve where genus did not match estimate!')
                    logger.error(F)
                elif F not in function_fields:
                    assert F.genus() == expected_genus
                    function_fields.append(F)
                    logger.info(f'Found curve {len(function_fields)} / {repeat} in {end_time - start_time} seconds')
                else:
                    logger.error('Found same curve twice! This should not be allowed to happen!')
        if len(function_fields) > 0:
            if K.cardinality() not in all_function_fields:
                all_function_fields[(p, expected_genus)] = []
            all_function_fields[(p, expected_genus)].append((n, m, tuple(str(F.polynomial()).replace('y', 't') for F in function_fields)))
        else:
            logger.warning('Failed to find any curves for input {(K, n, m)}')
        generation_time = time.time() - generation_start_time
        remaining = len(params) - (i + 1)
        logger.info(f'Time to generate this parameter set: {generation_time} seconds')
        logger.info(f'Estimated time remaining: {generation_time * remaining / (60 * 60)} hours')

    print('FUNCTION_FIELDS =', all_function_fields)
    logger.info('Done')
