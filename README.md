# bgit

Script for bundling a git repo for offline analysis.

## Usage

```
git-bundle [OPTIONS]
```

### Options

| Option             | Description                                         |
| ------------------ | --------------------------------------------------- |
| `-r, --repo PATH`  | Path to git repository (default: current directory) |
| `-o, --output DIR` | Output directory (default: current directory)       |
| `-s, --submodules` | Include git submodules                              |
| `--no-compress`    | Skip gzip compression                               |
| `-h, --help`       | Show help message                                   |

### Output

`{repo-name}_{YYYY-MM-DD_HH-MM-SS}.bundle[.gz]`

## Example

```bash
# Bundle current repo with default settings
./bgit.sh

# Bundle a specific repo to a custom location
./bgit.sh -r /path/to/repo -o ~/bundles

# Include submodules and skip compression
./bgit.sh -s --no-compress
```
