# Created by Aaron Oppong
# https://github.com/aaron-oppong

import json

if __name__ == "__main__":
    path = 'user_prefs.json'

    with open(path, 'r') as file:
        prefs = json.load(file)

    pref_list = [('label_height', 'Label Height'), ('label_offset', 'Label Offset'), ('stroke_width', 'Stroke Width')]

    print('Current . . .')

    for key, question in pref_list:
        print(f'{question}: {prefs.get(key, 0):.4f}')

    print('\nPress Enter to skip.\n\nNew . . .')

    for key, question in pref_list:
        user_input = input(f'{question}: ')

        try:
            value = abs(eval(user_input))
        except:
            value = prefs.get(key, 0)

        prefs[key] = value

    with open(path, 'w') as file:
        json.dump(prefs, file, indent=2)