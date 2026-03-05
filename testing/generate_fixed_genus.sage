import argparse
import logging
import time
import random

load(f'{os.path.dirname(os.path.realpath(__file__))}/magma_patches.sage')

USE_MAGMA = True
try:
    magma('1')
except TypeError:
    USE_MAGMA = False

logger = logging.getLogger(__name__)

g_n_pair_counts = dict()

def valid_function_fields(prime, n, genus, Cf, trials=50):
    genus_estimate = ((n - 1) * (n * Cf - 2) // 2)
    if genus_estimate <= 2 or genus_estimate < genus:
        return
    logger.info(f'Genus estimate is {genus_estimate}')

    K = GF(prime)
    Kx.<x> = FunctionField(K)
    Kxt.<t> = Kx[]
    KX.<X> = K[]
    KXT.<T> = KX[]

    for tr in range(trials):
        phi = t^n
        for i in range(n):
            max_degree  = Cf * (n - i)
            d = random.randint(0, max_degree)
            a = Kx(KX.random_element(degree=(-1, d)))
            phi += t^i * a
        logger.info(f'Testing function field {tr} / {trials}')

        if not phi.is_irreducible():
            logger.debug('Not irreducible')
            continue
        logger.debug('Irreducible, checking genus')

        F.<y> = Kx.extension(phi)

        if USE_MAGMA:
            magma_genus(F)
        if F.genus() != genus:
            logger.debug('Genus too low')
            continue
        logger.debug('Genus okay, checking exact constant field')
        if F.constant_field() is not K:
            logger.debug(f'Exact constant field is {F.constant_field()}, wanted {K}')  
            continue
        logger.debug('Exact constant field correct, looking for degree 1 infinite place')

        infinite_places = F.places_above(Kx.place_infinite())
        if len(infinite_places) <= 1:
            logger.debug(f'Only {len(infinite_places)} infinite places')
            continue
        else:
            logger.debug(f'Good, has {len(infinite_places)} infinite places')
        if any(P.degree() == 1 for P in infinite_places):
            g = F.genus()
            assert g == genus
            if (g, n) in g_n_pair_counts:
                g_n_pair_counts[(g, n)] += 1
            else:
                g_n_pair_counts[(g, n)] = 1
            yield F

def search_for_function_fields(prime, genus, repeat):
    for n in range(3, 10):
        max_Cf = ceil(2 * (genus + n - 1) / (n^2 - n))
        logger.info(f'Searching for degree {n}')

        count = 0
        for Cf in range(1, max_Cf + 1):
            logger.info(f'Searching for n = {n}, Cf <= {Cf}')
            while count < repeat:
                for F in valid_function_fields(prime, n, genus, Cf):
                    print(F.polynomial())
                    count += 1
                    if count >= repeat:
                        break
                if count == 0:
                    break
                elif 0 < count < repeat:
                    logger.info(f'Found {count} / {repeat}, trying again')

            logger.info(g_n_pair_counts)
            if count >= repeat:
                break


if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)
    logger.info(f'Using Magma for genus computations: {USE_MAGMA}')

    # Process command line parameters
    parser = argparse.ArgumentParser(prog='Function field generator for fixed genus')
    parser.add_argument('--repeat', default=5, type=int, help='Number of function fields to generate per parameter set (default: 5)')
    parser.add_argument('--prime-size', default=15, type=int, help='Prime size (default: 15)')
    parser.add_argument('--genus', default=15, type=int, help='Target genus (default: 15)')

    args, unknown = parser.parse_known_args()
    repeat = args.repeat
    prime_exponent_range = args.prime_size
    genus = args.genus

    prime = next_prime(2 ** prime_exponent_range)
    logger.info(f'Prime: {prime}')

    search_for_function_fields(prime, genus, repeat)
