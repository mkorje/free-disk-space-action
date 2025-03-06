# free-disk-space-action

A configurable action to free disk space on Ubuntu runners.

An example of the results when all options are enabled is below:

```
Free space before: 22GiB
Haskell: Freed 6.4GiB in 2s
Android SDK: Freed 8.8GiB in 22s
Tool cache: Freed 7.9GiB in 3s
Free space after: 45GiB
Total space freed: 23GiB
```

## Details

Targets the `ubuntu-latest` runner image.
To find out what there is to remove on the image, see the [source of truth](https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md).

## Inputs

See [action.yml](action.yml) for documentation of the available inputs.

## Usage

### Minimal example

```yaml
name: Examples
on: push
jobs:
  minimal:
    runs-on: ubuntu-latest
    steps:
      - uses: mkorje/free-disk-space-action@v1
```
