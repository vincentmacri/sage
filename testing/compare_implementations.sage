import argparse
import csv
from dataclasses import dataclass
import itertools
import time
import logging
import os
from typing import Any

from curves import FUNCTION_FIELDS

logger = logging.getLogger(__name__)


@dataclass
class ImplementationTimingResults:
    """Hold timing results for a function field for a specific implementation."""
    implementation: str
    point_initialization: int = 0
    warmup: int = 0
    addition_chains: int = 0

    def timing_data(self) -> dict[str, int]:
        return {
                f'{self.implementation}_point_initialization': self.point_initialization,
                f'{self.implementation}_warmup': self.warmup,
                f'{self.implementation}_addition_chains': self.addition_chains,
                }

@dataclass
class FunctionFieldTimingResults:
    """Hold timing results for a function field."""
    function_field: Any
    prime: int
    Cf: int
    chains: int
    chain_length: int
    setup_time: int

    linear_no_caching_results: ImplementationTimingResults | None = None
    linear_caching_results: ImplementationTimingResults | None = None
    binary_no_caching_results: ImplementationTimingResults | None = None
    binary_caching_results: ImplementationTimingResults | None = None

    def csv_row(self):
        result = dict()

        result['prime'] = prime
        result['genus'] = self.function_field.genus()
        result['degree'] = self.function_field.degree()
        result['Cf'] = self.Cf
        result['function_field'] = str(self.function_field.polynomial())
        result['chains'] = self.chains
        result['chain_length'] = self.chain_length
        result['setup_time'] = self.setup_time

        result.update(self.linear_no_caching_results.timing_data())
        result.update(self.linear_caching_results.timing_data())
        result.update(self.binary_no_caching_results.timing_data())
        result.update(self.binary_caching_results.timing_data())
        return result


def curves_over_finite_field(p, g) -> tuple:
    if (p, g) not in FUNCTION_FIELDS:
        return tuple()
    K = GF(p)
    Kx = FunctionField(K, names='x')
    x = Kx.gen()
    t = polygen(Kx, name='t')
    return Kx, tuple(
            (n, m,
             tuple(Kx.extension(sage_eval(poly, locals={'x': x, 't': t}), names='y') for poly in polys))
            for n, m, polys in FUNCTION_FIELDS[(p, g)]
            )

def time_jacobian(J, name, chain_start_divisor_pairs, chain_length):
    G = J.group()
    point_init_start = time.process_time_ns()
    chain_start_pairs = []
    for P1, P2 in chain_start_divisor_pairs:
        chain_start_pairs.append((G.point(P1), G.point(P2)))
    point_init_end = time.process_time_ns()

    # Perform a few calculations to warm things up (populate caches, etc.)
    warmup_start = time.process_time_ns()
    for P1, P2 in chain_start_pairs:
        for Q1, Q2 in chain_start_pairs:
            P1 + Q1
            P1 + Q2
            P2 + Q1
            P2 + Q2
    warmup_end = time.process_time_ns()

    addition_chains_start_time = time.process_time_ns()
    for i in range(len(chain_start_pairs)):
        P1, P2 = chain_start_pairs[i]
        for _ in range(chain_length):
            P3 = P1 + P2
            P1 = P2
            P2 = P3
    addition_chains_end_time = time.process_time_ns()

    results = ImplementationTimingResults(
            name,
            point_init_end - point_init_start,
            warmup_end - warmup_start,
            addition_chains_end_time - addition_chains_start_time
            )
    return results

def time_implementations(prime, g, chains, chain_length):
    all_timing_results = []
    Kx, values = curves_over_finite_field(prime, g)
    for n, m, function_fields in values:
        for F in function_fields:
            logger.info('-' * 80)
            logger.info(f'Testing {F}')
            logger.info(f'Genus {g} | Degree {n} | Cf {m}')

            # These are somewhat slow one-time computations for each function field 
            # We do them before testing the Jacobian implementation so that values are cached,
            # and the setup time does not count towards the time of the first implementation we test
            # Some of them are also sanity tests, as our generate_curves.sage script specifically generates
            # curves where all these tests should pass.
            setup_start = time.process_time_ns()
            P1, P2 = F.places_infinite(degree=None)
            assert P1.degree() == 1
            assert P2.degree() == 1
            O = F.maximal_order()
            Oinf = F.maximal_order_infinite()
            O.unit_ideal()
            Oinf.unit_ideal()
            assert g == F.genus()
            assert F.constant_field() == GF(prime)
            A = P2

            logger.info('Creating starting points...')
            # Create some starting points to use for the addition chains
            starting_points = []
            for P in F._places_finite(1):
                starting_points.append(g * (P - A))
                if len(starting_points) >= 2 * chains:
                    break

            if len(starting_points) < 2 * chains:  # Sometimes we can't easily find enough easy-to-construct points over small prime fields
                divisor_group = F.divisor_group()
                for E in divisor_group.effective_divisors(max_degree=g):
                    D = E - E.degree() * A.divisor()
                    if D not in starting_points:
                        starting_points.append(D)
                        if len(starting_points) >= 2 * chains:
                            break

            starting_pairs = list(itertools.batched(starting_points, 2))
            assert len(starting_pairs[-1]) == 2
            assert len(starting_pairs) == chains
            logger.info('Done')
            setup_end = time.process_time_ns()

            function_field_results = FunctionFieldTimingResults(
                    F,
                    prime,
                    m,
                    chains,
                    chain_length,
                    setup_end - setup_start
                    )

            logger.debug('Timing unique_hess with no caching...')
            linear_no_caching = F.jacobian(model='unique_hess', base_div=A, extra_caching=False)
            function_field_results.linear_no_caching_results = time_jacobian(linear_no_caching, 'linear_no_caching', starting_pairs, chain_length)
            logger.debug('Done')

            logger.debug('Timing unique_hess with caching...')
            linear_caching = F.jacobian(model='unique_hess', base_div=A, extra_caching=True)
            function_field_results.linear_caching_results = time_jacobian(linear_caching, 'linear_caching', starting_pairs, chain_length)
            logger.debug('Done')

            logger.debug('Timing unique_hess_bs with no caching...')
            binary_no_caching = F.jacobian(model='unique_hess_bs', base_div=A, extra_caching=False)
            function_field_results.binary_no_caching_results = time_jacobian(binary_no_caching, 'binary_no_caching', starting_pairs, chain_length)
            logger.debug('Done')

            logger.debug('Timing unique_hess_bs with caching...')
            binary_caching = F.jacobian(model='unique_hess_bs', base_div=A, extra_caching=True)
            function_field_results.binary_caching_results = time_jacobian(binary_caching, 'binary_caching', starting_pairs, chain_length)
            logger.debug('Done')

            logger.info('Done timing curve')
            all_timing_results.append(function_field_results)
    return all_timing_results

if __name__ == '__main__':
    logging.basicConfig(level=logging.WARNING)
    # Process command line parameters
    parser = argparse.ArgumentParser(prog='Jacobian implementation timing comparison')
    parser.add_argument('--prime', default=11, type=int, help='Prime to test for, there must be curves over this prime field in curves.py (default: 11)')
    parser.add_argument('--genus', default=3, type=int, help='Genus to test over (default: 3)')
    parser.add_argument('--chains', default=5, type=int, help='Number of addition chains to time per implementation (default: 5)')
    parser.add_argument('--chain-length', default=100, type=int, help='Length of each addition chain (default: 100)')
    parser.add_argument('--save', action=argparse.BooleanOptionalAction, default=False, help='Whether or not to save timing results to a CSV file')

    args, unknown = parser.parse_known_args()
    prime = Integer(args.prime)
    chains = args.chains
    chain_length = args.chain_length
    genus = args.genus
    save_results = args.save

    results = time_implementations(prime, genus, chains, chain_length)

    if not save_results:
        logger.info('Done timing, printing results...')
        print('=' * 80)
        print(results)
        print('=' * 80)
        exit()

    output_folder = f'{os.path.dirname(os.path.realpath(__file__))}/timing_data'
    os.makedirs(output_folder, exist_ok=True)
    output_file = f'{output_folder}/timing_{prime}_{genus}.csv'
    logger.info(f'Done timing, saving results to {output_file}...')

    field_names = list(results[0].csv_row())

    with open(output_file, 'w', newline='') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=field_names, dialect='unix')
        writer.writeheader()
        for function_field_result in results:
            writer.writerow(function_field_result.csv_row())
    print(f'Results saved to {output_file}')
