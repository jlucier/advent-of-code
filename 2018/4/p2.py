from collections import Counter
from datetime import datetime

def parse_dt(log_entry):
    return datetime.strptime(log_entry[1:log_entry.index(']')], '%Y-%m-%d %H:%M')

with open('input.txt', 'r') as f:
    log = list(sorted(f.readlines(), key=parse_dt))

g_sleeping = dict()
curr_guard = None
curr_fall_asleep = None
for entry in log:
    dt = parse_dt(entry)

    if 'Guard' in entry:
        # guard start
        curr_guard = entry[entry.index('#')+1: entry.index('begins') -1]
        curr_fall_asleep = None

    elif 'falls' in entry:
        # fall asleep
        curr_fall_asleep = dt.minute

    elif 'wakes' in entry:
        # wake up
        sleep = g_sleeping.setdefault(curr_guard, Counter())
        sleep.update(range(curr_fall_asleep, dt.minute))

    else:
        raise Exception('....')

g, sleep = list(sorted(g_sleeping.items(), key=lambda t: max(t[1].values())))[-1]
max_min = sleep.most_common(1)[0][0]
print(int(g) * max_min)
