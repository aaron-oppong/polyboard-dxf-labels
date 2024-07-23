# Created by Aaron Oppong
# https://github.com/aaron-oppong

import csv, ezdxf, re, json, string, sys
from ezdxf.math import area, closest_point, Vec2
from shapely.geometry import Polygon

def get_dictionary(folder, log):
    log = open(log, 'r')
    paths = log.readlines()
    log.close()

    alphabets = list(string.ascii_uppercase)

    cabinet_dict = {}
    dictionary = {}
    
    for path in paths:
        path = re.sub(r'^(.*)\n$', r'\1', path)

        file = open(f'{path}.txt', 'r')
        report = file.read()
        file.close()

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
    try:
        return list(poly.vertices_in_wcs())
    except AttributeError:
        return list(poly.points())

def label_attribs(outline):
    points = [p.vec2 for p in poly_to_points(outline)]

    Poly = Polygon(points)

    mx, my = Poly.bounds[2:]

    v1, v2 = [Vec2(p) for p in Poly.oriented_envelope.exterior.coords[-3:-1]]
    a = round((v1 - v2).angle_deg, 4) - 45

    points += [(points[i] + points[i - 1]) / 2 for i in range(len(points))]

    p0 = closest_point(Vec2(0,0), points).vec2

    return p0, mx, my, a

def add_label(msp, info, outline, label_height, label_offset):
    text = info['cabinet'] + info['number']
    
    p, dx, dy, a = label_attribs(outline)

    if label_offset + label_height <= min(dx, dy):
        p += label_offset * Vec2(1,1)

        if dx <= dy:
            p += label_height * Vec2(1,0)
            a += 45
        else:
            a -= 45

        msp.add_text(text, height=label_height, rotation=a, dxfattribs={'layer': 'Label', 'insert': p})

if __name__ == '__main__':
    arg = sys.argv

    cd = arg[1]
    dxf_list = arg[2]
    report_log = arg[3]

    label_height = float(arg[4])
    label_offset = float(arg[5])
    
    if label_height != 0:
        file = open(dxf_list, 'r')

        dictionary = get_dictionary(cd, report_log)
        current_folder = None

        for path, folder, filename in csv.reader(file):
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

            try:
                info = dictionary[filename]
            except KeyError:
                doc.save()
                continue

            add_label(msp, info, outline, label_height, label_offset)

            if folder != current_folder:
                print(f'\n{re.findall(r'[^\\]+(?=\\$)', folder)[0]}')
                current_folder = folder

            print(f'> {filename}')

            doc.layers.remove('Defpoints')

            doc.save()
        
        file.close()
