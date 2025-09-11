# Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and [Keep a Changelog](http://keepachangelog.com/).

## Unreleased

---

### New

### Changes

- Optimize named `*_rfc6570` helpers by removing unnecessary indirection
- Optimize `#rfc6570_routes` and `#rfc6570_route` helpers

### Fixes

- Fix up `RouteSet#to_rfc6570` and `NamedRouteCollection#to_rfc6570`
- Fix up `*_path_rfc6570` to include Rails Engines mount point.

### Breaks

## 3.4.0 - (2025-01-31)

---

### New

- Support for Ruby 3.4

### Changes

- Optimize named `*_rfc6570` helpers by removing unnecessary indirection
- Optimize `#rfc6570_routes` and `#rfc6570_route` helpers

### Fixes

- Fix up `RouteSet#to_rfc6570` and `NamedRouteCollection#to_rfc6570`

## 3.3.0 - (2024-11-25)

---

### New

- Support Rails 8.0 by @jgraichen

## 3.2.0 - (2024-08-24)

---

### New

- Add support for Rails 7.2 by @jgraichen

## 3.1.0 - (2023-11-28)

---

### New

- Add support for Rails 7.1 by @jgraichen

## 3.0.0 - (2023-09-04)

---

### New

- Add Ruby 3.1 and 3.2 to test matrix

### Changes

- Drop Ruby < 2.7 from test matrix
- Drop Rails < 6.1 from test matrix

### Breaks

- Require Ruby 2.7+

## 2.6.0 - (2021-12-16)

---

### New

- Support for Rails 7

## 2.5.0 - (2020-12-13)

---

### New

- Add support for Rails 6.1

## 2.4.0

---

- Add support for Rails 6.0

## 2.3.0

---

- Newly written visitor and formatter to improve performance (#3)
- Nested groups are expanded into a list of groups

## 2.2.0

---

- Add support to Rails 5.2 to gemspec

## 2.1.0

---

- Add emulation for Rails' routing behavior with original script name

## 2.0.0

---

- Add support for Rails 5.1
- Drop support for Rails < 4.2

## 1.1.1

---

- Fix full URL generation to not use `root_url` helper to avoid depending on that and to improve compatibility with e.g. rails engines.

## 1.1.0

---

- Added support for Rails 5.0

## 1.0.0

---

- No changes just bumping version to a production release

## 0.3.0

---

- Added Rails 4.2 support

## 0.2.0

---

- Added `_path_rfc6570` and `_url_rfc6570` helpers (#2)
