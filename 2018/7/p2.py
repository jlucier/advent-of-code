import numpy as np

with open('input.txt', 'r') as f:
    steps = list(map(lambda l: l.strip(), f.readlines()))

cost = lambda task: ord(task) - 4
dependencies = dict()
all_tasks = set()
for s in steps:
    s = s.split()
    dependencies.setdefault(s[-3], list()).append(s[1])
    all_tasks.update([s[1], s[-3]])

no_deps = all_tasks.difference(dependencies.keys())
complete_tasks = set()
time_elapsed = 0
workers = [None] * 5

while len(dependencies) > 0:
    for i in range(len(workers)):
        if workers[i] is not None and workers[i][1] <= time_elapsed:
            complete_tasks.add(workers[i][0])
            workers[i] = None

    next_tasks = list()
    for task, deps in dependencies.items():
        if all(d in complete_tasks for d in deps):
            next_tasks.append(task)

    if len(no_deps) > 0:
        next_tasks.extend(no_deps)

    next_tasks = sorted(next_tasks, reverse=True)

    if len(next_tasks) > 0:
        for i in range(len(workers)):
            if workers[i] is None:
                # schedule task on worker i and calculate when it'll finish
                task = next_tasks.pop()
                workers[i] = (task, time_elapsed + cost(task))

                if task in dependencies:
                    del dependencies[task]

                if task in no_deps:
                    no_deps.remove(task)

                if len(next_tasks) == 0:
                    break

    time_elapsed = min(map(lambda w: w[1] if w is not None else float('inf'), workers))

print(max(map(lambda w: w[1] if w is not None else 0, workers)))
