"""Compress OSM Overpass output into a compact map-data.json for the FITRIX prototype."""
import json, sys, math

base_path, out_path = sys.argv[1], sys.argv[2]
LAT0, LON0, S = 41.295, 69.255, 1e5
d = json.load(open(base_path))

def q(p):  # lat/lon -> int grid (~1 m)
    return [round((p['lon'] - LON0) * S), round((p['lat'] - LAT0) * S)]

def rdp(pts, eps):
    if len(pts) < 3: return pts
    (x1, y1), (x2, y2) = pts[0], pts[-1]
    dx, dy = x2 - x1, y2 - y1
    n = math.hypot(dx, dy) or 1e-9
    i, dmax = 0, -1
    for k in range(1, len(pts) - 1):
        x0, y0 = pts[k]
        dist = abs(dy * x0 - dx * y0 + x2 * y1 - y2 * x1) / n if (dx or dy) else math.hypot(x0 - x1, y0 - y1)
        if dist > dmax: i, dmax = k, dist
    if dmax > eps:
        return rdp(pts[:i + 1], eps)[:-1] + rdp(pts[i:], eps)
    return [pts[0], pts[-1]]

def merge(segs):  # join outer member segments into rings
    segs = [s[:] for s in segs if len(s) > 1]
    rings = []
    while segs:
        ring = segs.pop(0)
        changed = True
        while changed and ring[0] != ring[-1]:
            changed = False
            for j, s in enumerate(segs):
                if s[0] == ring[-1]: ring += s[1:]
                elif s[-1] == ring[-1]: ring += s[::-1][1:]
                elif s[-1] == ring[0]: ring = s[:-1] + ring
                elif s[0] == ring[0]: ring = s[::-1][:-1] + ring
                else: continue
                segs.pop(j); changed = True; break
        rings.append(ring)
    return rings

ROAD = {'motorway': 'r1', 'trunk': 'r1', 'primary': 'r1', 'motorway_link': 'r2', 'trunk_link': 'r2', 'primary_link': 'r2',
        'secondary': 'r2', 'secondary_link': 'r2', 'tertiary': 'r3', 'tertiary_link': 'r3', 'residential': 'r3',
        'unclassified': 'r3', 'living_street': 'r4', 'pedestrian': 'r4', 'footway': 'foot', 'path': 'foot'}
layers = {k: [] for k in ['green', 'pitch', 'water', 'waterway', 'building', 'rail', 'r4', 'r3', 'r2', 'r1', 'foot']}
labels = []
canal = []

for e in d['elements']:
    t = e.get('tags', {})
    if 'building' in t: layer, eps = 'building', 0.8
    elif 'highway' in t: layer, eps = ROAD.get(t['highway']), 0.6
    elif 'waterway' in t: layer, eps = 'waterway', 0.8
    elif t.get('natural') == 'water': layer, eps = 'water', 0.8
    elif 'railway' in t: layer, eps = 'rail', 0.8
    elif t.get('leisure') == 'pitch': layer, eps = 'pitch', 0.8
    elif t.get('leisure') in ('park', 'garden', 'stadium', 'water_park') or t.get('landuse') in ('grass', 'forest', 'recreation_ground'): layer, eps = 'green', 0.8
    else: continue
    if not layer: continue
    if e['type'] == 'way' and 'geometry' in e:
        shapes = [[q(p) for p in e['geometry']]]
    elif e['type'] == 'relation':
        outers = [[q(p) for p in m['geometry']] for m in e.get('members', []) if m.get('role') == 'outer' and 'geometry' in m]
        shapes = merge(outers)
    else:
        continue
    for pts in shapes:
        pts = rdp(pts, eps)
        if len(pts) < 2: continue
        layers[layer].append([c for p in pts for c in p])
    if layer == 'waterway' and 'Anhor' in (t.get('name:en', '') + t.get('name', '') + t.get('name:uz', '')).replace('Ankhor', 'Anhor').replace('Анхор', 'Anhor'):
        canal.append(shapes[0])

out = {'origin': [LAT0, LON0], 'scale': S, 'layers': layers,
       'canal': [[c for p in s for c in p] for s in canal]}
json.dump(out, open(out_path, 'w'), separators=(',', ':'))
print({k: len(v) for k, v in layers.items()}, 'canal segs', len(canal))
