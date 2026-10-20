#!/usr/bin/env python3
"""Regenerates lib/src/templates/calendar_studio_preset_specs.dart.

Reads the JSON spec in each <section class="preset"> of
docs/design/calendar-studio-theme-presets.html (Vol 1) and -2.html (Vol 2), applies
the per-preset UI fixes below, and writes Dart const data for
CalendarStudioPresetBuilder. Run from the repository root:

    python3 packages/features/calendar_studio/tool/generate_preset_specs.py

Then `dart format` the output and review goldens (flutter test --update-goldens).
"""
import copy
import json
import os
import re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..', '..'))
DOCS = ['docs/design/calendar-studio-theme-presets.html', 'docs/design/calendar-studio-theme-presets-2.html']
OUT = 'packages/features/calendar_studio/lib/src/templates/calendar_studio_preset_specs.dart'

specs = []
for doc in DOCS:
    html = open(os.path.join(ROOT, doc), encoding='utf-8').read()
    for match in re.finditer(r'<script type="application/json" class="spec">(.*?)</script>', html, re.S):
        specs.append(json.loads(match.group(1)))
vols = ['v1', 'v2']
out_path = os.path.join(ROOT, OUT)
by_id = {s['id']: s for s in specs}

def blocks(s, t, **match):
    return [b for b in s['blocks'] if b['type'] == t and all(b.get(k) == v for k, v in match.items())]

def setb(b, bounds): b['bounds'] = bounds

FIX = {}
def fix(pid, label, collection, moods, notes, fn):
    FIX[pid] = (label, collection, moods, notes, fn)

# ---------- Vol 1 ----------
def rose(s):
    s['theme']['holiday'] = '#9A6A1F'; s['theme']['sabbath'] = '#6B4E2A'
    blocks(s, 'text', binding='yearTitle')[0]['style']['color'] = 'holiday'
    blocks(s, 'calendarGrid')[0]['style']['holidayColor'] = 'holiday'
fix('love_relationship', 'Social · square', 'Vol 1', ['Love', 'Calm'], [
    'Holiday gold darkened from #C9A15A for contrast on blush paper; the year uses it too.',
    'Sabbath gets its own colour; legend text is enlarged to a readable minimum.',
], rose)

def hearth(s):
    s['theme']['sabbath'] = '#7A4E1E'
    setb(blocks(s, 'calendarGrid')[0], [0.08, 0.5, 0.84, 0.32])
    lst = blocks(s, 'eventList')[0]; setb(lst, [0.08, 0.835, 0.84, 0.095])
    lst['placeholder'] = ['4 — Family lunch', '12 — School concert', '19 — Grandma visits']
    setb(blocks(s, 'holidayLegend')[0], [0.08, 0.94, 0.84, 0.03])
fix('family', 'Wall · A4 portrait', 'Vol 1', ['Family', 'Warm'], [
    'Grid shortened so the event list fits its title and three rows without clipping.',
    'Legend moved up from the trim edge; the photo frame is drawn.',
], hearth)

def lantern(s):
    s['theme']['sabbath'] = '#8A5A12'
    blocks(s, 'text', binding='monthTitle')[0]['style']['subtitleColor'] = '#CCF7EFE0'
    lst = blocks(s, 'eventList')[0]
    lst['style'].update({'mutedColor': '#B3F7EFE0', 'titleColor': 'accent'})
    lst['placeholder'] = ['4 — Lantern market', '12 — Temple fair', '19 — Full-moon lights', '26 — Offering day']
fix('festival', 'Desk · A4 landscape', 'Vol 1', ['Festive', 'Bright'], [
    'English sub-line and list text on the teal panel use light tints instead of inkMuted.',
    'Sabbath no longer shares the weekend/header teal.',
], lantern)

def panel(s):
    s['theme']['holiday'] = '#D1352B'; s['theme']['sabbath'] = '#7A3FB0'
    setb(blocks(s, 'text', binding='monthTitle')[0], [0.06, 0.075, 0.49, 0.16])
fix('anime', 'Social · square', 'Vol 1', ['Bold', 'Playful'], [
    'Holidays are red instead of yellow-on-white (1.5:1).',
    'Month title fits inside its yellow caption box; the halftone is radial and clipped.',
], panel)

def botanical(s):
    s['theme']['sabbath'] = '#7A5A1F'
    sprig = blocks(s, 'decoration', motif='leafSprig')[1]
    setb(sprig, [0.79, 0.80, 0.15, 0.17]); sprig.pop('rotation', None)
    lst = blocks(s, 'eventList')[0]; setb(lst, [0.08, 0.805, 0.68, 0.09]); lst['kind'] = 'notes'
    setb(blocks(s, 'holidayLegend')[0], [0.08, 0.905, 0.68, 0.03])
    setb(blocks(s, 'text', binding='yearTitle')[0], [0.08, 0.175, 0.4, 0.05])
fix('nature', 'Wall · A4 portrait', 'Vol 1', ['Nature', 'Calm'], [
    'The lower sprig moves to the right so it no longer covers the notes and legend.',
    'Notes are ruled lines; the italic applies to the English line only.',
    'Year moved down so its box no longer overlaps the month title.',
], botanical)

def hollow(s):
    s['theme']['holiday'] = '#E07A9A'; s['theme']['sabbath'] = '#C9C4D9'
    s['blocks'] = [b for b in s['blocks'] if not (b['type'] == 'shape' and b.get('shape') == 'ellipse')]
    s['blocks'].insert(0, {'type': 'decoration', 'motif': 'crescent', 'bounds': [0.70, 0.12, 0.18, 0.1], 'color': 'accent', 'opacity': 1})
    setb(blocks(s, 'holidayLegend')[0], [0.07, 0.8, 0.86, 0.035])
    setb(blocks(s, 'text', binding='custom')[0], [0.2, 0.845, 0.6, 0.04])
    setb(blocks(s, 'text', binding='yearTitle')[0], [0.08, 0.3, 0.84, 0.045])
fix('ghost', 'Story · 9:16', 'Vol 1', ['Night', 'Quiet'], [
    'Crescent is drawn as one shape instead of a paper-coloured mask.',
    'Moon, legend and tagline stay inside the story safe zones (top and bottom 12%).',
    'Holidays are rose so they differ from the lavender weekends.',
    'Year moved down so its box no longer overlaps the month title.',
], hollow)

def tide(s):
    s['theme']['sabbath'] = '#7A4FA0'
    setb(blocks(s, 'shape', shape='rect')[0], [0, 0, 1, 0.28])
    wave = blocks(s, 'decoration', motif='horizonWave')[0]
    setb(wave, [0, 0.265, 1, 0.07]); wave['color'] = 'primary'; wave['accent'] = 'accent'
    blocks(s, 'text', binding='yearTitle')[0]['style']['color'] = '#8FD3CE'
    blocks(s, 'text', binding='monthTitle')[0]['style']['subtitleColor'] = '#CCEAF4F4'
    lst = blocks(s, 'eventList')[0]
    lst['placeholder'] = ['4 — Harbour walk', '12 — Spring tide', '19 — Beach clean-up', '26 — Sunset sail']
    setb(blocks(s, 'holidayLegend')[0], [0.34, 0.905, 0.62, 0.05])
fix('ocean', 'Desk · A4 landscape', 'Vol 1', ['Calm', 'Coastal'], [
    'The navy band ends inside the wave, so the wave is its edge instead of crossing a straight line.',
    'Year on navy uses a light teal; legend moved up from the trim edge.',
], tide)

def woven(s):
    s['monthly'] = False
    s['theme']['sabbath'] = '#6B5A2E'
    weaves = blocks(s, 'decoration', motif='diamondWeave')
    setb(weaves[0], [0.04, 0.02, 0.92, 0.045]); setb(weaves[1], [0.04, 0.935, 0.92, 0.045])
    for w in weaves: w['accent'] = w['color']  # one colour, alternating opacity
    setb(blocks(s, 'text', binding='yearTitle')[0], [0.1, 0.085, 0.8, 0.13])
    month = blocks(s, 'text', binding='monthTitle')[0]
    month['binding'] = 'custom'; month['text'] = 'ပြက္ခဒိန်  ·  Calendar'; month['name'] = 'Subtitle'
    setb(month, [0.1, 0.225, 0.8, 0.05])
    setb(blocks(s, 'shape', shape='line')[0], [0.3, 0.29, 0.4, 0.0015])
    grid = blocks(s, 'calendarGrid')[0]
    grid['type'] = 'annualGrid'; setb(grid, [0.1, 0.32, 0.8, 0.55]); grid['columns'] = 3
    grid.pop('content', None)
    legend = blocks(s, 'holidayLegend')[0]; setb(legend, [0.1, 0.89, 0.8, 0.03])
    legend['items'] = ['holiday']
fix('nations', 'Annual · A3 portrait', 'Vol 1', ['Heritage', 'Formal'], [
    'A true one-sheet annual: twelve labelled mini months instead of a single month.',
    'Year and subtitle no longer overlap; the weave bands sit inside the trim margin.',
    'Mini grids hide lunar labels, so the legend lists holidays only.',
], woven)

# ---------- Vol 2 ----------
def deep(s):
    s['theme'].update({'holiday': '#FF8A7A', 'sabbath': '#9FB7FF'})
    stars = blocks(s, 'decoration', motif='starField')[0]; stars['avoid'] = [0.05, 0.44, 0.9, 0.36]
    planet, ring = blocks(s, 'shape', shape='ellipse')
    setb(planet, [0.62, 0.12, 0.3, 0.17]); setb(ring, [0.56, 0.18, 0.42, 0.05])
    grid = blocks(s, 'calendarGrid')[0]; setb(grid, [0.07, 0.445, 0.86, 0.355])
    grid['style'].update({'weekendColor': 'primary', 'holidayColor': 'holiday'})
    setb(blocks(s, 'holidayLegend')[0], [0.07, 0.81, 0.86, 0.03])
    setb(blocks(s, 'text', binding='custom')[0], [0.2, 0.845, 0.6, 0.035])
    setb(blocks(s, 'text', binding='yearTitle')[0], [0.08, 0.395, 0.84, 0.045])
fix('space', 'Story · 9:16', 'Vol 2', ['Night', 'Dreamy'], [
    'Holidays are coral and weekends violet instead of sharing one colour.',
    'Stars keep clear of the grid; planet, legend and tagline sit inside the story safe zones.',
    'Year moved down so its box no longer overlaps the month title.',
], deep)

def chart(s):
    s['theme'].update({'holiday': '#F08A7A', 'sabbath': '#D4AF6A'})
    setb(blocks(s, 'decoration', motif='zodiacWheel')[0], [0.64, 0.05, 0.3, 0.27])
    blocks(s, 'calendarGrid')[0]['style']['holidayColor'] = 'holiday'
    lst = blocks(s, 'eventList')[0]
    setb(blocks(s, 'text', binding='yearTitle')[0], [0.08, 0.245, 0.4, 0.055])
    lst['placeholder'] = ['Note the full-moon day', 'Plan quiet Sabbath mornings', 'Lucky colour of the month']
fix('astrology', 'Social · square', 'Vol 2', ['Spiritual', 'Night'], [
    'Zodiac wheel made smaller so it no longer draws through the weekday header.',
    'Holidays are coral, distinct from the lavender weekends; legend and notes have a readable minimum size.',
    'Year moved down so its box no longer overlaps the month title.',
], chart)

def monsoon(s):
    s['theme'].update({'holiday': '#B5482F', 'sabbath': '#6E5A8F'})
    s['blocks'] = [b for b in s['blocks'] if not (b['type'] == 'shape' and b.get('shape') == 'line')]
    rain = [(0.06, 0.04), (0.2, 0.11), (0.33, 0.03), (0.45, 0.15), (0.58, 0.06), (0.7, 0.13), (0.82, 0.04), (0.9, 0.16), (0.14, 0.18), (0.62, 0.19)]
    for i, (x, y) in enumerate(rain):
        s['blocks'].insert(1 + i, {'type': 'shape', 'shape': 'line', 'name': 'Rain', 'bounds': [x, y, 0.07, 0.006],
                                   'stroke': 'onPrimary', 'strokeWidth': 1.6, 'opacity': 0.45, 'rotation': 68})
    blocks(s, 'calendarGrid')[0]['style'].update({'holidayColor': 'holiday'})
fix('monsoon', 'Wall · A4 portrait', 'Vol 2', ['Calm', 'Rainy'], [
    'Rain falls as diagonal streaks across the whole band instead of four flat dashes at the top.',
    'Holidays use a darker rust for contrast; sabbath gets its own colour.',
], monsoon)

def pagoda(s):
    s['theme'].update({'holiday': '#B8322A', 'sabbath': '#6B1F23'})
    grid = blocks(s, 'calendarGrid')[0]
    grid['style'].update({'holidayColor': 'holiday', 'weekendColor': '#7A5A1F', 'sabbathColor': 'sabbath'})
    blocks(s, 'text', binding='yearTitle')[0]['style']['color'] = '#8A6A10'
    legend = blocks(s, 'holidayLegend')[0]; legend['items'] = ['sabbath', 'fullMoon', 'newMoon', 'holiday']
fix('pagoda', 'Wall · A4 portrait', 'Vol 2', ['Spiritual', 'Calm'], [
    'Legend leads with Sabbath, as the preset intends.',
    'Holidays are red so they differ from the maroon Sabbath; weekends no longer look disabled.',
    'Year in a deeper gold for contrast.',
], pagoda)

def plain(s):
    s['theme']['sabbath'] = '#3D4A52'
    setb(blocks(s, 'text', binding='yearTitle')[0], [0.05, 0.245, 0.3, 0.055])
fix('minimalist', 'Desk · A4 landscape', 'Vol 2', ['Minimal', 'Calm'], [
    'Holidays stay visible when their colour matches ordinary dates (tinted cell and underline).',
    'Year no longer overlaps the month title.',
], plain)

def sunbeam(s):
    s['theme'].update({'holiday': '#9E2F2F', 'sabbath': '#6B4E2A'})
    setb(blocks(s, 'decoration', motif='sunRays')[0], [0, 0, 0.5, 0.37])
    setb(blocks(s, 'text', binding='monthTitle')[0], [0.08, 0.4, 0.7, 0.15])
    setb(blocks(s, 'text', binding='yearTitle')[0], [0.08, 0.56, 0.4, 0.06])
    setb(blocks(s, 'shape', shape='line')[0], [0.08, 0.635, 0.5, 0.006])
    grid = blocks(s, 'calendarGrid')[0]; setb(grid, [0.08, 0.66, 0.84, 0.25])
    grid['style']['holidayColor'] = 'holiday'
    legend = blocks(s, 'holidayLegend')[0]; setb(legend, [0.08, 0.92, 0.84, 0.035]); legend['items'] = ['holiday']
fix('retro', 'Social · square', 'Vol 2', ['Bold', 'Warm'], [
    'Sun anchored in the canvas corner; title, grid and legend moved up from the bottom edge.',
    'The mini grid hides lunar labels, so the legend lists holidays only; holidays differ from weekends.',
], sunbeam)

def cafe(s):
    s['theme'].update({'holiday': '#A8402F', 'sabbath': '#5C6B3A'})
    grid = blocks(s, 'calendarGrid')[0]
    grid['style'].update({'holidayColor': 'holiday', 'weekendColor': '#8A5530'})
    blocks(s, 'text', binding='monthTitle')[0]['style']['subtitleColor'] = '#CCF5EDE1'
    lst = blocks(s, 'eventList')[0]
    lst['style'].update({'mutedColor': '#B3F5EDE1', 'titleColor': 'accent'})
    lst['placeholder'] = ['4 — Shan tea', '12 — Pour-over morning', '19 — Laphet & tea', '26 — Cold brew']
fix('cafe', 'Desk · A4 landscape', 'Vol 2', ['Cozy', 'Warm'], [
    'Steam rises from a cup; panel text uses light tints instead of unreadable muted brown.',
    'Holidays, weekends and the header each get their own colour.',
], cafe)

def compass(s):
    s['theme'].update({'sabbath': '#7A5A1F'})
    setb(blocks(s, 'text', binding='yearTitle')[0], [0.1, 0.14, 0.8, 0.12])
    setb(blocks(s, 'text', binding='monthTitle')[0], [0.1, 0.27, 0.8, 0.05])
    setb(blocks(s, 'shape', shape='line')[0], [0.32, 0.33, 0.36, 0.0015])
    blocks(s, 'calendarGrid')[0]['style']['weekendColor'] = 'primary'
    setb(blocks(s, 'shape', shape='ellipse')[0], [0.78, 0.865, 0.12, 0.07])
    setb(blocks(s, 'holidayLegend')[0], [0.2, 0.885, 0.56, 0.03])
fix('travel', 'Wall · A3 portrait', 'Vol 2', ['Travel', 'Heritage'], [
    'Labelled as a monthly A3 wall calendar (the mockup called it annual but shows one month).',
    'Stamp ring no longer crosses the legend; more space between year and month.',
    'Weekends are teal so holidays stand out.',
], compass)

def dart(v, indent=0):
    pad = '  ' * indent
    if isinstance(v, dict):
        if not v: return '<String, Object?>{}'
        items = ',\n'.join(f"{pad}  {dart(k)}: {dart(x, indent + 1)}" for k, x in v.items())
        return '<String, Object?>{\n' + items + f',\n{pad}}}'
    if isinstance(v, list):
        if not v: return '<Object?>[]'
        if all(isinstance(x, (int, float)) and not isinstance(x, bool) for x in v):
            return '[' + ', '.join(dart(x) for x in v) + ']'
        items = ',\n'.join(f"{pad}  {dart(x, indent + 1)}" for x in v)
        return '[\n' + items + f',\n{pad}]'
    if isinstance(v, bool): return 'true' if v else 'false'
    if isinstance(v, int): return str(v)
    if isinstance(v, float): return repr(v)
    if v is None: return 'null'
    s = str(v).replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$')
    return f"'{s}'"

out = []
for s in specs:
    if s['id'] not in FIX: continue
    label, collection, moods, notes, fn = FIX[s['id']]
    if collection.replace('Vol ', 'v') not in vols: continue
    s = copy.deepcopy(s)
    fn(s)
    s['label'] = label; s['collection'] = collection; s['moods'] = moods; s['fixes'] = notes
    for b in s['blocks']: b.pop('newMotif', None)
    out.append(s)

header = '''// Round-2 preset specs, derived from docs/design/calendar-studio-theme-presets.html
// (Vol 1) and docs/design/calendar-studio-theme-presets-2.html (Vol 2).
//
// Same shape as the docs' JSON (bounds are 0–1, colours are theme roles or
// literals, font sizes are in the mockup canvas's units). Each spec's "fixes"
// lists where it deliberately differs from the mockup to fix a UI issue.
// Built into templates by CalendarStudioPresetBuilder.

// ignore_for_file: lines_longer_than_80_chars

'''
open(out_path, 'w', encoding='utf-8').write(header + 'const calendarStudioPresetSpecs = <Map<String, Object?>>[\n' +
    ''.join('  ' + dart(s, 1) + ',\n' for s in out) + '];\n')
print('wrote', len(out), 'specs')
