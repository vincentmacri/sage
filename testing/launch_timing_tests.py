import argparse
import logging
import os
import pathlib
import subprocess
import time

from curves import FUNCTION_FIELDS

logger = logging.getLogger(__name__)

def remove_finished_processes(processes):
    for i, p in enumerate(processes):
        ret = p.poll()
        if ret is not None:  # Process is done
            finished = processes.pop(i)
            print(f'Finished: {p.args[3]}_{p.args[5]}')
            if ret == 0:
                logger.info(f'{p.args} finished with return code {ret}')
            else:
                logger.warning(f'{p.args} finished with return code {ret}')
            return True
    return False

if __name__ == '__main__':
    file_path = pathlib.Path(__file__)
    timing_folder = file_path.parent
    sage_path = file_path.parents[1] / 'sage'
    sage_path.resolve()
    timing_tests_path = timing_folder / 'compare_implementations.sage'
    timing_tests_path.resolve()

    logging.basicConfig(level=logging.WARNING)

    parser = argparse.ArgumentParser(prog='Launch timing tests in multiple threads')
    parser.add_argument('--threads', default=4, type=int, help='Number of extra processes to launch (default: 4)')
    parser.add_argument('--chains', default=5, type=int, help='Number of addition chains to time per implementation (default: 5)')
    parser.add_argument('--chain-length', default=100, type=int, help='Length of each addition chain (default: 100)')
    parser.add_argument('--min-g', default=3, type=int, help='Minimum genus to test (default: 3)')

    args, unknown = parser.parse_known_args()
    max_threads = args.threads
    chains = args.chains
    chain_length = args.chain_length
    min_genus = args.min_g

    process_args = []

    for p, g in FUNCTION_FIELDS:
        if g >= min_genus:
            process_args.append([
                sage_path,
                timing_tests_path,
                '--prime', str(p),
                '--genus', str(g),
                '--chains', str(chains),
                '--chain-length', str(chain_length),
                '--save',
                ])
    total_processes = len(process_args)

    print('Launching', total_processes, 'processes')
    exit()
    running_processes = []
    while len(process_args) > 0:
        if len(running_processes) < max_threads:
            args = process_args.pop(0)
            running_processes.append(subprocess.Popen(args))
        if remove_finished_processes(running_processes):
            print(f'Remaining: {len(running_processes) + len(process_args)}')
        time.sleep(1)
    print('All processes started')
    while len(running_processes) > 0:
        remove_finished_processes(running_processes)
        time.sleep(5)
    print('Done')
