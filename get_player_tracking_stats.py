import pandas as pd
import math

clean_vert_df = pd.read_csv('data/cleaned_vertical_route_data.csv')

def get_play_data(row, week_data, play_index):
    if play_index % 20 == 0: # print every 20 plays
        print(f'Index: {play_index}')

    temp_df = pd.DataFrame()
    play_data = row.to_dict()
    if play_data['possessionTeam'] == play_data['homeTeamAbbr']:
        offense_side = 'home'
        defense_side = 'away'
    else:
        offense_side = 'away'
        defense_side = 'home'

    play_tracking_data = week_data.loc[(week_data['gameId'] == play_data['gameId']) & (week_data['playId'] == play_data['playId'])]

    los = play_data['absoluteYardlineNumber']

    x_direction = -1 if play_tracking_data.iloc[0]['playDirection'] == 'left' else 1
    receiver_tracking_data = play_tracking_data.loc[(play_tracking_data['team'] == offense_side) &
                                                    (play_tracking_data['jerseyNumber'] == play_data['receiver_num'])]

    defender_tracking_data = play_tracking_data.loc[(play_tracking_data['team'] == defense_side) &
                                                    (play_tracking_data['jerseyNumber'] == play_data['defender_num'])]

    try:
        play_data['receiver_name'] = receiver_tracking_data.iloc[0]['displayName']
        play_data['defender_name'] = defender_tracking_data.iloc[0]['displayName']
    except:
        print(f'could not find one or both player(s) at index {play_index}')
        temp_df = temp_df.append(play_data, ignore_index=True)
        return temp_df

    snapped = False
    if math.isnan(los):
        print(f'nan abs yardline at index {play_index}')
    elif play_data['route_name'] == 'Go':
        for index, track_row in receiver_tracking_data.iterrows():
            if snapped:
                if track_row['event'] in ["pass_forward", "pass_arrived", "pass_outcome_caught", "pass_outcome_incomplete", "first_contact", "tackle", "qb_sack",  "pass_tipped", "pass_outcome_interception", "qb_strip_sack", "pass_shovel", "touchdown", "pass_outcome_touchdown"] \
                        or ((track_row['x'] - los) * x_direction) > 17:
                    #print(f"Go route {((track_row['x'] - los) * x_direction): .2f} yards downfield")
                    play_data['route_depth'] = ((track_row['x'] - los) * x_direction)

                    # get downfield distance
                    frame = track_row['frameId']
                    receiver_x = track_row['x']
                    try:
                        defender_x = defender_tracking_data.loc[defender_tracking_data['frameId'] == frame].iloc[0]['x']
                    except:
                        print(f'defender missing frame {frame} at index {play_index}')
                        break
                    # positive means defender is on top of receiver
                    play_data['downfield_distance'] = (defender_x - receiver_x) * x_direction
                    break
                elif track_row['event'] in ["touchback", "penalty_accepted", "run","qb_spike", "field_goal_blocked", "out_of_bounds", "fumble",  "fumble_offense_recovered",  "handoff", "fumble_defense_recovered"]:
                    # broken play
                    break
            elif track_row['event'] == "ball_snap":
                snapped = True
    else:
        prev_speed = 0
        for index, track_row in receiver_tracking_data.iterrows():
            if snapped and ((track_row['x'] - los) * x_direction) > 3: # at least 3 yards downfield
                if track_row['s'] < prev_speed:
                    #print(f"Breaking route {((track_row['x'] - los) * x_direction): .2f} yards downfield")
                    play_data['route_depth'] = ((track_row['x'] - los) * x_direction)

                    # get downfield distance
                    frame = track_row['frameId']
                    try:
                        defender_s = defender_tracking_data.loc[defender_tracking_data['frameId'] == frame].iloc[0]['s']
                    except:
                        print(f'defender missing frame {frame} at index {play_index}')
                        break
                    rem_def_frames = defender_tracking_data.loc[defender_tracking_data['frameId'] > frame]

                    for def_index, def_track_row in rem_def_frames.iterrows():
                        if def_track_row['s'] < defender_s:
                            # each frame is 0.1 seconds
                            def_frame = def_track_row['frameId']
                            play_data['hip_reaction_time'] = (def_frame - frame) * 0.1
                            break
                        else:
                            defender_s = def_track_row['s']
                    break

                elif track_row['event'] in ["touchback", "penalty_accepted", "run","qb_spike", "field_goal_blocked", "out_of_bounds", "fumble",  "fumble_offense_recovered",  "handoff", "fumble_defense_recovered"]:
                    # broken play
                    break
                else:
                    prev_speed = track_row['s']
            elif track_row['event'] == "ball_snap":
                snapped = True

    if play_data['targeted'] == 1:
        if any(x in list(receiver_tracking_data['event']) for x in ['pass_arrived', 'pass_outcome_incomplete', 'pass_outcome_caught', 'pass_outcome_touchdown', 'pass_outcome_interception']):
            pass_caught_frame = receiver_tracking_data.loc[(receiver_tracking_data['event'] == 'pass_arrived') |
                                                           (receiver_tracking_data['event'] == 'pass_outcome_incomplete') |
                                                           (receiver_tracking_data['event'] == 'pass_outcome_caught') |
                                                           (receiver_tracking_data['event'] == 'pass_outcome_touchdown') |
                                                           (receiver_tracking_data['event'] == 'pass_outcome_interception')].iloc[0]
            frame = pass_caught_frame['frameId']
            receiver_x = pass_caught_frame['x']
            receiver_y = pass_caught_frame['y']
            try:
                defender_x = defender_tracking_data.loc[defender_tracking_data['frameId'] == frame].iloc[0]['x']
                defender_y = defender_tracking_data.loc[defender_tracking_data['frameId'] == frame].iloc[0]['y']
                play_data['separation'] = math.sqrt(((receiver_x - defender_x) ** 2) + ((receiver_y - defender_y) ** 2))
            except:
                print(f'defender missing frame {frame} at index {play_index}')
    temp_df = temp_df.append(play_data, ignore_index=True)
    return temp_df

def get_week_data(week):
    week_data = pd.read_csv(f'data/week{week}.csv')
    week_play_data = clean_vert_df.loc[clean_vert_df['week'] == week]
    print(f'{len(week_play_data)} plays')
    week_df = pd.concat([get_play_data(row, week_data, index) for index, row in week_play_data.iterrows()], sort=False)
    return week_df

def main():
    fin_df = pd.DataFrame()
    for week in range(1, 18):
        print(f'Week {week}:')
        week_df = get_week_data(week)
        fin_df = fin_df.append(week_df, sort=False)
        fin_df.to_csv('data/final_data.csv')
    print('we did it fam')

if __name__ == '__main__':
    main()
