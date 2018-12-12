num_players = 470
last_marble_val = 72170

circle = [0]
players = [0] * num_players
next_marble_val = 1
curr_marble_idx = 0

curr_player = 0
while next_marble_val <= last_marble_val:
    if next_marble_val % 23 == 0:
        remove_idx = (curr_marble_idx - 7 + len(circle)) % len(circle)
        players[curr_player] += next_marble_val + circle.pop(remove_idx)
        curr_marble_idx = remove_idx
    else:
        # add marble normally
        insert_idx = (curr_marble_idx + 2) % len(circle)
        if insert_idx == 0:
            circle.append(next_marble_val)
            curr_marble_idx = len(circle) - 1
        else:
            circle.insert(insert_idx, next_marble_val)
            curr_marble_idx = insert_idx

    curr_player = (curr_player + 1) % len(players)
    next_marble_val += 1

print(max(players))
