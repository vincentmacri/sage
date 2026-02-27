import csv
import logging
import os

DATA_FOLDER = 'timing_data'

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
            else:
                assert fieldnames == reader.fieldnames
            all_rows.extend(reader)
    output_file = 'merged_timing_data.csv'
    with open(output_file, 'w', newline='') as output_csv:
        writer = csv.DictWriter(output_csv, fieldnames=fieldnames, dialect='unix')
        writer.writeheader()
        writer.writerows(all_rows)
    print('Done')
