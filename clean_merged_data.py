import pandas as pd


route_dict = {
    '-': 'Block',
    '0': 'Now',
    '1': 'Speed Out',
    '2': 'Slant',
    '3': 'Deep Out',
    '4': 'Dig/Indy',
    '5': 'Comeback',
    '6': 'Hitch/Curl',
    '7': 'Corner',
    '8': 'Post',
    '9': 'Go',
    'X': 'Mesh',
    'H0': 'HB Screen',
    'H1': 'HB Screen',
    'H2': 'HB Flare',
    'H3': 'HB Flare',
    'H4': 'HB Out',
    'H5': 'HB Out',
    'H6': 'HB Pivot',
    'H7': 'HB Pivot',
    'H8': 'HB Wheel',
    'H9': 'HB Wheel'
}



def make_press_player_rows(row):
    row = row.to_dict()
    temp_df = pd.DataFrame()
    press_players = row['press_players'].split(';')
    for press_player in press_players:
        try:
            defender, receiver = [x.strip() for x in press_player.split('>')]
        except:
            continue
        if row['pass_receiver_target'] == receiver:
            targeted = 1
        else:
            targeted = 0

        if row['pass_breakup'] == defender:
            pbu = 1
        else:
            pbu = 0

        try:
            receiver_ind = [x for x in range(len(row['pass_pattern_by_player'].split(';')))
                            if receiver in row['pass_pattern_by_player'].split(';')[x]][0]
        except:
            print(f"Missing {receiver} in {row['pass_pattern_by_player']}")
            '''
            4 missing routes:
            Missing ARZ 11 in ARZ 03 n; ARZ 10 k; ARZ 82 k; ARZ 31 h8(-2); ARZ 84 xo(14)
            Missing PHI 13 in PHI 09 h8(-5); PHI 14 k; PHI 86 k; PHI 30 h9(-4); PHI 88 9s
            Missing TEN 15 in TEN 08 h9(-5); TEN 33 frxj(-5); TEN 17 xo(11); TEN 88 k; TEN 81 k
            Missing NE 11 in NE 12 h2(-6); NE 15 k; NE 47 k; NE 28 fl; NE 13 xo(20)
            '''
            continue

        route = row['pass_pattern_basic'].split(';')[receiver_ind].strip()
        route_name = route_dict[route]
        press_dict = row.copy()
        press_dict.update({
            'defender': defender,
            'defender_num': int(defender.replace(row['defense'], '')),
            'receiver': receiver,
            'receiver_num': int(receiver.replace(row['offense'], '')),
            'targeted': targeted,
            'pbu': pbu,
            'route': route,
            'route_name': route_name
        })

        temp_df = temp_df.append(press_dict, ignore_index=True)
    return temp_df


def main():
    df = pd.read_csv('data/merged_data.csv')
    clean_df = pd.concat([make_press_player_rows(row) for index, row in df.iterrows()], sort=False)
    clean_df = clean_df.sort_values(by = 'week')
    '''
    Route counts:
    Go            2824
    Deep Out      1650
    Hitch/Curl    1466
    Mesh          1312
    Dig/Indy      1104
    Slant         1051
    Post           827
    Corner         453
    Block          387
    Comeback       212
    Now            163
    HB Screen        1
    '''
    clean_df.to_csv('data/cleaned_data.csv')

if __name__ == '__main__':
    main()
