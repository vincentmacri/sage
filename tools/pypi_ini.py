#!/usr/bin/env python3

"""
Script for generating checksums.ini files from PyPI.
"""

import argparse

import requests

argparse

if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument('package_name')
    parser.add_argument('version')

    args = parser.parse_args()
    name = args.package_name
    version = args.version

    r = requests.get(f'https://pypi.org/pypi/{name}/{version}/json')
    response = r.json()
    info = response['info']
    last_serial = response['last_serial']
    ownership = response['ownership']
    urls = response['urls']
    vulnerabilities = response['vulnerabilities']

    for url in urls:
        tarball = url['filename']
        sha256 = url['digests']['sha256']
        upstream_url = url['url']

        print(f'tarball={tarball}')
        print(f'sha256={sha256}')
        print(f'upstream_url={upstream_url}')
        print()
