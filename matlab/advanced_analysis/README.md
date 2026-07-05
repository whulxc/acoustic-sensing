# Optional Advanced Analysis

The default public example stops at the large-scale time-distance CC maps:

- processed display: `大尺度时间-距离的CC图-处理`
- unprocessed display: `大尺度时间-距离的CC图-不处理`

`plot_time_distance_analysis.m` keeps the older downstream exploration code as an optional module. It is useful when the next step is to analyze motion or periodic activity from the CC map.

The optional stages are:

- large-scale distance-frequency power map;
- local time-distance CC map for a selected distance window;
- ridge extraction and local peak selection;
- local distance-frequency power map.

This module is intentionally not called by `run_example.m`, so the first-release example stays focused on reproducible CC-map generation.
