# XML-XORT Library

## Overview
This directory contains the XML-XORT library (version 0.007) required for the ARGS metrics script (`update_report_args.pl`).

XORT (XML Object-Relational Transformation) is a Perl library developed by FlyBase for converting between XML and relational database formats, particularly for Chado databases.

## Security Note
**All database credentials and sensitive configuration files have been removed from this library.**

Only the `ddl.properties` file (database schema definitions) is retained in the `conf/` directory, as it contains no sensitive data and is required for the ARGS metrics script to function.

## Original Source
This library was copied from: `/users/zhou/work/XML-XORT-0.007` on the Conrad server.

## Usage
The library is installed to `/usr/local/lib/XML-XORT-0.007` in the Docker container and is accessed by the ARGS metrics script via:
```perl
use lib '/usr/local/lib/XML-XORT-0.007/xort';
```

## Files Removed
The following types of files were removed to prevent credential exposure:
- `*.properties` files (except `ddl.properties`) - contained database credentials
- Backup configuration files
- Development/test configuration files

## Dependencies
See the main Dockerfile for Perl module dependencies installed via CPAN.
