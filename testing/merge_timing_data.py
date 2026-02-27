import csv
import logging
import os

DATA_FOLDER = 'timing_data'
IMPLEMENTATION_NAMES = ('linear_no_caching', 'linear_caching', 'binary_no_caching', 'binary_caching')
NANOSECONDS_PER_MILLISECOND = 10**6

logger = logging.getLogger(__name__)


if __name__ == '__main__':
    all_rows = []
    for file_name in os.listdir(DATA_FOLDER):
        file = f'{DATA_FOLDER}/{file_name}'

        fieldnames = None
        with open(file, newline='') as csv_file:
            reader = csv.DictReader(csv_file, dialect='unix')
            if fieldnames is None:
                fieldnames = reader.fieldnames
                for impl in IMPLEMENTATION_NAMES:
                    fieldnames.append(f'{impl}_milliseconds_per_addition')
                    fieldnames.append(f'{impl}_additions_per_second')
            else:
                assert fieldnames == reader.fieldnames
            for row in reader:
                for impl in IMPLEMENTATION_NAMES:
                    additions = int(row['chains']) * int(row['chain_length'])
                    assert additions == 50000
                    milliseconds_per_addition = (int(row[f'{impl}_addition_chains']) / additions) / NANOSECONDS_PER_MILLISECOND
                    row[f'{impl}_milliseconds_per_addition'] = milliseconds_per_addition
                    row[f'{impl}_additions_per_second'] = 1000 / milliseconds_per_addition

                all_rows.append(row)

    output_file = 'merged_timing_data.csv'
    with open(output_file, 'w', newline='') as output_csv:
        writer = csv.DictWriter(output_csv, fieldnames=fieldnames, dialect='unix')
        writer.writeheader()
        writer.writerows(all_rows)
    print('Done')
