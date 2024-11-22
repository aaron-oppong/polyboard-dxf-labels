# Created by Aaron Oppong
# https://github.com/aaron-oppong

import csv, ezdxf, re, json, string, sys

from ezdxf.math import area, closest_point, Vec2, Vec3, NULLVEC, Z_AXIS

from shapely.affinity import rotate
from shapely.geometry import Point, LineString, Polygon
from shapely.ops import unary_union

def get_dictionary(folder, log):
    with open(log, 'r') as log:
        paths = log.readlines()

    alphabets = list(string.ascii_uppercase)

    cabinet_dict = {}
    dictionary = {}

    for path in paths:
        path = re.sub(r'^(.*)\n$', r'\1', path)

        with open(f'{path}.txt', 'r') as file:
            report = file.read()

        report = re.sub(r'\\', r'\\\\', report)
        report = re.sub(r'(?<!:)(")(?=")', r'\\\1', report)
        report = re.sub(r'\n(?!$)', ', ', report)
        report = re.sub(r'^(.*)\n$', r'{\1}', report)
        report = json.loads(report)

        for key in report:
            info = report[key]

            cabinet = info['cabinet']
            project = info['project']

            if project == '':
                info['cabinet'] = ''
            else:
                if cabinet not in cabinet_dict:
                    len_cabinets = len(cabinet_dict)

                    if len_cabinets < 26:
                        cabinet_dict[cabinet] = alphabets[len_cabinets]
                    else:
                        cabinet_dict[cabinet] = alphabets[(len_cabinets // 26) - 1] + alphabets[len_cabinets % 26]

                cabinet = cabinet_dict[cabinet]

                info['cabinet'] = cabinet

            dictionary[key] = info

    if len(cabinet_dict) != 0:
        cabinet_list = open(f'{folder}\\{project}.txt', 'w')

        for cabinet in cabinet_dict:
            cabinet_list.write(f'{cabinet_dict[cabinet]} -> {cabinet}\n')

        cabinet_list.close()

    return dictionary

def poly_to_points(poly):
    ocs = poly.ocs()

    if poly.dxftype() == 'POLYLINE':
        points = poly.points()
        if poly.is_3d_polyline:
            points = ocs.points_from_wcs(points)
    else:
        points = ocs.points_from_wcs(poly.vertices_in_wcs())

    return list(points)

def add_label(msp, info, outline_area, label_area, stroke_radius, label_offset, label_height, half_label_height):
    text = info['cabinet'] + info['number']

    p1, p2 = [Vec3(p) for p in outline_area.oriented_envelope.exterior.coords[-3:-1]]

    u1 = (p1 - p2).normalize()
    u2 = u1.orthogonal(False)
    u3 = u1 + u2

    a = round(u1.angle_deg, 4)

    v1, v2, v3 = [(label_offset + half_label_height) * u for u in [u1, u2, u3]]
    v4 = v3.orthogonal(False)

    polys = label_area.geoms if label_area.geom_type == 'MultiPolygon' else [label_area]
    points = []

    for poly in polys:
        b_box = poly.oriented_envelope

        if a % 90 != 0:
            b_box = rotate(b_box, a)

        d = b_box.bounds
        d = Vec2(d[2:]) - Vec2(d[:2])

        if (label_offset + label_height) <= min(d.x, d.y):
            q = d.x <= d.y

            exterior_points = [Vec3(p) for p in poly.exterior.coords[:-1]]
            points += zip(exterior_points, [q] * len(exterior_points))
            points += [((exterior_points[i] + p) / 2, q) for i, p in enumerate(exterior_points, start=-1)]

            for interior in poly.interiors:
                interior_points = [Vec3(p) for p in interior.coords[:-1]]
                points += zip(interior_points, [q] * len(interior_points))
                points += [((interior_points[i] + p) / 2, q) for i, p in enumerate(interior_points, start=-1)]

    points += [(p[0], True) for p in filter(lambda p: not p[1], points)]
    new_points = []

    for p, q in points:
        for v in [v1, v2, v3, v4]:
            new_points += [(p + v, q), (p - v, q)]

    text_length = len(text)
    v1, v2 = [(text_length - 1) * label_height * u for u in [u1, u2]]

    points = list(filter(lambda p: label_area.contains((Point(p[0]) if v1 == NULLVEC else LineString([p[0], p[0] + (v1 if p[1] else v2)])).buffer(stroke_radius)), new_points))

    if len(points) != 0:
        p = closest_point(NULLVEC, list(zip(*points))[0])
        q = (p, True) in points

        v1, v2, v3 = [half_label_height * u for u in [u1, u2, u3]]
        v4 = v3.orthogonal(False)

        if not q:
            a -= 90

        p += v4 if q else v3.reversed()

        msp.add_text(text, height=label_height, rotation=a, dxfattribs={'layer': 'Label', 'insert': p})

if __name__ == "__main__":
    arg = sys.argv[1:]

    if len(arg) == 0:
        sys.exit()

    cd, dxf_list, report_log = arg[1:]

    with open(arg[0]) as file:
        user_prefs = json.load(file)

    label_height, label_offset, stroke_width = [user_prefs.get(key, 0) for key in ['label_height', 'label_offset', 'stroke_width']]

    if label_height != 0:
        half_label_height, quarter_label_height = [label_height / k for k in [2, 4]]
        stroke_radius = half_label_height + (stroke_width / 2)

        file = open(dxf_list, 'r')

        dictionary = get_dictionary(cd, report_log)
        current_folder = None

        for path, folder, filename in csv.reader(file):
            try:
                info = dictionary[filename]
            except KeyError:
                continue

            doc = ezdxf.readfile(path)
            msp = doc.modelspace()

            try:
                outline = msp.query(f'LWPOLYLINE POLYLINE[layer=="{outline_layer}"]')[0]
            except NameError:
                polys = msp.query(f'LWPOLYLINE POLYLINE[thickness!=0]')

                volume_list = []

                for poly in polys:
                    volume_list.append(area(poly_to_points(poly)) * abs(poly.dxf.thickness))

                outline = polys[volume_list.index(max(volume_list))]
                outline_layer = outline.dxf.layer
            except IndexError:
                continue

            elevation = outline.dxf.elevation
            extrusion = outline.dxf.extrusion
            thickness = abs(outline.dxf.thickness)

            outline_area = Polygon(poly_to_points(outline))

            label_area = outline_area.difference(
                unary_union(
                    [LineString([l.dxf.start, l.dxf.end]).buffer(1e-4, cap_style='square') for l in msp.query('LINE').filter(
                        lambda e: (e.dxf.extrusion.z * Z_AXIS).normalize() == extrusion
                    )] +
                    [Polygon(c.vertices(range(0, 360, 5))) for c in msp.query(f'CIRCLE[radius>{quarter_label_height} & thickness!=0]').filter(
                        lambda e: (e.dxf.extrusion == extrusion) or ((abs(e.dxf.thickness) == thickness) and (e.dxf.extrusion.z + extrusion.z == 0))
                    )] +
                    [Polygon(poly_to_points(t)) for t in msp.query('LWPOLYLINE POLYLINE[thickness==0]').union(msp.query(f'LWPOLYLINE POLYLINE[layer!="{outline_layer}" & thickness!=0]').filter(
                        lambda e: (e.dxf.elevation, e.dxf.extrusion) == (elevation, extrusion)
                    ))]
                )
            )

            add_label(msp, info, outline_area, label_area, stroke_radius, label_offset, label_height, half_label_height)

            if folder != current_folder:
                print(f'\n{re.findall(r'[^\\]+(?=\\$)', folder)[0]}')
                current_folder = folder

            print(f'> {filename}')

            doc.layers.remove('Defpoints')

            doc.save()

        file.close()