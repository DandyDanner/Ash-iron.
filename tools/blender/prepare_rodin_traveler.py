"""Prepare one figure from Dallon's Rodin (Hyper3D) traveler generation as a playable traveler export. Blender 5.2.
Run: blender --background --factory-startup --python tools/blender/prepare_rodin_traveler.py -- /path/to/base.glb [--figure=0] [--height=2.06] [--budget=90000] [--slug=willow_scout] [--yaw=0]
Rodin turns a character sheet into several fused figures; --figure picks one by left-to-right order. The download stays untouched.
Outputs: assets/characters/<slug>.glb bound to the game's 14-joint TravelerRig (joint pivots measured from the figure itself),
art/blender/rodin_import/<slug>.blend, art/blender/rodin_import/<slug>_report.json and Cycles review renders in docs/art/rodin-traveler/.
Colours come from the turnaround sheet the figure was generated from (--sheet=<png>, front/side/back on a plain background),
projected onto the mesh by facing direction; where the sheet gives nothing, the Willow palette by region fills in.
"""
import bpy, bmesh, sys, json, math
import numpy as np
from pathlib import Path
from mathutils import Vector

R = Path(__file__).resolve().parents[2]
ARGS = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
SOURCE = Path(next((a for a in ARGS if not a.startswith('--')), '/Users/dallonanderson/Downloads/base.glb'))

def option(name, default):
	raw = next((a.split('=', 1)[1] for a in ARGS if a.startswith('--' + name + '=')), None)
	return type(default)(raw) if raw is not None else default

FIGURE = option('figure', 0)
HEIGHT = option('height', 2.06)
BUDGET = option('budget', 90000)
SLUG = option('slug', 'willow_scout')
YAW = option('yaw', 0.0)
SHEET = Path(option('sheet', '/Users/dallonanderson/Downloads/Willow Scout.png'))
SASH_Z = option('sash', 1.13)  # height of the figure's waist wrap, the one band Rodin placed lower than the drawing
SIZE = 1.14  # AuthoredTraveler size for design 0: SCALES[0] * 1.14
OUT = R / 'art/blender/rodin_import'; OUT.mkdir(parents=True, exist_ok=True)
ASSET = R / 'assets/characters'; ASSET.mkdir(parents=True, exist_ok=True)
REVIEW = R / 'docs/art/rodin-traveler'; REVIEW.mkdir(parents=True, exist_ok=True)

# Reference joint heights shared with authored_traveler.gd (Blender Z-up metres, design 0).
Z = {'body': .97 * SIZE, 'torso': 1.0 * SIZE, 'head': 1.53 * SIZE, 'cape': 1.50 * SIZE, 'hip': .96 * SIZE, 'knee': .54 * SIZE,
	'shoulder': 1.442 * SIZE, 'elbow': 1.188 * SIZE, 'hand': .931 * SIZE}

def smooth(t):
	t = np.clip(t, 0, 1)
	return t * t * (3 - 2 * t)

def linear(hex_code):
	c = [int(hex_code[i:i + 2], 16) / 255 for i in (0, 2, 4)]
	return tuple(((v + .055) / 1.055) ** 2.4 if v > .04045 else v / 12.92 for v in c)

# ---------------------------------------------------------------- import and isolate one figure
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
obj = next(o for o in bpy.context.scene.objects if o.type == 'MESH')
bpy.context.view_layer.objects.active = obj; obj.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
source_triangles = sum(len(p.vertices) - 2 for p in obj.data.polygons)
bm = bmesh.new(); bm.from_mesh(obj.data)
bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=1e-6)
layer = bm.verts.layers.int.new('figure')
seen = set(); parts = []
for v in bm.verts:
	if v in seen: continue
	stack = [v]; seen.add(v); group = []
	while stack:
		q = stack.pop(); group.append(q)
		for e in q.link_edges:
			w = e.other_vert(q)
			if w not in seen: seen.add(w); stack.append(w)
	parts.append(group)
parts.sort(key=len, reverse=True)
figures = [p for p in parts if len(p) > .05 * len(bm.verts)] or parts[:1]
seeds = sorted(sum((v.co.x for v in p), 0.0) / len(p) for p in figures)
if FIGURE >= len(seeds): raise ValueError('Source has %d figures; --figure=%d is out of range' % (len(seeds), FIGURE))
for p in parts:
	cx = sum((v.co.x for v in p), 0.0) / len(p)
	nearest = min(range(len(seeds)), key=lambda k: abs(seeds[k] - cx))
	for v in p: v[layer] = nearest
bmesh.ops.delete(bm, geom=[v for v in bm.verts if v[layer] != FIGURE], context='VERTS')
bm.to_mesh(obj.data); bm.free()
me = obj.data
print('FIGURES', len(seeds), 'chosen', FIGURE, 'vertices', len(me.vertices), flush=True)

# ---------------------------------------------------------------- orient, ground, centre, scale
P = np.empty(len(me.vertices) * 3, dtype=np.float32); me.vertices.foreach_get('co', P); P = P.reshape(-1, 3).astype(np.float64)
if YAW:
	a = math.radians(YAW); c, s = math.cos(a), math.sin(a)
	P[:, 0], P[:, 1] = c * P[:, 0] - s * P[:, 1], s * P[:, 0] + c * P[:, 1]
P[:, 2] -= P[:, 2].min()
h0 = P[:, 2].max()
legs = P[(P[:, 2] > .25 * h0) & (P[:, 2] < .35 * h0)]
P[:, 0] -= np.median(legs[:, 0])
waist = P[(P[:, 2] > .55 * h0) & (P[:, 2] < .62 * h0) & (np.abs(P[:, 0]) < .08 * h0)]
P[:, 1] -= np.median(waist[:, 1])
crown = P[(np.abs(P[:, 0]) < .07 * h0) & (np.abs(P[:, 1]) < .06 * h0)]
P *= HEIGHT / crown[:, 2].max()
me.vertices.foreach_set('co', P.ravel().astype(np.float32)); me.update()
del legs, waist, crown

# ---------------------------------------------------------------- polygon budget
tri = sum(len(p.vertices) - 2 for p in me.polygons)
if tri > BUDGET:
	dec = obj.modifiers.new('Game triangle budget', 'DECIMATE'); dec.ratio = BUDGET / tri
	bpy.ops.object.modifier_apply(modifier=dec.name); me = obj.data
me.polygons.foreach_set('use_smooth', [True] * len(me.polygons))
P = np.empty(len(me.vertices) * 3, dtype=np.float32); me.vertices.foreach_get('co', P); P = P.reshape(-1, 3).astype(np.float64)
X, Y, Zc = P[:, 0], P[:, 1], P[:, 2]

# ---------------------------------------------------------------- measure the figure's own joints
def slice_clusters(z, half=.012, cell=.015):
	"""2D connected blobs (grid flood fill) of the vertices in a thin horizontal band."""
	idx = np.nonzero(np.abs(Zc - z) < half)[0]
	if len(idx) == 0: return []
	ij = np.floor(P[idx, :2] / cell).astype(int)
	cells = {}
	for k, key in enumerate(map(tuple, ij)): cells.setdefault(key, []).append(idx[k])
	label = {}; blobs = []
	for c in cells:
		if c in label: continue
		stack = [c]; label[c] = len(blobs); members = []
		while stack:
			q = stack.pop(); members.extend(cells[q])
			for di in (-1, 0, 1):
				for dj in (-1, 0, 1):
					n = (q[0] + di, q[1] + dj)
					if n in cells and n not in label: label[n] = len(blobs); stack.append(n)
		pts = P[members]
		blobs.append({'idx': np.array(members), 'cx': float(pts[:, 0].mean()), 'cy': float(pts[:, 1].mean()), 'maxabs': float(np.abs(pts[:, 0]).max()), 'n': len(members)})
	return sorted(blobs, key=lambda b: b['cx'])

def band_blobs(z_lo, z_hi, step=.012):
	for z in np.arange(z_lo, z_hi, step):
		yield z, slice_clusters(z)

def mirrored(left, right):
	if not left: return None
	l = np.median(np.array(left)[:, :2], axis=0); r = np.median(np.array(right)[:, :2], axis=0)
	return {'x': float((abs(l[0]) + abs(r[0])) / 2), 'y': float((l[1] + r[1]) / 2), 'samples': len(left)}

def pair_of_largest(z_lo, z_hi):
	"""Left/right centres of the two biggest blobs in each band: the legs, never a hanging sash or hand."""
	left, right = [], []
	for z, blobs in band_blobs(z_lo, z_hi):
		big = sorted(sorted(blobs, key=lambda b: -b['n'])[:2], key=lambda b: b['cx'])
		if len(big) == 2 and big[0]['cx'] < -.03 and big[1]['cx'] > .03:
			left.append((big[0]['cx'], big[0]['cy'])); right.append((big[1]['cx'], big[1]['cy']))
	return mirrored(left, right)

def outer_pair(z_lo, z_hi, min_x):
	"""Left/right outermost blobs (hands, bare forearms) in the bands where they separate from the body."""
	left, right = [], []
	for z, blobs in band_blobs(z_lo, z_hi):
		if len(blobs) >= 3 and blobs[0]['cx'] < -min_x and blobs[-1]['cx'] > min_x and blobs[0]['n'] > 12 and blobs[-1]['n'] > 12:
			left.append((blobs[0]['cx'], blobs[0]['cy'], z)); right.append((blobs[-1]['cx'], blobs[-1]['cy'], z))
	return left, right

def silhouette(z):
	band = P[np.abs(Zc - z) < .012]
	return float(np.abs(band[:, 0]).max()) if len(band) else .3

knees = pair_of_largest(Z['knee'] - .06, Z['knee'] + .06) or {'x': .10 * SIZE, 'y': -.007 * SIZE, 'samples': 0}
thighs = pair_of_largest(.68, .80) or {'x': .10 * SIZE, 'y': 0.0, 'samples': 0}
def outer_shell(z, depth, half=.015):
	"""Centre of the outermost band of each side: the arm, whether or not it touches a pouch or the cape hem."""
	band = P[np.abs(Zc - z) < half]
	if len(band) < 20: return None
	right = band[band[:, 0] > band[:, 0].max() - depth]; left = band[band[:, 0] < band[:, 0].min() + depth]
	return {'x': float((right[:, 0].mean() - left[:, 0].mean()) / 2), 'y': float((right[:, 1].mean() + left[:, 1].mean()) / 2), 'samples': int(len(left) + len(right))}

hands = outer_shell(Z['hand'], .09) or {'x': .310 * SIZE, 'y': -.018 * SIZE, 'samples': 0}
elbows = outer_shell(Z['elbow'], .10) or {'x': .267 * SIZE, 'y': -.005 * SIZE, 'samples': 0}
upper = outer_shell(Z['shoulder'], .18)
# The shoulder pivot sits about 9 cm inside the shoulder silhouette, within human proportions.
shoulder = {'x': float(min(max(.15, silhouette(Z['shoulder']) - .09), .25)), 'y': upper['y'] if upper else 0.0, 'samples': upper['samples'] if upper else 0}
neck = P[(np.abs(Zc - (Z['head'] - .04)) < .015) & (np.abs(X) < .12) & (np.abs(Y) < .12)]
head_y = float(np.median(neck[:, 1])) if len(neck) else 0.0
points = {'Body': (0, 0, Z['body']), 'Torso': (0, 0, Z['torso']), 'Head': (0, head_y, Z['head']), 'Cape': (0, head_y, Z['cape'])}
for side, sx in (('Left', -1), ('Right', 1)):
	points[side + 'Leg'] = (sx * thighs['x'], thighs['y'], Z['hip'])
	points[side + 'Knee'] = (sx * knees['x'], knees['y'], Z['knee'])
	points[side + 'Arm'] = (sx * shoulder['x'], shoulder['y'], Z['shoulder'])
	points[side + 'Elbow'] = (sx * elbows['x'], elbows['y'], Z['elbow'])
	points[side + 'Hand'] = (sx * hands['x'], hands['y'], Z['hand'])
print('LANDMARKS', json.dumps({'hands': hands, 'elbows': elbows, 'shoulder': shoulder, 'knees': knees, 'thighs': thighs, 'head_y': head_y}), flush=True)

# ---------------------------------------------------------------- region masks
arm_mask = np.zeros(len(P), dtype=bool)
for z in np.arange(Z['hand'] - .10, 1.70, .024):
	blobs = slice_clusters(z)
	band = np.abs(Zc - z) < .012
	separated = len(blobs) >= 3 and blobs[0]['cx'] < -.2 and blobs[-1]['cx'] > .2
	if separated:
		arm_mask[blobs[0]['idx']] = True; arm_mask[blobs[-1]['idx']] = True
	else:
		limit = shoulder['x'] + .03 if z > 1.38 else .24
		arm_mask |= band & (np.abs(X) > limit)
skull = P[(Zc > 1.80) & (Zc < 1.95) & (np.abs(X) < .15) & (np.abs(Y) < .25)]
head_centre_y = float(np.median(skull[:, 1])) if len(skull) else head_y
head_centre_x = float(np.median(skull[:, 0])) if len(skull) else 0.0
head_radius = np.sqrt(X ** 2 + (Y - head_centre_y) ** 2)
head_mask = (Zc > Z['head'] - .10) & (head_radius < .20) & ~arm_mask
# Bow, quiver and arrows: either well behind the back, or a small separate blob behind the body in their band.
back_blob = np.zeros(len(P), dtype=bool)
for z, blobs in band_blobs(.85, HEIGHT, .024):
	if not blobs: continue
	biggest = max(b['n'] for b in blobs)
	for b in blobs:
		if b['cy'] > .05 and b['n'] < .3 * biggest: back_blob[b['idx']] = True
arrows = (Zc > 1.72) & (Y > .06) & (np.abs(X) > .10)
gear_mask = (((Y > .19) & (Zc > 1.05)) | back_blob | arrows) & (Zc > .85) & ~head_mask & ~arm_mask
print('MASKS arm=%d head=%d gear=%d of %d' % (arm_mask.sum(), head_mask.sum(), gear_mask.sum(), len(P)), flush=True)

# ---------------------------------------------------------------- skin weights (four influences, normalised)
side_names = np.where(X < 0, 'Left', 'Right')
hand_w = 1 - smooth((Zc - (Z['hand'] - .03)) / .07)
elbow_w = smooth((Zc - (Z['elbow'] - .045)) / .097)
shoulder_w = smooth((Zc - (Z['shoulder'] - .048)) / .063)
knee_w = smooth((Zc - (Z['knee'] - .057)) / .114)
hip_w = smooth((Zc - (Z['hip'] - .09)) / .137)
torso_w = smooth((Zc - 1.17) / .10)
neck_w = smooth((Zc - (Z['head'] - .068)) / .084)
groups = {name: obj.vertex_groups.new(name=name) for name in points}
influences = []
for i in range(len(P)):
	side = side_names[i]; w = {}
	if head_mask[i]:
		w = {'Head': neck_w[i], 'Torso': 1 - neck_w[i]}
	elif arm_mask[i]:
		h, e, s = hand_w[i], elbow_w[i], shoulder_w[i]
		w = {side + 'Hand': h, side + 'Elbow': (1 - h) * (1 - e), side + 'Arm': (1 - h) * e * (1 - s), 'Torso': (1 - h) * e * s}
	elif gear_mask[i]:
		w = {'Torso': 1.0}
	else:
		k, hp, t = knee_w[i], hip_w[i], torso_w[i]
		body = k * hp
		w = {side + 'Knee': 1 - k, side + 'Leg': k * (1 - hp), 'Body': body * (1 - t), 'Torso': body * t}
	active = sorted([(n, float(v)) for n, v in w.items() if v > 1e-4], key=lambda p: p[1], reverse=True)[:4]
	total = sum(v for n, v in active)
	for n, v in active: groups[n].add([i], v / total, 'REPLACE')
	influences.append(len(active))

# ---------------------------------------------------------------- Willow palette by region, as linear vertex colours
skin = (.48, .285, .16); sage = linear('70865c'); cream = linear('e9ddbc'); sand = linear('baa987'); leather = linear('79583c')
teal = linear('3c6665'); hair = linear('392b27'); wood = linear('6e4f33')
colour = np.empty((len(P), 3)); category = np.zeros(len(P), dtype=int)  # 0 fabric, 1 skin, 2 hair
for i in range(len(P)):
	x, y, z = P[i]
	if head_mask[i]:
		if z > 1.945 or (z > 1.78 and y > head_centre_y + .015) or (z > 1.83 and abs(x - head_centre_x) > .10): colour[i], category[i] = hair, 2
		elif z < Z['head'] and y > head_centre_y + .06: colour[i] = sage
		else: colour[i], category[i] = skin, 1
	elif arm_mask[i]:
		if z > 1.40: colour[i] = sage
		elif z > 1.28: colour[i] = cream
		elif z > 1.09: colour[i], category[i] = skin, 1
		elif z > 1.055: colour[i] = leather
		else: colour[i], category[i] = skin, 1
	elif gear_mask[i]:
		colour[i] = wood if x > .05 else leather
	elif z > 1.42: colour[i] = sage
	elif z > 1.20: colour[i] = cream
	elif z > 1.06: colour[i] = teal
	elif z > .31: colour[i] = sand
	else: colour[i] = leather
# ---------------------------------------------------------------- project the turnaround sheet onto the figure
def load_sheet(path):
	"""sRGB float image (top row first) and a foreground mask of the drawn figures."""
	img = bpy.data.images.load(str(path)); img.colorspace_settings.name = 'Non-Color'
	w, h = img.size; px = np.empty(w * h * 4, dtype=np.float32); img.pixels.foreach_get(px)
	rgb = px.reshape(h, w, 4)[::-1, :, :3].copy()
	border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]]); bg = np.median(border, axis=0)
	fg = np.abs(rgb - bg).max(axis=2) > .10
	fg[: int(.06 * h)] = False; fg[int(.93 * h):] = False  # title and labels
	return rgb, fg

def figure_boxes(fg):
	cols = np.nonzero(fg.any(axis=0))[0]; boxes = []; start = cols[0]; prev = cols[0]
	for c in cols[1:]:
		if c - prev > 24: boxes.append((start, prev)); start = c
		prev = c
	boxes.append((start, prev))
	boxes = [b for b in boxes if b[1] - b[0] > .08 * fg.shape[1]]
	out = []
	for x0, x1 in boxes:
		rows = np.nonzero(fg[:, x0:x1 + 1].any(axis=1))[0]; out.append((x0, x1, rows[0], rows[-1]))
	return out

def grow(rgb, mask, iters):
	"""Spread figure colours a few pixels into the background so silhouette misfits sample cloth, not paper."""
	rgb = rgb.copy(); mask = mask.copy()
	for _ in range(iters):
		acc = np.zeros_like(rgb); cnt = np.zeros(mask.shape, dtype=np.float32)
		for dy in (-1, 0, 1):
			for dx in (-1, 0, 1):
				if dy == 0 and dx == 0: continue
				sm = np.roll(mask, (dy, dx), axis=(0, 1)); acc += np.roll(rgb, (dy, dx), axis=(0, 1)) * sm[..., None]; cnt += sm
		fill = (~mask) & (cnt > 0); rgb[fill] = acc[fill] / cnt[fill][:, None]; mask = mask | fill
	return rgb, mask

def to_linear(c):
	return np.where(c > .04045, ((c + .055) / 1.055) ** 2.4, c / 12.92)

def box_blur(rgb, radius):
	"""Separable box blur; a vertex then samples a patch of the drawing instead of one painterly pixel."""
	k = 2 * radius + 1; out = rgb
	for axis in (0, 1):
		pad = [(0, 0)] * rgb.ndim; pad[axis] = (radius, radius)
		c = np.cumsum(np.pad(out, pad, mode='edge'), axis=axis)
		lead = [slice(None)] * rgb.ndim; lead[axis] = slice(k, None)
		lag = [slice(None)] * rgb.ndim; lag[axis] = slice(None, -k)
		out = (c[tuple(lead)] - c[tuple(lag)]) / k
		first = [slice(None)] * rgb.ndim; first[axis] = slice(k - 1, k)
		out = np.concatenate([c[tuple(first)] / k, out], axis=axis)
	return out

def erode(mask, iters):
	m = mask.copy()
	for _ in range(iters):
		n = m.copy()
		for dy in (-1, 0, 1):
			for dx in (-1, 0, 1):
				n &= np.roll(m, (dy, dx), axis=(0, 1))
		m = n
	return m

def centre_column(fg, box, v_lo=.45, v_hi=.58):
	"""Median foreground column across the hip rows: the figure's centre line."""
	x0, x1, y0, y1 = box; cs = []
	for r in range(int(y0 + v_lo * (y1 - y0)), int(y0 + v_hi * (y1 - y0))):
		xs = np.nonzero(fg[r, x0:x1 + 1])[0]
		if len(xs): cs.append(x0 + float(np.median(xs)))
	return float(np.median(cs))

projected = None; sheet_report = {'sheet': None}
if SHEET.exists():
	rgb, fg = load_sheet(SHEET); boxes = figure_boxes(fg)
	if len(boxes) >= 3:
		# Seed the spread from interior pixels so anti-aliased outlines do not tint the ring around each figure.
		rgb_grown, fg_grown = grow(rgb, erode(fg, 2), 26)
		rgb_grown = box_blur(rgb_grown, 3)
		front_box, side_box, back_box = boxes[0], boxes[1], boxes[2]
		N = np.empty(len(me.vertices) * 3, dtype=np.float32); me.vertex_normals.foreach_get('vector', N); N = N.reshape(-1, 3)
		def fit_view(box, along, sign):
			"""Scale and offset that best overlap the projected mesh with the drawn figure (IoU on a quarter-resolution raster)."""
			x0, x1, y0, y1 = box; sub = fg[y0:y1 + 1, x0:x1 + 1]; R = 4
			H4, W4 = (sub.shape[0] + R - 1) // R, (sub.shape[1] + R - 1) // R
			mask4 = np.zeros((H4, W4), bool); ys, xs = np.nonzero(sub); mask4[ys // R, xs // R] = True
			ppm0 = (y1 - y0) / HEIGHT; cx0 = centre_column(fg, box) - x0; a = sign * along
			def score(sx, sy, tx, ty):
				px = np.rint((cx0 + tx + a * ppm0 * sx) / R).astype(int); py = np.rint((y1 - y0 + ty - Zc * ppm0 * sy) / R).astype(int)
				ok = (px >= 0) & (px < W4) & (py >= 0) & (py < H4)
				model4 = np.zeros((H4, W4), bool); model4[py[ok], px[ok]] = True
				return np.count_nonzero(model4 & mask4) / max(1, np.count_nonzero(model4 | mask4))
			best = (-1, 1, 1, 0, 0)
			for sy in np.arange(.85, 1.16, .03):
				for sx in (sy * .94, sy, sy * 1.06):
					for ty in range(-64, 65, 8):
						for tx in range(-40, 41, 8):
							sc = score(sx, sy, tx, ty)
							if sc > best[0]: best = (sc, sx, sy, tx, ty)
			_, sx0, sy0, tx0, ty0 = best
			for sy in np.arange(sy0 - .03, sy0 + .031, .01):
				for sx in np.arange(sx0 - .04, sx0 + .041, .01):
					for ty in range(ty0 - 8, ty0 + 9, 2):
						for tx in range(tx0 - 8, tx0 + 9, 2):
							sc = score(sx, sy, tx, ty)
							if sc > best[0]: best = (sc, sx, sy, tx, ty)
			sc, sx, sy, tx, ty = best
			return {'iou': round(float(sc), 3), 'cx': float(x0 + cx0 + tx), 'base_y': float(y1 + ty), 'ppm_x': float(ppm0 * sx), 'ppm_y': float(ppm0 * sy)}
		fits = {'front': fit_view(front_box, X, 1), 'back': fit_view(back_box, X, -1), 'side': fit_view(side_box, Y, -1)}
		def sash_row(box, fit):
			"""Centre row of the drawn waist wrap: the topmost dark run through the figure's middle columns below the shirt."""
			x0, x1, y0, y1 = box; half = int(.2 * (x1 - x0)); cx = int(round(fit['cx'])); hits = []
			for r in range(int(y0 + .3 * (y1 - y0)), int(y0 + .65 * (y1 - y0))):
				if rgb[r, max(x0, cx - half):min(x1, cx + half)].mean() < .42: hits.append(r)
			if not hits: return None
			run = [hits[0]]
			for r in hits[1:]:
				if r - run[-1] > 3: break
				run.append(r)
			return float(np.mean(run)) if len(run) >= 20 else None
		body_only = ~(arm_mask | head_mask)
		def sample(key, along, sign):
			fit = fits[key]
			px = np.clip(np.rint(fit['cx'] + sign * along * fit['ppm_x']).astype(int), 0, rgb.shape[1] - 1)
			rows = fit['base_y'] - Zc * fit['ppm_y']
			if fit.get('sash_row'):
				# Torso and legs bend the height map through the drawn sash; arms and head keep the uniform fit they already match.
				crown = fit['base_y'] - HEIGHT * fit['ppm_y']; sash = fit['sash_row']
				bent = np.where(Zc < SASH_Z, fit['base_y'] - Zc * (fit['base_y'] - sash) / SASH_Z, sash - (Zc - SASH_Z) * (sash - crown) / (HEIGHT - SASH_Z))
				rows = np.where(body_only, bent, rows)
			py = np.clip(np.rint(rows).astype(int), 0, rgb.shape[0] - 1)
			return rgb_grown[py, px], fg_grown[py, px].astype(np.float32)
		front_sash = sash_row(front_box, fits['front'])
		for key in fits:  # the side and back share the drawing's proportions, so the front's sash height carries over by scale
			fits[key]['sash_row'] = None if front_sash is None else float(fits[key]['base_y'] - (fits['front']['base_y'] - front_sash) * fits[key]['ppm_y'] / fits['front']['ppm_y'])
		c_front, m_front = sample('front', X, 1)    # facing the viewer: +X on the viewer's right
		c_back, m_back = sample('back', X, -1)      # seen from behind: +X on the viewer's left
		c_side, m_side = sample('side', Y, -1)      # profile facing the viewer's right: the front (-Y) is on the right
		w_front = np.clip(-N[:, 1], 0, 1) ** 6 * m_front
		w_back = np.clip(N[:, 1], 0, 1) ** 6 * m_back
		w_side = np.abs(N[:, 0]) ** 6 * m_side
		total = w_front + w_back + w_side
		flat = total < 1e-4  # top or bottom facing: no view is better, average what covers it
		w_front[flat], w_back[flat], w_side[flat] = m_front[flat], m_back[flat], m_side[flat]
		total = w_front + w_back + w_side
		mixed = (c_front * w_front[:, None] + c_back * w_back[:, None] + c_side * w_side[:, None]) / np.maximum(total, 1e-6)[:, None]
		projected = np.where((total > 1e-3)[:, None], to_linear(mixed), np.nan)
		sheet_report = {'sheet': SHEET.name, 'boxes_front_side_back': [list(map(int, b)) for b in boxes[:3]], 'fits': fits, 'covered': float(np.mean(total > 1e-3))}
	else:
		sheet_report = {'sheet': SHEET.name, 'error': 'expected three figures, found %d' % len(boxes)}
print('SHEET', json.dumps(sheet_report), flush=True)
if projected is not None:
	use = ~np.isnan(projected[:, 0]); colour[use] = projected[use]

loops = np.empty(len(me.loops), dtype=np.int32); me.loops.foreach_get('vertex_index', loops)
attr = me.color_attributes.new(name='GameColor', type='FLOAT_COLOR', domain='CORNER')
rgba = np.concatenate([colour[loops], np.ones((len(loops), 1))], axis=1).astype(np.float32)
attr.data.foreach_set('color', rgba.ravel()); me.color_attributes.active_color = attr

def runtime_material(name, rough, metal=0):
	m = bpy.data.materials.new('Game ' + name); m.use_nodes = True
	p = m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value = (1, 1, 1, 1)
	p.inputs['Roughness'].default_value = rough; p.inputs['Metallic'].default_value = metal
	a = m.node_tree.nodes.new('ShaderNodeVertexColor'); a.layer_name = 'GameColor'
	m.node_tree.links.new(a.outputs['Color'], p.inputs['Base Color']); m.use_backface_culling = False
	return m

me.materials.clear()
for m in (runtime_material('Fabric', .90), runtime_material('Skin', .57), runtime_material('Hair', .66), runtime_material('Brass', .4, .55), runtime_material('Eyes', .19)):
	me.materials.append(m)
poly_verts = [list(p.vertices) for p in me.polygons]
me.polygons.foreach_set('material_index', [int(np.bincount(category[v], minlength=3).argmax()) for v in poly_verts])
me.update()

# ---------------------------------------------------------------- rig and export
obj.name = 'Traveler'; me.name = 'Traveler'
arm_data = bpy.data.armatures.new('TravelerRig'); arm = bpy.data.objects.new('TravelerRig', arm_data)
bpy.context.scene.collection.objects.link(arm); bpy.context.view_layer.objects.active = arm; arm.select_set(True); obj.select_set(False)
bpy.ops.object.mode_set(mode='EDIT')
for name, p in points.items():
	b = arm_data.edit_bones.new(name); b.head = Vector(p); b.tail = Vector(p) + Vector((0, 0, .10))
bpy.ops.object.mode_set(mode='OBJECT')
mod = obj.modifiers.new('Traveler skin', 'ARMATURE'); mod.object = arm; obj.parent = arm
bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); arm.select_set(True); bpy.context.view_layer.objects.active = arm
path = ASSET / (SLUG + '.glb')
bpy.ops.export_scene.gltf(filepath=str(path), export_format='GLB', use_selection=True, export_animations=False, export_skins=True,
	export_all_influences=False, export_def_bones=True, export_materials='EXPORT', export_attributes=False, export_yup=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / (SLUG + '.blend')))
triangles = sum(len(p.vertices) - 2 for p in me.polygons)
report = {'source': SOURCE.name, 'figure': FIGURE, 'figures_in_source': len(seeds), 'source_triangles': source_triangles, 'triangles': triangles,
	'vertices': len(me.vertices), 'bytes': path.stat().st_size, 'height_m': HEIGHT, 'bones': list(points),
	'joints_blender_zup': {k: [round(v, 4) for v in p] for k, p in points.items()},
	'joints_godot_yup': {k: [round(p[0], 4), round(p[2], 4), round(-p[1], 4)] for k, p in points.items()},
	'landmark_samples': {'hands': hands['samples'], 'forearm': elbows['samples'], 'knees': knees['samples'], 'thighs': thighs['samples']},
	'sheet': sheet_report, 'max_influences': max(influences), 'regions': {'arm': int(arm_mask.sum()), 'head': int(head_mask.sum()), 'gear': int(gear_mask.sum())},
	'limitations': ['Generated topology, no manual retopology', 'Colours projected from the 2D turnaround sheet (baked illustration shading, projection smear where surfaces are hidden in all three views)',
		'Single mesh: gripped-tool poses show the game\'s procedural closed fingers over the open hand', 'Cape bone carries no vertices']}
(OUT / (SLUG + '_report.json')).write_text(json.dumps(report, indent=2) + '\n')
print('RODIN_TRAVELER_EXPORTED', json.dumps(report), flush=True)

# ---------------------------------------------------------------- actual Cycles renders of the exported geometry
scene = bpy.context.scene; scene.render.engine = 'CYCLES'; scene.cycles.device = 'CPU'; scene.cycles.samples = 24; scene.cycles.use_denoising = True
scene.render.resolution_x = 800; scene.render.resolution_y = 1000; scene.render.resolution_percentage = 100; scene.world.color = (.16, .16, .16)
centre = Vector((0, 0, 1.03))
for offset, energy, size in [((-3, -4, 5), 500, 4), ((4, -1, 3), 280, 4), ((0, 4, 4), 550, 3)]:
	bpy.ops.object.light_add(type='AREA', location=offset); light = bpy.context.object; light.data.energy = energy; light.data.size = size
	light.rotation_euler = (centre - light.location).to_track_quat('-Z', 'Y').to_euler()
bpy.ops.object.camera_add(); cam = bpy.context.object; scene.camera = cam; cam.data.type = 'ORTHO'
bpy.ops.mesh.primitive_plane_add(size=200); floor = bpy.context.object; fmat = bpy.data.materials.new('Review floor'); fmat.diffuse_color = (.1, .12, .13, 1); floor.data.materials.append(fmat)
def render(name, offset, span, target=None):
	aim = Vector(target) if target else centre
	cam.location = aim + Vector(offset); cam.rotation_euler = (aim - cam.location).to_track_quat('-Z', 'Y').to_euler()
	cam.data.ortho_scale = span; scene.render.filepath = str(REVIEW / (name + '.png')); bpy.ops.render.render(write_still=True)
render('front', (0, -4, .2), 2.3)
render('back', (0, 4, .2), 2.3)
render('three-quarter', (2.8, -2.8, .3), 2.3)
render('face', (0, -2, .02), .6, (0, 0, 1.86))
print('RODIN_TRAVELER_COMPLETE', flush=True)
