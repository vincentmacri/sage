import time

load('testing/curves.sage')

def curves_over_finite_field(p: Integer) -> tuple:
    if p not in FUNCTION_FIELDS:
        return tuple()
    K = GF(p)
    Kx.<x> = FunctionField(K)
    t = polygen(Kx, name='t')
    return Kx, tuple(
            (g, n, m,
             tuple(Kx.extension(sage_eval(poly, locals={'x': x, 't': t}), names='y') for poly in polys))
            for g, n, m, polys in FUNCTION_FIELDS[p]
            )

def time_jacobian(J, iters=100, chains=5):
    group_start = time.time()
    G = J.group()
    group_end = time.time()
    points_gen_start = time.time()

    genus = G._genus
    points = []
    for P in F._places_finite(1):
        points.append(G.point(genus * (P - J.base_divisor())))
        if len(points) >= 2 * chains:
            break

    points_gen_end = time.time()

    # Perform a few calculations to warm things up (populate caches, etc.)
    warmup_start = time.time()
    for P1 in points:
        for P2 in points:
            P1 + P2
    warmup_end = time.time()
    print('Done warmup')

    start_time = time.time()
    for i in range(0, len(points), 2):
        P1 = points[i]
        P2 = points[i + 1]
        assert not P1.is_zero()
        assert not P2.is_zero()
        for _ in range(iters):
            assert not (P1.is_zero() and P2.is_zero())
            P3 = P1 + P2
            P1 = P2
            P2 = P3
    end_time = time.time()
    return (group_end - group_start, points_gen_end - points_gen_start, warmup_end - warmup_start, end_time - start_time)

primes = sorted(FUNCTION_FIELDS.keys(), reverse=True)
print('Primes:', primes);
for p in primes:
    Kx, values = curves_over_finite_field(p)
    print(Kx)
    for g, n, m, function_fields in values:
        if g <= 9:
            continue
        if n != 6:
            continue
        for F in function_fields:
            print('-' * 80)
            print('Testing', F)
            print(f'Genus {g} | Degree {n} | Cf {m} | p {p}')

            # These are somewhat slow one-time computations for each function field 
            # We do them before testing the Jacobian implementation so that values are cached,
            # and the setup time does not count towards the time of the first implementation we test
            setup_start = time.time()
            P1, P2 = F.places_infinite(degree=None)
            assert P1.degree() == 1
            assert P2.degree() == 1
            O = F.maximal_order()
            Oinf = F.maximal_order_infinite()
            O.unit_ideal()
            Oinf.unit_ideal()
            g = F.genus()
            F.constant_field()
            setup_end = time.time()
            print('Setup time:', setup_end - setup_start, 'seconds')
            print()
            A = P2

            print('Timing unique_hess with no caching', end='... ', flush=True)
            linear_unique_hess_no_caching = F.jacobian(model='unique_hess', base_div=A, extra_caching=False)
            print(time_jacobian(linear_unique_hess_no_caching), 'seconds')

            print('Timing unique_hess with caching', end='... ', flush=True)
            linear_unique_hess_caching = F.jacobian(model='unique_hess', base_div=A, extra_caching=True)
            print(time_jacobian(linear_unique_hess_caching), 'seconds')

            print('Timing unique_hess_bs with no caching', end='... ', flush=True)
            binary_unique_hess_no_caching = F.jacobian(model='unique_hess_bs', base_div=A, extra_caching=False)
            print(time_jacobian(binary_unique_hess_no_caching), 'seconds')

            print('Timing unique_hess_bs with caching', end='... ', flush=True)
            binary_unique_hess_caching = F.jacobian(model='unique_hess_bs', base_div=A, extra_caching=True)
            print(time_jacobian(binary_unique_hess_caching), 'seconds')
