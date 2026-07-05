# Acoustic Sensing

MATLAB implementation for acoustic echo sensing with a 17-23 kHz chirp. The main pipeline loads a stereo recording, applies detrending and band-pass filtering, segments chirp frames by normalized cross-correlation, estimates echo distance responses, and exports time-distance correlation results.

## Repository Layout

- `matlab/Track_PreData_v2.m` - main acoustic sensing pipeline.
- `matlab/splitFrame0313.m` - chirp frame segmentation by template correlation.
- `matlab/Value2index0319.m` - value-to-index helper for time and distance windows.
- `matlab/DrawAnalyse0319.m` - optional visualization and analysis helper.
- `matlab/applyFunction/` - utility functions used by the pipeline.
- `matlab/template/` - small chirp template text files.
- `examples/run_track_predata_v2_example.m` - example launcher.
- `examples/results/test/` - sample output files from one local test run.
- `data/example/` - local input data location, intentionally ignored by git.

## Requirements

- MATLAB R2022a or newer is recommended.
- Signal Processing Toolbox is required for functions such as `firpm`, `filtfilt`, and `hilbert`.

## Run The Example

The raw input recording is not committed because the original `Record.txt` file is about 105 MB. To run locally:

1. Put `Record.txt` or `Record.mat` in `data/example/`.
2. Open MATLAB at the repository root.
3. Run:

```matlab
run examples/run_track_predata_v2_example.m
```

The script writes these outputs to the same data directory:

- `CCvalue.txt`
- `Disvalue.txt`
- `Tvalue.txt`

The expected recording format is the original interleaved stereo sample vector used by `Track_PreData_v2.m`, with the final two values storing start and end timestamps in nanoseconds.

## Notes

- `Track_PreData_v2.m` can also be run directly. By default it reads from `data/example/Record.txt`.
- To use another data directory, set `DfilePath`, `DfileName`, and optionally `output_stereo` before running the script.
- No open-source license has been selected yet.