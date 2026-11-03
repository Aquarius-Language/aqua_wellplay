# Examples

The gallery behind File › Examples. Each folder is a group (`NN Name`: the number orders the groups and is not shown);
each `.ipynb` is a notebook whose `metadata.wellplay` names it:

```json
"wellplay": {"version": 1, "title": "Collatz Rollercoaster", "description": "One sentence for the card.", "icon": "chevronUp",
             "order": 50, "interactive": false}
```

`icon` is a SaturnUI icon name; `order` (default 50) sorts within a group before names; `interactive: true` marks a
notebook that opens a window (the example test skips it). Save examples without outputs. `tests/run.ps1` runs every
non-interactive example and fails on an error or an example that shows nothing.
