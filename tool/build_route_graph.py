"""Build the compact multi-mode routing graph for FITRIX.

Usage:
  python3 tool/build_route_graph.py walk.json metro.json metro_nodes.json assets/data/route-graph.json

Inputs are Overpass API exports (`out body geom`): the street network (walk.json),
metro relations (metro.json) and metro stop nodes (metro_nodes.json). Output: junction
nodes + edges [a, b, meters, mid, class, oneway] plus metro lines with ordered stations.
"""
import json, sys, math, collections

walk_src, metro_src, metro_nodes_src, out_path = sys.argv[1:5]
LAT0, LON0, S = 41.295, 69.255, 1e5
SKIP = {'busway', 'bus_stop'}
CLASSES = ['footway', 'path', 'pedestrian', 'steps', 'cycleway', 'service', 'living_street', 'residential',
           'unclassified', 'tertiary', 'secondary', 'primary', 'trunk', 'link', 'track', 'other']
def cls_of(h):
    if h.endswith('_link'): return CLASSES.index('link')
    return CLASSES.index(h) if h in CLASSES else CLASSES.index('other')

ways = [w for w in json.load(open(walk_src))['elements'] if w['type'] == 'way' and w['tags'].get('highway') not in SKIP]
coord, use = {}, collections.Counter()
for w in ways:
    for nid, g in zip(w['nodes'], w['geometry']):
        coord[nid] = (g['lat'], g['lon'])
    for nid in w['nodes']:
        use[nid] += 1
    use[w['nodes'][0]] += 1; use[w['nodes'][-1]] += 1

def meters(a, b):
    la = math.radians((a[0] + b[0]) / 2)
    return math.hypot((b[0] - a[0]) * 111320, (b[1] - a[1]) * 111320 * math.cos(la))
def q(lat, lon): return [round((lon - LON0) * S), round((lat - LAT0) * S)]

idx, nodes = {}, []
def nid_index(n):
    if n not in idx:
        idx[n] = len(nodes) // 2
        nodes.extend(q(*coord[n]))
    return idx[n]

edges = []
for w in ways:
    t = w['tags']
    ow = t.get('oneway')
    oneway = 1 if ow in ('yes', 'true', '1') or (t.get('junction') in ('roundabout', 'circular') and ow != 'no') else (-1 if ow == '-1' else 0)
    c = cls_of(t['highway'])
    seq = w['nodes']
    start, length, mid = seq[0], 0.0, []
    for prev, cur in zip(seq, seq[1:]):
        length += meters(coord[prev], coord[cur])
        if use[cur] > 1 or cur == seq[-1]:
            if start != cur:
                edges.append([nid_index(start), nid_index(cur), round(length, 1), mid, c, oneway])
            start, length, mid = cur, 0.0, []
        else:
            mid.extend(q(*coord[cur]))

# metro: one relation per line, ordered stops
rels = {r['id']: r for r in json.load(open(metro_src))['elements']}
mnodes = {n['id']: n for n in json.load(open(metro_nodes_src))['elements']}
lines = []
for rid in (2254096, 2255159, 2458135, 11649095):
    r = rels[rid]; t = r['tags']
    stops = []
    for m in r['members']:
        if m['type'] == 'node' and m['role'].startswith('stop') and m['ref'] in mnodes:
            n = mnodes[m['ref']]; nt = n.get('tags', {})
            stops.append([nt.get('name:en') or nt.get('name:uz') or nt.get('name'), round(n['lat'], 5), round(n['lon'], 5)])
    lines.append({'ref': t.get('ref'), 'name': t.get('name:en', t.get('name', '')).split(':')[0], 'colour': t.get('colour'), 'stops': stops})

json.dump({'origin': [LAT0, LON0], 'scale': S, 'classes': CLASSES, 'nodes': nodes, 'edges': edges, 'metro': lines},
          open(out_path, 'w'), separators=(',', ':'))
print('nodes', len(nodes) // 2, 'edges', len(edges), 'oneway', sum(1 for e in edges if e[5]), 'metro lines', len(lines))
